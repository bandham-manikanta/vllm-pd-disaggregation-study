#!/bin/bash
#
# launch_collocated_4x_tp2.sh
#
# Multi-Node Collocated Baseline (4x TP=2 across 8 GPUs, 2 Nodes):
#   - Node A (a100-04):
#       - Engine 1: GPUs 0,1 (TP=2, Port 8001)
#       - Engine 2: GPUs 2,3 (TP=2, Port 8002)
#   - Node B (a100-02):
#       - Engine 3: GPUs 0,1 (TP=2, Port 8003)
#       - Engine 4: GPUs 2,3 (TP=2, Port 8004)
#   - Proxy: Node A Port 8000 (Central Round-Robin / LOR Load Balancer)
#
set -euo pipefail

MODEL=${1:-"Qwen/Qwen3-8B"}
NODE_A=${NODE_A:-"a100-04"}
NODE_B=${NODE_B:-"a100-02"}
IP_A=${IP_A:-"10.10.4.174"}
IP_B=${IP_B:-"10.10.4.172"}

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VENV_DIR="${VENV_DIR:-/gpfs/projects/MaffeiGroup/venvs/vllm_venv}"
LOG_DIR="${PROJECT_DIR}/logs"
PROXY_SCRIPT="${PROJECT_DIR}/scripts/collocated_round_robin_proxy.py"

export PATH="${VENV_DIR}/bin:$PATH"
mkdir -p "$LOG_DIR"

echo "================================================================="
echo " Launching Multi-Node Collocated Baseline (4x TP=2 across 8 GPUs)"
echo " Node A (${NODE_A}): Engine 1 (GPUs 0,1 :8001), Engine 2 (GPUs 2,3 :8002)"
echo " Node B (${NODE_B}): Engine 3 (GPUs 0,1 :8003), Engine 4 (GPUs 2,3 :8004)"
echo " Proxy:  ${NODE_A} Port 8000"
echo " Model:  ${MODEL}"
echo "================================================================="

echo "=== [1/6] Cleaning prior processes on ${NODE_A} and ${NODE_B} ==="
bash "${PROJECT_DIR}/scripts/stop_services.sh" "${NODE_A}" "${NODE_B}"

echo "=== [2/6] Launching Engines 1 & 2 on ${NODE_A} ==="
ssh "${NODE_A}" "nohup bash -c '
  export PATH=\"${VENV_DIR}/bin:\$PATH\"
  CUDA_VISIBLE_DEVICES=0,1 vllm serve \"${MODEL}\" --host 0.0.0.0 --tensor-parallel-size 2 --port 8001 --gpu-memory-utilization 0.85 >> \"${LOG_DIR}/collocated_4x_tp2_eng1_8001.log\" 2>&1 &
  CUDA_VISIBLE_DEVICES=2,3 vllm serve \"${MODEL}\" --host 0.0.0.0 --tensor-parallel-size 2 --port 8002 --gpu-memory-utilization 0.85 >> \"${LOG_DIR}/collocated_4x_tp2_eng2_8002.log\" 2>&1 &
' > /dev/null 2>&1 &"

echo "=== [3/6] Launching Engines 3 & 4 on ${NODE_B} ==="
ssh "${NODE_B}" "nohup bash -c '
  export PATH=\"${VENV_DIR}/bin:\$PATH\"
  CUDA_VISIBLE_DEVICES=0,1 vllm serve \"${MODEL}\" --host 0.0.0.0 --tensor-parallel-size 2 --port 8003 --gpu-memory-utilization 0.85 >> \"${LOG_DIR}/collocated_4x_tp2_eng3_8003.log\" 2>&1 &
  CUDA_VISIBLE_DEVICES=2,3 vllm serve \"${MODEL}\" --host 0.0.0.0 --tensor-parallel-size 2 --port 8004 --gpu-memory-utilization 0.85 >> \"${LOG_DIR}/collocated_4x_tp2_eng4_8004.log\" 2>&1 &
' > /dev/null 2>&1 &"

MAX_WAIT="${MAX_WAIT:-300}"

echo "Waiting for all 4 engines to become healthy..."
for p in 8001 8002; do
  ELAPSED=0
  until curl -s -f "http://${IP_A}:${p}/health" > /dev/null 2>&1; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then echo "[!] TIMEOUT on ${NODE_A}:${p}"; exit 1; fi
    sleep 2; ELAPSED=$((ELAPSED + 2))
  done
  echo "[✓] Engine on ${NODE_A}:${p} is ready!"
done

for p in 8003 8004; do
  ELAPSED=0
  until curl -s -f "http://${IP_B}:${p}/health" > /dev/null 2>&1; do
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then echo "[!] TIMEOUT on ${NODE_B}:${p}"; exit 1; fi
    sleep 2; ELAPSED=$((ELAPSED + 2))
  done
  echo "[✓] Engine on ${NODE_B}:${p} is ready!"
done

echo "=== [4/6] Launching Multi-Node Load Balancer on ${NODE_A}:8000 ==="
ssh "${NODE_A}" "nohup bash -c '
  export PATH=\"${VENV_DIR}/bin:\$PATH\"
  python3 \"${PROXY_SCRIPT}\" --port 8000 \
    --backends 127.0.0.1:8001 127.0.0.1:8002 ${IP_B}:8003 ${IP_B}:8004 \
    >> \"${LOG_DIR}/collocated_4x_tp2_proxy_8000.log\" 2>&1
' > /dev/null 2>&1 &"

echo "Waiting for central proxy (8000)..."
ELAPSED=0
until curl -s -f "http://${IP_A}:8000/healthcheck" > /dev/null 2>&1; do
  if [ "$ELAPSED" -ge 30 ]; then echo "[!] TIMEOUT: Central proxy failed."; exit 1; fi
  sleep 1; ELAPSED=$((ELAPSED + 1))
done
echo "[✓] Multi-Node Collocated 4x TP=2 Load Balancer is ready on ${NODE_A}:8000!"
