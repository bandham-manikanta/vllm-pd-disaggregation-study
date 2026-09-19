#!/usr/bin/env python3
"""
collocated_round_robin_proxy.py - Production-Grade Inference Reverse Proxy for Collocated vLLM

Features & Standards Alignment (vLLM, Ray Serve, LiteLLM, RFC 9110):
- Least Outstanding Requests (LOR) dynamic scheduling with round-robin tiebreaking
- Asynchronous background health monitoring with automatic failure detection & recovery
- Probes both `/health` and `/healthcheck` for vLLM V0/V1 engine compatibility
- Transparent failover & retry on connection drops and upstream 502/503/504 errors
- Non-blocking bidirectional streaming with client disconnect cancellation propagation
- Strict RFC 7230 / RFC 9110 hop-by-hop header scrubbing
- CORS support for web clients and frontend chat interfaces
- Clean application factory pattern with isolated CLI parsing
"""

import argparse
import asyncio
import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

import httpx
import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("inference_proxy")

# RFC 7230 / RFC 9110 Hop-by-Hop Headers to scrub
HOP_BY_HOP_HEADERS = frozenset({
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
    "host",
})


def filter_forward_headers(headers: dict[str, str]) -> dict[str, str]:
    """Scrub hop-by-hop and length/encoding headers before forwarding."""
    return {
        k: v for k, v in headers.items()
        if k.lower() not in HOP_BY_HOP_HEADERS and k.lower() not in ("content-length", "content-encoding")
    }


class Backend:
    """Manages an upstream vLLM inference engine instance."""

    def __init__(self, target_url: str, timeout: httpx.Timeout, limits: httpx.Limits):
        self.url = target_url if target_url.startswith(("http://", "https://")) else f"http://{target_url}"
        self.client = httpx.AsyncClient(
            base_url=self.url,
            timeout=timeout,
            limits=limits,
        )
        self.active_requests: int = 0
        self.is_healthy: bool = True
        self.consecutive_failures: int = 0

    def increment_active_requests(self) -> None:
        self.active_requests += 1

    def decrement_active_requests(self) -> None:
        self.active_requests = max(0, self.active_requests - 1)

    async def probe(self) -> bool:
        """
        Asynchronously probes backend health.
        Supports standard vLLM /health and proxy /healthcheck endpoints.
        """
        for endpoint in ("/health", "/healthcheck"):
            try:
                resp = await self.client.get(endpoint, timeout=2.0)
                if resp.status_code == 200:
                    self.is_healthy = True
                    self.consecutive_failures = 0
                    return True
                elif resp.status_code == 404:
                    continue
                else:
                    break
            except (httpx.RequestError, asyncio.TimeoutError):
                break

        self.consecutive_failures += 1
        if self.consecutive_failures >= 2:
            self.is_healthy = False
        return False

    async def close(self) -> None:
        """Closes the underlying HTTPX connection pool."""
        await self.client.aclose()


class LoadBalancer:
    """Least Outstanding Requests (LOR) load balancer with background health monitoring."""

    def __init__(self, targets: list[str]):
        # High-concurrency connection pool with fast connect timeout and indefinite read timeout for LLM generation
        self.limits = httpx.Limits(max_keepalive_connections=256, max_connections=1024, keepalive_expiry=30.0)
        self.timeout = httpx.Timeout(connect=5.0, read=None, write=30.0, pool=10.0)
        self.backends = [Backend(t, self.timeout, self.limits) for t in targets]
        self._rr_tiebreaker: int = 0
        self._health_task: asyncio.Task | None = None

    async def start(self) -> None:
        """Perform immediate health check and spawn background polling loop."""
        await asyncio.gather(*(b.probe() for b in self.backends), return_exceptions=True)
        self._health_task = asyncio.create_task(self._health_loop())
        logger.info(
            "Load balancer started with %d backends. Health states: %s",
            len(self.backends),
            {b.url: "UP" if b.is_healthy else "DOWN" for b in self.backends},
        )

    async def stop(self) -> None:
        """Cancel background health monitoring and close all connection pools."""
        if self._health_task:
            self._health_task.cancel()
            try:
                await self._health_task
            except asyncio.CancelledError:
                pass
        await asyncio.gather(*(b.close() for b in self.backends))
        logger.info("Load balancer stopped and connection pools closed.")

    async def _health_loop(self) -> None:
        """Background coroutine probing engines every 2 seconds."""
        while True:
            try:
                await asyncio.sleep(2.0)
                await asyncio.gather(*(b.probe() for b in self.backends), return_exceptions=True)
            except asyncio.CancelledError:
                break
            except Exception as exc:  # noqa: BLE001
                logger.warning("Unexpected error in health polling loop: %s", exc)

    def select_backend(self, excluded_backends: set[Backend] | None = None) -> Backend | None:
        """
        Selects an engine using Least Outstanding Requests (LOR).
        Falls back to round-robin when active request counts are tied.
        """
        excluded = excluded_backends or set()
        candidates = [b for b in self.backends if b.is_healthy and b not in excluded]

        # If all healthy candidates are exhausted, try any unattempted backend
        if not candidates:
            candidates = [b for b in self.backends if b not in excluded]

        if not candidates:
            return None

        min_load = min(b.active_requests for b in candidates)
        tied_candidates = [b for b in candidates if b.active_requests == min_load]

        if len(tied_candidates) == 1:
            return tied_candidates[0]

        # Round-robin tiebreaker among least loaded backends
        self._rr_tiebreaker = (self._rr_tiebreaker + 1) % len(tied_candidates)
        return tied_candidates[self._rr_tiebreaker]

    def fleet_status(self) -> dict[str, Any]:
        """Returns in-memory snapshot of cluster health."""
        healthy_count = sum(1 for b in self.backends if b.is_healthy)
        total = len(self.backends)
        overall_status = "healthy" if healthy_count == total else (
            "degraded" if healthy_count > 0 else "unhealthy"
        )
        return {
            "status": overall_status,
            "healthy_backends": healthy_count,
            "total_backends": total,
            "backends": {
                b.url: {
                    "healthy": b.is_healthy,
                    "active_requests": b.active_requests,
                    "consecutive_failures": b.consecutive_failures,
                }
                for b in self.backends
            },
        }


