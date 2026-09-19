#!/bin/bash
#
# launch_collocated_2x_tp1.sh
#
# Launch 2x Collocated vLLM TP=1 Replicas with Central Load Balancer (2 GPUs)
#   - Engine 1: GPU 0 (Port 8001)
#   - Engine 2: GPU 1 (Port 8002)
#   - Proxy:    Port 8000
#
set -euo pipefail

MODEL=${1:-"Qwen/Qwen3-8B"}

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VENV_DIR="${VENV_DIR:-/gpfs/projects/MaffeiGroup/venvs/vllm_venv}"
LOG_DIR="${PROJECT_DIR}/logs"
PROXY_SCRIPT="${PROJECT_DIR}/scripts/collocated_round_robin_proxy.py"

export PATH="${VENV_DIR}/bin:$PATH"
mkdir -p "$LOG_DIR"

echo "================================================================="
echo " Launching Collocated Baseline: 2x TP=1 Replicas across 2 GPUs"
echo " Engine 1: GPU 0 (TP=1, Port 8001)"
echo " Engine 2: GPU 1 (TP=1, Port 8002)"
echo " Proxy:    Port 8000 (Central Load Balancer)"
echo " Model:    ${MODEL}"
echo "================================================================="

echo "=== [1/4] Cleaning prior processes ==="
bash "${PROJECT_DIR}/scripts/stop_services.sh"

echo "=== [2/4] Launching Collocated Engine 1 on GPU 0 (Port 8001) ==="
CUDA_VISIBLE_DEVICES=0 \
nohup vllm serve "${MODEL}" \
  --host 0.0.0.0 \
  --tensor-parallel-size 1 \
  --port 8001 \
  --gpu-memory-utilization 0.85 \
  >> "${LOG_DIR}/collocated_2x_tp1_engine1_8001.log" 2>&1 &
ENG1_PID=$!

echo "=== [3/4] Launching Collocated Engine 2 on GPU 1 (Port 8002) ==="
CUDA_VISIBLE_DEVICES=1 \
nohup vllm serve "${MODEL}" \
  --host 0.0.0.0 \
  --tensor-parallel-size 1 \
  --port 8002 \
  --gpu-memory-utilization 0.85 \
  >> "${LOG_DIR}/collocated_2x_tp1_engine2_8002.log" 2>&1 &
ENG2_PID=$!

MAX_WAIT="${MAX_WAIT:-300}"

echo "Waiting for Engine 1 (8001)..."
ELAPSED=0
until curl -s -f "http://127.0.0.1:8001/health" > /dev/null 2>&1; do
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "[!] TIMEOUT: Engine 1 failed to become ready within ${MAX_WAIT}s."
    tail -n 30 "${LOG_DIR}/collocated_2x_tp1_engine1_8001.log"
    exit 1
  fi
  sleep 2
  ELAPSED=$((ELAPSED + 2))
done
echo "[✓] Engine 1 (Port 8001) is ready!"

echo "Waiting for Engine 2 (8002)..."
ELAPSED=0
until curl -s -f "http://127.0.0.1:8002/health" > /dev/null 2>&1; do
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "[!] TIMEOUT: Engine 2 failed to become ready within ${MAX_WAIT}s."
    tail -n 30 "${LOG_DIR}/collocated_2x_tp1_engine2_8002.log"
    exit 1
  fi
  sleep 2
  ELAPSED=$((ELAPSED + 2))
done
echo "[✓] Engine 2 (Port 8002) is ready!"

echo "=== [4/4] Launching Central Load Balancer on Port 8000 ==="
nohup python3 "${PROXY_SCRIPT}" \
  --port 8000 \
  --backends 127.0.0.1:8001 127.0.0.1:8002 \
  >> "${LOG_DIR}/collocated_2x_tp1_proxy_8000.log" 2>&1 &
PROXY_PID=$!

echo "Waiting for Proxy (8000)..."
ELAPSED=0
until curl -s -f "http://127.0.0.1:8000/healthcheck" > /dev/null 2>&1; do
  if [ "$ELAPSED" -ge 30 ]; then
    echo "[!] TIMEOUT: Proxy on port 8000 failed to become ready."
    tail -n 30 "${LOG_DIR}/collocated_2x_tp1_proxy_8000.log"
    exit 1
  fi
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done
echo "[✓] Collocated 2x TP=1 Load Balancer is ready on Port 8000!"
echo "================================================================="
echo " ALL SERVICES READY!"
echo " Target Endpoint: http://127.0.0.1:8000/v1/completions"
echo "================================================================="
