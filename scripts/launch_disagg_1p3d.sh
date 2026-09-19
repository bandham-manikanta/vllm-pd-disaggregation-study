#!/bin/bash
#
# launch_disagg_1p3d.sh
#
# Disaggregated 1P:3D Asymmetric Multiplexing across 4 GPUs
# Supports:
#   - Single Node (a100-04): GPU 0 (P), GPU 1 (D1), GPU 2 (D2), GPU 3 (D3)
#   - Cross Node: Node A (GPU 0=P, GPU 1=D1) -> Node B (GPU 0=D2, GPU 1=D3)
#   - Proxy: Port 8000
#
set -euo pipefail

MODEL=${1:-"Qwen/Qwen3-8B"}
NODE_PREFILL=${NODE_PREFILL:-"a100-04"}
NODE_DECODE=${NODE_DECODE:-"a100-02"}
IP_PREFILL=${IP_PREFILL:-"10.10.4.174"}
IP_DECODE=${IP_DECODE:-"10.10.4.172"}

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VLLM_DIR="${VLLM_DIR:-/gpfs/projects/MaffeiGroup/open-source-contributions/vllm}"
VENV_DIR="${VENV_DIR:-/gpfs/projects/MaffeiGroup/venvs/vllm_venv}"
LOG_DIR="${PROJECT_DIR}/logs"
PROXY_SCRIPT="${VLLM_DIR}/tests/v1/kv_connector/nixl_integration/toy_proxy_server.py"

export PATH="${VENV_DIR}/bin:$PATH"
mkdir -p "$LOG_DIR"

if [ "${NODE_PREFILL}" = "${NODE_DECODE}" ]; then
  GPU_P=0
  GPU_D1=1
  GPU_D2=2
  GPU_D3=3
  IS_SINGLE_NODE=1
  UCX_NET_DEV="all"
else
  GPU_P=0
  GPU_D1=1
  GPU_D2=0
  GPU_D3=1
  IS_SINGLE_NODE=0
  UCX_NET_DEV="mlx5_0:1"
fi

LOG_PREFILL="${LOG_DIR}/disagg_1p3d_prefill_8100.log"
LOG_DEC1="${LOG_DIR}/disagg_1p3d_decode1_8201.log"
LOG_DEC2="${LOG_DIR}/disagg_1p3d_decode2_8202.log"
LOG_DEC3="${LOG_DIR}/disagg_1p3d_decode3_8203.log"
LOG_PROXY="${LOG_DIR}/disagg_1p3d_proxy_8000.log"

echo "================================================================="
echo " Launching Disaggregated 1P:3D (4 GPUs)"
echo " Prefill:   ${NODE_PREFILL} GPU ${GPU_P} (TP=1, Port 8100)"
echo " Decoder 1: ${NODE_PREFILL} GPU ${GPU_D1} (TP=1, Port 8201)"
echo " Decoder 2: ${NODE_DECODE}  GPU ${GPU_D2} (TP=1, Port 8202)"
echo " Decoder 3: ${NODE_DECODE}  GPU ${GPU_D3} (TP=1, Port 8203)"
echo " Proxy:     ${NODE_DECODE}  Port 8000"
echo " Model:     ${MODEL}"
echo " Transport: UCX_NET_DEVICES=${UCX_NET_DEV}"
echo " Mode:      $([ "$IS_SINGLE_NODE" -eq 1 ] && echo 'Single Node Native' || echo 'Cross-Node SSH')"
echo "================================================================="

echo "=== [1/6] Cleaning prior processes ==="
if [ "$IS_SINGLE_NODE" -eq 1 ]; then
  bash "${PROJECT_DIR}/scripts/stop_services.sh" "${NODE_PREFILL}"
else
  bash "${PROJECT_DIR}/scripts/stop_services.sh" "${NODE_PREFILL}" "${NODE_DECODE}"
fi

echo "=== [2/6] Launching Prefill on GPU ${GPU_P} (Port 8100) ==="
if [ "$IS_SINGLE_NODE" -eq 1 ]; then
  CUDA_VISIBLE_DEVICES=${GPU_P} \
  UCX_NET_DEVICES=${UCX_NET_DEV} \
  VLLM_NIXL_SIDE_CHANNEL_PORT=5559 \
  nohup vllm serve "${MODEL}" \
    --host 0.0.0.0 \
    --tensor-parallel-size 1 \
    --port 8100 \
    --gpu-memory-utilization 0.85 \
    --kv-transfer-config '{"kv_connector": "NixlConnector", "kv_role": "kv_producer", "kv_buffer_device": "cuda", "kv_connector_extra_config": {"kv_lease_duration": 300}}' \
    >> "${LOG_PREFILL}" 2>&1 &
  PID_P=$!
