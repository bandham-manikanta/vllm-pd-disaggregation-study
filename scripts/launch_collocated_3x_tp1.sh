#!/bin/bash
#
# launch_collocated_3x_tp1.sh
#
# Launch 3x Collocated TP=1 Engines (3 GPUs total)
# Supports:
#   - Single Node (a100-04): Engine 1 (GPU 0), Engine 2 (GPU 1), Engine 3 (GPU 2)
#   - Cross Node: Node A (GPU 0) + Node B (GPUs 0, 1)
#   - Proxy: Port 8000 (Central Round-Robin Load Balancer)
#
set -euo pipefail

MODEL=${1:-"Qwen/Qwen3-8B"}
NODE_A=${NODE_A:-"a100-04"}
NODE_B=${NODE_B:-"a100-04"}
IP_A=${IP_A:-"10.10.4.174"}
IP_B=${IP_B:-"10.10.4.174"}

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VENV_DIR="${VENV_DIR:-/gpfs/projects/MaffeiGroup/venvs/vllm_venv}"
LOG_DIR="${PROJECT_DIR}/logs"
PROXY_SCRIPT="${PROJECT_DIR}/scripts/collocated_round_robin_proxy.py"

export PATH="${VENV_DIR}/bin:$PATH"
mkdir -p "$LOG_DIR"

if [ "${NODE_A}" = "${NODE_B}" ]; then
  GPU_ENG1=0
  GPU_ENG2=1
  GPU_ENG3=2
  IS_SINGLE_NODE=1
else
  GPU_ENG1=0
  GPU_ENG2=0
  GPU_ENG3=1
  IS_SINGLE_NODE=0
fi

LOG_ENG1="${LOG_DIR}/collocated_3x_tp1_engine1_8001.log"
LOG_ENG2="${LOG_DIR}/collocated_3x_tp1_engine2_8002.log"
LOG_ENG3="${LOG_DIR}/collocated_3x_tp1_engine3_8003.log"
LOG_PROXY="${LOG_DIR}/collocated_3x_tp1_proxy_8000.log"

echo "================================================================="
echo " Launching Collocated Baseline: 3x TP=1 across 3 GPUs"
echo " Engine 1: ${NODE_A} GPU ${GPU_ENG1} (Port 8001)"
echo " Engine 2: ${NODE_B} GPU ${GPU_ENG2} (Port 8002)"
echo " Engine 3: ${NODE_B} GPU ${GPU_ENG3} (Port 8003)"
echo " Proxy:    ${NODE_A} Port 8000"
echo " Model:    ${MODEL}"
echo " Mode:     $([ "$IS_SINGLE_NODE" -eq 1 ] && echo 'Single Node Native' || echo 'Cross-Node SSH')"
echo "================================================================="

echo "=== [1/5] Cleaning prior processes ==="
if [ "$IS_SINGLE_NODE" -eq 1 ]; then
  bash "${PROJECT_DIR}/scripts/stop_services.sh" "${NODE_A}"
else
  bash "${PROJECT_DIR}/scripts/stop_services.sh" "${NODE_A}" "${NODE_B}"
fi

echo "=== [2/5] Launching Engine 1 (Port 8001) ==="
if [ "$IS_SINGLE_NODE" -eq 1 ]; then
  CUDA_VISIBLE_DEVICES=${GPU_ENG1} \
  nohup vllm serve "${MODEL}" \
    --host 0.0.0.0 \
    --tensor-parallel-size 1 \
    --port 8001 \
    --gpu-memory-utilization 0.85 \
    >> "${LOG_ENG1}" 2>&1 &
  PID_ENG1=$!
else
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${NODE_A}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=${GPU_ENG1} vllm serve \"${MODEL}\" --host 0.0.0.0 --tensor-parallel-size 1 --port 8001 --gpu-memory-utilization 0.85 >> \"${LOG_ENG1}\" 2>&1
  ' > /dev/null 2>&1 &"
  PID_ENG1=""
fi

echo "=== [3/5] Launching Engine 2 (Port 8002) ==="
if [ "$IS_SINGLE_NODE" -eq 1 ]; then
  CUDA_VISIBLE_DEVICES=${GPU_ENG2} \
  nohup vllm serve "${MODEL}" \
    --host 0.0.0.0 \
    --tensor-parallel-size 1 \
    --port 8002 \
    --gpu-memory-utilization 0.85 \
    >> "${LOG_ENG2}" 2>&1 &
  PID_ENG2=$!
else
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${NODE_B}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=${GPU_ENG2} vllm serve \"${MODEL}\" --host 0.0.0.0 --tensor-parallel-size 1 --port 8002 --gpu-memory-utilization 0.85 >> \"${LOG_ENG2}\" 2>&1
  ' > /dev/null 2>&1 &"
  PID_ENG2=""
fi

