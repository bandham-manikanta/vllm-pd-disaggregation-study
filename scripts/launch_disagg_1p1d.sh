#!/bin/bash
#
# launch_disagg_1p1d.sh
#
# Launch Disaggregated 1P:1D on a single node (GPUs 0 and 1 over NVLink 12)
# Prefill: GPU 0 (TP=1, Port 8100)
# Decode:  GPU 1 (TP=1, Port 8200)
# Proxy:   Port 8000
#
set -euo pipefail

MODEL=${1:-"Qwen/Qwen3-8B"}

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VLLM_DIR="${VLLM_DIR:-/gpfs/projects/MaffeiGroup/open-source-contributions/vllm}"
VENV_DIR="${VENV_DIR:-/gpfs/projects/MaffeiGroup/venvs/vllm_venv}"
LOG_DIR="${PROJECT_DIR}/logs"
PROXY_SCRIPT="${VLLM_DIR}/tests/v1/kv_connector/nixl_integration/toy_proxy_server.py"

PREFILL_LOG="${LOG_DIR}/disagg_1p1d_prefill_8100.log"
DECODE_LOG="${LOG_DIR}/disagg_1p1d_decode_8200.log"
PROXY_LOG="${LOG_DIR}/disagg_1p1d_proxy_8000.log"

export PATH="${VENV_DIR}/bin:$PATH"
mkdir -p "$LOG_DIR"

echo "=== Cleaning prior processes for user $USER ==="
bash "${PROJECT_DIR}/scripts/stop_services.sh"

echo "=== Launching Prefill on GPU 0 (Port 8100) ==="
CUDA_VISIBLE_DEVICES=0 \
UCX_NET_DEVICES=all \
VLLM_NIXL_SIDE_CHANNEL_PORT=5559 \
nohup vllm serve "$MODEL" \
  --tensor-parallel-size 1 \
  --port 8100 \
  --gpu-memory-utilization 0.85 \
  --kv-transfer-config '{"kv_connector": "NixlConnector", "kv_role": "kv_producer", "kv_buffer_device": "cuda", "kv_connector_extra_config": {"kv_lease_duration": 300}}' \
  >> "$PREFILL_LOG" 2>&1 &
PREFILL_PID=$!

echo "=== Launching Decode on GPU 1 (Port 8200) ==="
CUDA_VISIBLE_DEVICES=1 \
UCX_NET_DEVICES=all \
VLLM_NIXL_SIDE_CHANNEL_PORT=6000 \
nohup vllm serve "$MODEL" \
  --tensor-parallel-size 1 \
  --port 8200 \
  --gpu-memory-utilization 0.85 \
  --kv-transfer-config '{"kv_connector": "NixlConnector", "kv_role": "kv_consumer", "kv_buffer_device": "cuda", "kv_connector_extra_config": {"kv_lease_duration": 300}}' \
  >> "$DECODE_LOG" 2>&1 &
DECODE_PID=$!

MAX_WAIT="${MAX_WAIT:-300}"
echo "Waiting for prefill server (8100, PID: $PREFILL_PID)..."
ELAPSED=0
until curl -s -f "http://127.0.0.1:8100/health" > /dev/null 2>&1; do
  if ! kill -0 "$PREFILL_PID" 2>/dev/null; then
    echo "[!] FATAL: Prefill server (PID: $PREFILL_PID) exited unexpectedly!"
    tail -n 30 "$PREFILL_LOG"
    exit 1
  fi
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "[!] TIMEOUT: Prefill server failed to become ready within ${MAX_WAIT}s."
    echo "--- Last 30 lines of $PREFILL_LOG ---"
    tail -n 30 "$PREFILL_LOG"
    exit 1
  fi
  sleep 2
  ELAPSED=$((ELAPSED + 2))
  if [ $((ELAPSED % 10)) -eq 0 ]; then
    echo "    ... waiting for prefill server (${ELAPSED}s / ${MAX_WAIT}s)"
  fi
done
echo "[✓] Prefill server (8100, TP=1) is ready!"

echo "Waiting for decode server (8200, PID: $DECODE_PID)..."
ELAPSED=0
until curl -s -f "http://127.0.0.1:8200/health" > /dev/null 2>&1; do
  if ! kill -0 "$DECODE_PID" 2>/dev/null; then
    echo "[!] FATAL: Decode server (PID: $DECODE_PID) exited unexpectedly!"
    tail -n 30 "$DECODE_LOG"
    exit 1
  fi
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "[!] TIMEOUT: Decode server failed to become ready within ${MAX_WAIT}s."
    echo "--- Last 30 lines of $DECODE_LOG ---"
    tail -n 30 "$DECODE_LOG"
    exit 1
  fi
  sleep 2
  ELAPSED=$((ELAPSED + 2))
  if [ $((ELAPSED % 10)) -eq 0 ]; then
    echo "    ... waiting for decode server (${ELAPSED}s / ${MAX_WAIT}s)"
  fi
done
echo "[✓] Decode server (8200, TP=1) is ready!"

echo "=== Launching Disagg Proxy on Port 8000 ==="
nohup python3 "${PROXY_SCRIPT}" \
  --port 8000 \
  --prefiller-hosts 127.0.0.1 --prefiller-ports 8100 \
  --decoder-hosts 127.0.0.1 --decoder-ports 8200 \
  >> "$PROXY_LOG" 2>&1 &
PROXY_PID=$!

echo "Waiting for proxy (8000, PID: $PROXY_PID)..."
ELAPSED=0
until curl -s -f "http://127.0.0.1:8000/healthcheck" > /dev/null 2>&1; do
  if ! kill -0 "$PROXY_PID" 2>/dev/null; then
    echo "[!] FATAL: Proxy server (PID: $PROXY_PID) exited unexpectedly!"
    tail -n 25 "$PROXY_LOG"
    exit 1
  fi
  if [ "$ELAPSED" -ge 30 ]; then
    echo "[!] TIMEOUT: Proxy failed to become ready within 30s."
    exit 1
  fi
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done
echo "[✓] Proxy (8000) is ready!"
echo "================================================================="
echo " ALL DISAGGREGATED 1P:1D SERVICES READY!"
echo " Logs stored in: ${LOG_DIR}"
echo " Target Endpoint: http://127.0.0.1:8000/v1/completions"
echo "================================================================="