else
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${NODE_PREFILL}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=${GPU_P} UCX_NET_DEVICES=${UCX_NET_DEV} VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP_PREFILL}\" VLLM_NIXL_SIDE_CHANNEL_PORT=5559 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --tensor-parallel-size 1 --port 8100 --gpu-memory-utilization 0.85 \
      --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_producer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
      >> \"${LOG_PREFILL}\" 2>&1
  ' > /dev/null 2>&1 &"
  PID_P=""
fi

echo "=== [3/6] Launching Decoder 1 on GPU ${GPU_D1} (Port 8201) ==="
if [ "$IS_SINGLE_NODE" -eq 1 ]; then
  CUDA_VISIBLE_DEVICES=${GPU_D1} \
  UCX_NET_DEVICES=${UCX_NET_DEV} \
  VLLM_NIXL_SIDE_CHANNEL_PORT=6001 \
  nohup vllm serve "${MODEL}" \
    --host 0.0.0.0 \
    --tensor-parallel-size 1 \
    --port 8201 \
    --gpu-memory-utilization 0.85 \
    --kv-transfer-config '{"kv_connector": "NixlConnector", "kv_role": "kv_consumer", "kv_buffer_device": "cuda", "kv_connector_extra_config": {"kv_lease_duration": 300}}' \
    >> "${LOG_DEC1}" 2>&1 &
  PID_D1=$!
else
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${NODE_PREFILL}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=${GPU_D1} UCX_NET_DEVICES=${UCX_NET_DEV} VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP_PREFILL}\" VLLM_NIXL_SIDE_CHANNEL_PORT=6001 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --tensor-parallel-size 1 --port 8201 --gpu-memory-utilization 0.85 \
      --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_consumer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
      >> \"${LOG_DEC1}\" 2>&1
  ' > /dev/null 2>&1 &"
  PID_D1=""
fi

echo "=== [4/6] Launching Decoder 2 on GPU ${GPU_D2} (Port 8202) ==="
if [ "$IS_SINGLE_NODE" -eq 1 ]; then
  CUDA_VISIBLE_DEVICES=${GPU_D2} \
  UCX_NET_DEVICES=${UCX_NET_DEV} \
  VLLM_NIXL_SIDE_CHANNEL_PORT=6002 \
  nohup vllm serve "${MODEL}" \
    --host 0.0.0.0 \
    --tensor-parallel-size 1 \
    --port 8202 \
    --gpu-memory-utilization 0.85 \
    --kv-transfer-config '{"kv_connector": "NixlConnector", "kv_role": "kv_consumer", "kv_buffer_device": "cuda", "kv_connector_extra_config": {"kv_lease_duration": 300}}' \
    >> "${LOG_DEC2}" 2>&1 &
  PID_D2=$!
else
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${NODE_DECODE}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=${GPU_D2} UCX_NET_DEVICES=${UCX_NET_DEV} VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP_DECODE}\" VLLM_NIXL_SIDE_CHANNEL_PORT=6002 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --tensor-parallel-size 1 --port 8202 --gpu-memory-utilization 0.85 \
      --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_consumer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
      >> \"${LOG_DEC2}\" 2>&1
  ' > /dev/null 2>&1 &"
  PID_D2=""
fi

echo "=== [5/6] Launching Decoder 3 on GPU ${GPU_D3} (Port 8203) ==="
if [ "$IS_SINGLE_NODE" -eq 1 ]; then
  CUDA_VISIBLE_DEVICES=${GPU_D3} \
  UCX_NET_DEVICES=${UCX_NET_DEV} \
  VLLM_NIXL_SIDE_CHANNEL_PORT=6003 \
  nohup vllm serve "${MODEL}" \
    --host 0.0.0.0 \
    --tensor-parallel-size 1 \
    --port 8203 \
    --gpu-memory-utilization 0.85 \
    --kv-transfer-config '{"kv_connector": "NixlConnector", "kv_role": "kv_consumer", "kv_buffer_device": "cuda", "kv_connector_extra_config": {"kv_lease_duration": 300}}' \
    >> "${LOG_DEC3}" 2>&1 &
  PID_D3=$!
else
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${NODE_DECODE}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=${GPU_D3} UCX_NET_DEVICES=${UCX_NET_DEV} VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP_DECODE}\" VLLM_NIXL_SIDE_CHANNEL_PORT=6003 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --tensor-parallel-size 1 --port 8203 --gpu-memory-utilization 0.85 \
      --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_consumer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
      >> \"${LOG_DEC3}\" 2>&1
  ' > /dev/null 2>&1 &"
  PID_D3=""
fi

MAX_WAIT="${MAX_WAIT:-300}"

