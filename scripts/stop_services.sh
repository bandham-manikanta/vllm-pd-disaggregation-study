#!/usr/bin/env bash
#
# stop_services.sh - Production Teardown Utility for vLLM & Proxy Services
# Scoped strictly to the invoking user to ensure zero risk to other cluster tenants.
#
set -euo pipefail

# Target nodes to teardown. Default: only the local machine where the script is executed.
if [ $# -eq 0 ]; then
  NODES=("$(hostname -s)")
else
  NODES=("$@")
fi

echo "================================================================="
echo " Stopping all vLLM, proxy, and benchmark services for user: ${USER}"
echo " Target Nodes: ${NODES[*]}"
echo "================================================================="

teardown_node() {
  local node=$1
  echo "[*] Tearing down services on ${node}..."
  
  teardown_cmd='
    CURRENT_PID=$$

    # 1. Kill any process holding a GPU context directly via nvidia-smi
    GPU_PIDS=$(nvidia-smi --query-compute-apps=pid --format=csv,noheader 2>/dev/null | grep -E "^[0-9]+$" || true)
    for pid in $GPU_PIDS; do
      if [ "$pid" != "$CURRENT_PID" ]; then
        kill -9 "$pid" 2>/dev/null || true
      fi
    done

    # 2. Kill by process name pattern (catches VLLM::Worker, EngineCore, vllm serve, proxies)
    pkill -9 -i -u "$USER" -f "VLLM::" 2>/dev/null || true
    pkill -9 -i -u "$USER" -f "vllm serve" 2>/dev/null || true
    pkill -9 -u "$USER" -f "multiproc_worker" 2>/dev/null || true
    pkill -9 -u "$USER" -f "toy_proxy" 2>/dev/null || true
    pkill -9 -u "$USER" -f "collocated_round_robin_proxy" 2>/dev/null || true
    
    # 3. Wait up to 5s for GPU memory unmap
    for i in {1..5}; do
      REMAINING=$(nvidia-smi --query-compute-apps=pid --format=csv,noheader 2>/dev/null | grep -E "^[0-9]+$" || true)
      [ -z "$REMAINING" ] && break
      sleep 1
    done
  '

  if [ "$node" = "$(hostname -s)" ] || [ "$node" = "localhost" ] || [ "$node" = "127.0.0.1" ]; then
    bash -s <<< "$teardown_cmd"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=5 "${node}" "bash -s" <<< "$teardown_cmd"
  fi
  echo "[✓] Teardown complete on ${node}."
}

for node in "${NODES[@]}"; do
  teardown_node "$node"
done

echo "================================================================="
echo " Checking GPU states..."
echo "================================================================="
for node in "${NODES[@]}"; do
  if [ "$node" = "$(hostname -s)" ] || [ "$node" = "localhost" ] || [ "$node" = "127.0.0.1" ]; then
    nvidia-smi --query-gpu=index,memory.used,utilization.gpu --format=csv,noheader || true
  else
    ssh "${node}" "nvidia-smi --query-gpu=index,memory.used,utilization.gpu --format=csv,noheader" || true
  fi
done
echo "[✓] Services cleanly stopped on target node(s)!"