def make_stream_generator(
    upstream_resp: httpx.Response,
    backend: Backend,
    request: Request,
) -> AsyncIterator[bytes]:
    """
    Creates an async generator streaming raw response chunks.
    Detects client disconnect to promptly cancel upstream vLLM inference.
    """
    async def stream_generator() -> AsyncIterator[bytes]:
        try:
            async for chunk in upstream_resp.aiter_raw():
                # Propagate client disconnect to prevent wasting GPU compute
                if await request.is_disconnected():
                    logger.debug("Client disconnected; aborting upstream stream to %s", backend.url)
                    break
                yield chunk
        except asyncio.CancelledError:
            logger.debug("Stream task cancelled; closing stream to %s", backend.url)
            raise
        finally:
            await upstream_resp.aclose()
            backend.decrement_active_requests()

    return stream_generator()


def create_app(targets: list[str]) -> FastAPI:
    """Factory creating configured FastAPI application with lifespan management."""
    lb = LoadBalancer(targets)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        await lb.start()
        app.state.lb = lb
        yield
        await lb.stop()

    app = FastAPI(
        title="vLLM Inference Reverse Proxy",
        description="Production Least Outstanding Requests Proxy for Collocated vLLM",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/health")
    @app.get("/healthcheck")
    async def health_endpoint():
        """O(1) in-memory fleet health reporting without synchronous probing."""
        status = lb.fleet_status()
        status_code = 200 if status["healthy_backends"] > 0 else 503
        return JSONResponse(content=status, status_code=status_code)

    @app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
    async def forward_request(request: Request, path: str):
        """Forwards inference requests with LOR balancing, disconnect detection, and upstream failover."""
        body = await request.body()
        req_headers = filter_forward_headers(dict(request.headers))

        client_host = request.client.host if request.client else None
        if client_host:
            existing_xff = req_headers.get("x-forwarded-for")
            req_headers["x-forwarded-for"] = f"{existing_xff}, {client_host}" if existing_xff else client_host
        req_headers["x-forwarded-proto"] = request.url.scheme

        attempted: set[Backend] = set()
        max_attempts = len(lb.backends)

        for attempt in range(max_attempts):
            backend = lb.select_backend(excluded_backends=attempted)
            if not backend:
                break
            attempted.add(backend)

            backend.increment_active_requests()
            try:
                upstream_req = backend.client.build_request(
                    method=request.method,
                    url=f"/{path}",
                    headers=req_headers,
                    params=request.query_params,
                    content=body,
                )
                upstream_resp = await backend.client.send(upstream_req, stream=True)

                # Upstream server error failover (before streaming response body)
                if upstream_resp.status_code in (502, 503, 504) and attempt < max_attempts - 1:
                    await upstream_resp.aclose()
                    backend.decrement_active_requests()
                    backend.consecutive_failures += 1
                    if backend.consecutive_failures >= 2:
                        backend.is_healthy = False
                    logger.warning(
                        "Upstream %s returned HTTP %d on attempt %d/%d. Retrying next backend...",
                        backend.url, upstream_resp.status_code, attempt + 1, max_attempts,
                    )
                    continue

                res_headers = filter_forward_headers(dict(upstream_resp.headers))

                return StreamingResponse(
                    make_stream_generator(upstream_resp, backend, request),
                    status_code=upstream_resp.status_code,
                    headers=res_headers,
                    media_type=upstream_resp.headers.get("content-type"),
                )

            except (httpx.RequestError, asyncio.TimeoutError) as exc:
                backend.decrement_active_requests()
                backend.is_healthy = False
                logger.warning(
                    "Upstream %s failed on attempt %d/%d (%s). Retrying next engine...",
                    backend.url, attempt + 1, max_attempts, exc,
                )
                continue

        healthy_count = sum(1 for b in lb.backends if b.is_healthy)
        status_code = 503 if healthy_count == 0 else 502
        err_msg = "Service Unavailable: No healthy backends" if healthy_count == 0 else "Bad Gateway: All upstream attempts failed"
        return JSONResponse(status_code=status_code, content={"error": err_msg})

    return app


def parse_args():
    parser = argparse.ArgumentParser(description="Production vLLM Inference Reverse Proxy")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="Host interface to bind")
    parser.add_argument("--port", type=int, default=8000, help="Proxy port (default: 8000)")
    parser.add_argument(
        "--targets",
        "--backends",
        dest="targets",
        nargs="+",
        default=["127.0.0.1:8001", "127.0.0.1:8002"],
        help="Target backend endpoints (e.g. 127.0.0.1:8001 127.0.0.1:8002)",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    logger.info("Initializing vLLM Reverse Proxy on %s:%d with backends: %s", args.host, args.port, args.targets)
    app = create_app(args.targets)
    uvicorn.run(app, host=args.host, port=args.port, log_level="info")