echo "Waiting for Prefill server (Port 8100)..."
ELAPSED=0
until curl -s -f "http://${IP_PREFILL}:8100/health" > /dev/null 2>&1; do
  if [ -n "$PID_P" ] && ! kill -0 "$PID_P" 2>/dev/null; then echo "[!] FATAL: Prefill exited!"; tail -n 30 "${LOG_PREFILL}"; exit 1; fi
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then echo "[!] TIMEOUT on Prefill"; tail -n 30 "${LOG_PREFILL}"; exit 1; fi
  sleep 2; ELAPSED=$((ELAPSED + 2))
  if [ $((ELAPSED % 10)) -eq 0 ]; then echo "    ... waiting for prefill (${ELAPSED}s / ${MAX_WAIT}s)"; fi
done
echo "[✓] Prefill server is ready!"

echo "Waiting for Decoder 1 (Port 8201)..."
ELAPSED=0
until curl -s -f "http://${IP_PREFILL}:8201/health" > /dev/null 2>&1; do
  if [ -n "$PID_D1" ] && ! kill -0 "$PID_D1" 2>/dev/null; then echo "[!] FATAL: Decoder 1 exited!"; tail -n 30 "${LOG_DEC1}"; exit 1; fi
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then echo "[!] TIMEOUT on Decoder 1"; tail -n 30 "${LOG_DEC1}"; exit 1; fi
  sleep 2; ELAPSED=$((ELAPSED + 2))
  if [ $((ELAPSED % 10)) -eq 0 ]; then echo "    ... waiting for Decoder 1 (${ELAPSED}s / ${MAX_WAIT}s)"; fi
done
echo "[✓] Decoder 1 is ready!"

echo "Waiting for Decoder 2 (Port 8202)..."
ELAPSED=0
until curl -s -f "http://${IP_DECODE}:8202/health" > /dev/null 2>&1; do
  if [ -n "$PID_D2" ] && ! kill -0 "$PID_D2" 2>/dev/null; then echo "[!] FATAL: Decoder 2 exited!"; tail -n 30 "${LOG_DEC2}"; exit 1; fi
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then echo "[!] TIMEOUT on Decoder 2"; tail -n 30 "${LOG_DEC2}"; exit 1; fi
  sleep 2; ELAPSED=$((ELAPSED + 2))
  if [ $((ELAPSED % 10)) -eq 0 ]; then echo "    ... waiting for Decoder 2 (${ELAPSED}s / ${MAX_WAIT}s)"; fi
done
echo "[✓] Decoder 2 is ready!"

echo "Waiting for Decoder 3 (Port 8203)..."
ELAPSED=0
until curl -s -f "http://${IP_DECODE}:8203/health" > /dev/null 2>&1; do
  if [ -n "$PID_D3" ] && ! kill -0 "$PID_D3" 2>/dev/null; then echo "[!] FATAL: Decoder 3 exited!"; tail -n 30 "${LOG_DEC3}"; exit 1; fi
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then echo "[!] TIMEOUT on Decoder 3"; tail -n 30 "${LOG_DEC3}"; exit 1; fi
  sleep 2; ELAPSED=$((ELAPSED + 2))
  if [ $((ELAPSED % 10)) -eq 0 ]; then echo "    ... waiting for Decoder 3 (${ELAPSED}s / ${MAX_WAIT}s)"; fi
done
echo "[✓] Decoder 3 is ready!"

echo "=== [6/6] Launching Disagg 1P:3D Proxy on Port 8000 ==="
nohup python3 "${PROXY_SCRIPT}" \
  --port 8000 \
  --prefiller-hosts "${IP_PREFILL}" --prefiller-ports 8100 \
  --decoder-hosts "${IP_PREFILL}" "${IP_DECODE}" "${IP_DECODE}" --decoder-ports 8201 8202 8203 \
  >> "${LOG_PROXY}" 2>&1 &
PID_PROXY=$!

echo "Waiting for Disagg Proxy (8000)..."
ELAPSED=0
until curl -s -f "http://127.0.0.1:8000/healthcheck" > /dev/null 2>&1; do
  if ! kill -0 "$PID_PROXY" 2>/dev/null; then echo "[!] FATAL: Proxy exited!"; tail -n 30 "${LOG_PROXY}"; exit 1; fi
  if [ "$ELAPSED" -ge 30 ]; then echo "[!] TIMEOUT on proxy"; tail -n 30 "${LOG_PROXY}"; exit 1; fi
  sleep 1; ELAPSED=$((ELAPSED + 1))
done
echo "[✓] Disagg 1P:3D Proxy is ready on Port 8000!"
echo "================================================================="
echo " ALL SERVICES READY! Target Endpoint: http://127.0.0.1:8000/v1/completions"
echo "================================================================="