echo "=== [4/5] Launching Engine 3 (Port 8003) ==="
if [ "$IS_SINGLE_NODE" -eq 1 ]; then
  CUDA_VISIBLE_DEVICES=${GPU_ENG3} \
  nohup vllm serve "${MODEL}" \
    --host 0.0.0.0 \
    --tensor-parallel-size 1 \
    --port 8003 \
    --gpu-memory-utilization 0.85 \
    >> "${LOG_ENG3}" 2>&1 &
  PID_ENG3=$!
else
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${NODE_B}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=${GPU_ENG3} vllm serve \"${MODEL}\" --host 0.0.0.0 --tensor-parallel-size 1 --port 8003 --gpu-memory-utilization 0.85 >> \"${LOG_ENG3}\" 2>&1
  ' > /dev/null 2>&1 &"
  PID_ENG3=""
fi

MAX_WAIT="${MAX_WAIT:-300}"

echo "Waiting for Engine 1 (8001)..."
ELAPSED=0
until curl -s -f "http://${IP_A}:8001/health" > /dev/null 2>&1; do
  if [ -n "$PID_ENG1" ] && ! kill -0 "$PID_ENG1" 2>/dev/null; then
    echo "[!] FATAL: Engine 1 exited unexpectedly!"
    tail -n 30 "${LOG_ENG1}"
    exit 1
  fi
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "[!] TIMEOUT on Engine 1 after ${MAX_WAIT}s"
    tail -n 30 "${LOG_ENG1}"
    exit 1
  fi
  sleep 2; ELAPSED=$((ELAPSED + 2))
  if [ $((ELAPSED % 10)) -eq 0 ]; then
    echo "    ... waiting for Engine 1 (${ELAPSED}s / ${MAX_WAIT}s)"
  fi
done
echo "[✓] Engine 1 is ready!"

echo "Waiting for Engine 2 (8002)..."
ELAPSED=0
until curl -s -f "http://${IP_B}:8002/health" > /dev/null 2>&1; do
  if [ -n "$PID_ENG2" ] && ! kill -0 "$PID_ENG2" 2>/dev/null; then
    echo "[!] FATAL: Engine 2 exited unexpectedly!"
    tail -n 30 "${LOG_ENG2}"
    exit 1
  fi
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "[!] TIMEOUT on Engine 2 after ${MAX_WAIT}s"
    tail -n 30 "${LOG_ENG2}"
    exit 1
  fi
  sleep 2; ELAPSED=$((ELAPSED + 2))
  if [ $((ELAPSED % 10)) -eq 0 ]; then
    echo "    ... waiting for Engine 2 (${ELAPSED}s / ${MAX_WAIT}s)"
  fi
done
echo "[✓] Engine 2 is ready!"

echo "Waiting for Engine 3 (8003)..."
ELAPSED=0
until curl -s -f "http://${IP_B}:8003/health" > /dev/null 2>&1; do
  if [ -n "$PID_ENG3" ] && ! kill -0 "$PID_ENG3" 2>/dev/null; then
    echo "[!] FATAL: Engine 3 exited unexpectedly!"
    tail -n 30 "${LOG_ENG3}"
    exit 1
  fi
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "[!] TIMEOUT on Engine 3 after ${MAX_WAIT}s"
    tail -n 30 "${LOG_ENG3}"
    exit 1
  fi
  sleep 2; ELAPSED=$((ELAPSED + 2))
  if [ $((ELAPSED % 10)) -eq 0 ]; then
    echo "    ... waiting for Engine 3 (${ELAPSED}s / ${MAX_WAIT}s)"
  fi
done
echo "[✓] Engine 3 is ready!"

echo "=== [5/5] Launching Central Load Balancer on ${NODE_A}:8000 ==="
if [ "$IS_SINGLE_NODE" -eq 1 ]; then
  nohup python3 "${PROXY_SCRIPT}" \
    --port 8000 \
    --backends 127.0.0.1:8001 127.0.0.1:8002 127.0.0.1:8003 \
    >> "${LOG_PROXY}" 2>&1 &
  PID_PROXY=$!
else
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${NODE_A}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    python3 \"${PROXY_SCRIPT}\" --port 8000 --backends 127.0.0.1:8001 ${IP_B}:8002 ${IP_B}:8003 >> \"${LOG_PROXY}\" 2>&1
  ' > /dev/null 2>&1 &"
  PID_PROXY=""
fi

echo "Waiting for Central Proxy (8000)..."
ELAPSED=0
until curl -s -f "http://${IP_A}:8000/healthcheck" > /dev/null 2>&1; do
  if [ -n "$PID_PROXY" ] && ! kill -0 "$PID_PROXY" 2>/dev/null; then
    echo "[!] FATAL: Central proxy exited unexpectedly!"
    tail -n 30 "${LOG_PROXY}"
    exit 1
  fi
  if [ "$ELAPSED" -ge 30 ]; then
    echo "[!] TIMEOUT on Central Proxy after 30s"
    tail -n 30 "${LOG_PROXY}"
    exit 1
  fi
  sleep 1; ELAPSED=$((ELAPSED + 1))
done
echo "[✓] Collocated 3x TP=1 Load Balancer is ready on Port 8000!"
