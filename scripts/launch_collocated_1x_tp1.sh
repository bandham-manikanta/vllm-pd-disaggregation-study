#!/bin/bash
#
# launch_collocated_1x_tp1.sh
#
# Launch Single Collocated vLLM Instance (TP=1 on GPU 0, Port 8000)
#
set -euo pipefail

MODEL=${1:-"Qwen/Qwen3-8B"}
PORT=${2:-8000}

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VENV_DIR="${VENV_DIR:-/gpfs/projects/MaffeiGroup/venvs/vllm_venv}"
LOG_DIR="${PROJECT_DIR}/logs"
LOG_FILE="${LOG_DIR}/collocated_1x_tp1_8000.log"

export PATH="${VENV_DIR}/bin:$PATH"
mkdir -p "$LOG_DIR"

echo "=== Cleaning prior processes on port $PORT for user $USER ==="
bash "${PROJECT_DIR}/scripts/stop_services.sh"

echo "=== Launching Collocated vLLM (TP=1 on GPU 0, Port $PORT) ==="
CUDA_VISIBLE_DEVICES=0 \
nohup vllm serve "$MODEL" \
  --tensor-parallel-size 1 \
  --port "$PORT" \
  --gpu-memory-utilization 0.85 \
  >> "$LOG_FILE" 2>&1 &
SERVER_PID=$!

echo "Waiting for collocated server ($PORT, PID: $SERVER_PID)..."
MAX_WAIT="${MAX_WAIT:-300}"
ELAPSED=0
until curl -s -f "http://127.0.0.1:$PORT/health" > /dev/null 2>&1; do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "[!] FATAL: Collocated server (PID: $SERVER_PID) exited unexpectedly!"
    tail -n 30 "$LOG_FILE"
    exit 1
  fi
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "[!] TIMEOUT: Collocated server failed to become ready within ${MAX_WAIT}s."
    echo "--- Last 30 lines of $LOG_FILE ---"
    tail -n 30 "$LOG_FILE"
    exit 1
  fi
  sleep 2
  ELAPSED=$((ELAPSED + 2))
  if [ $((ELAPSED % 10)) -eq 0 ]; then
    echo "    ... waiting for collocated server (${ELAPSED}s / ${MAX_WAIT}s)"
  fi
done
echo "[✓] Collocated server ($PORT, TP=1) is ready! Logs: $LOG_FILE"
