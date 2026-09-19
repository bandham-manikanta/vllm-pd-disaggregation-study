#!/usr/bin/env bash
#
# capture_nsys_traces.sh - Automated 8-Trace Nsight Systems Profiling Suite
# Captures publication-grade hardware execution timelines across 8 key architectures.
#
set -euo pipefail

MODEL=${1:-"Qwen/Qwen3-8B"}
NODE1="a100-04"
NODE2="a100-02"
IP1="10.10.4.174"
IP2="10.10.4.172"

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VLLM_DIR="${VLLM_DIR:-/gpfs/projects/MaffeiGroup/open-source-contributions/vllm}"
VENV_DIR="${VENV_DIR:-/gpfs/projects/MaffeiGroup/venvs/vllm_venv}"
VLLM_BIN="${VENV_DIR}/bin/vllm"
OUT_DIR="${PROJECT_DIR}/results/traces"
LOG_DIR="${PROJECT_DIR}/logs"
TOY_PROXY="${VLLM_DIR}/tests/v1/kv_connector/nixl_integration/toy_proxy_server.py"
RR_PROXY="${PROJECT_DIR}/scripts/collocated_round_robin_proxy.py"

mkdir -p "${OUT_DIR}" "${LOG_DIR}"

echo "================================================================="
echo " Starting Automated 8-Trace Nsight Systems Profiling Suite"
echo " Model:   ${MODEL}"
echo " Output:  ${OUT_DIR}"
echo " Time:    $(date)"
echo "================================================================="

wait_health() {
  local url=$1
  local max_wait=${2:-300}
  local elapsed=0
  until curl -s -f "${url}" > /dev/null 2>&1; do
    if [ "$elapsed" -ge "$max_wait" ]; then
      echo "[!] TIMEOUT waiting for ${url}"
      return 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
    if [ $((elapsed % 10)) -eq 0 ]; then
      echo "    ... waiting for ${url} (${elapsed}s / ${max_wait}s)"
    fi
  done
  return 0
}

cleanup() {
  echo "[*] Tearing down services across cluster..."
  bash "${PROJECT_DIR}/scripts/stop_services.sh" "${NODE1}" "${NODE2}" > /dev/null 2>&1 || true
  sleep 3
}

# ==============================================================================
# TRACE 1: collocated_1x_tp2 under Injected Burst (Proves SM Contention)
# ==============================================================================
run_trace1() {
  echo ""
  echo "================================================================="
  echo " [1/8] TRACE 1: collocated_1x_tp2 under Burst (SM Contention)"
  echo "================================================================="
  local trace_out="${OUT_DIR}/trace1_collocated_1x_tp2_burst"
  if [ -f "${trace_out}.nsys-rep" ]; then
    echo "[✓] Trace file ${trace_out}.nsys-rep already exists. Skipping."
    return 0
  fi
  cleanup
  
  ssh "${NODE1}" "nohup nsys profile -c cudaProfilerApi --capture-range-end=stop -t cuda,nvtx,osrt --force-overwrite=true -o '${trace_out}' \
    bash -c '
      export PATH=\"${VENV_DIR}/bin:\$PATH\"
      CUDA_VISIBLE_DEVICES=0,1 \
      vllm serve \"${MODEL}\" \
        --host 0.0.0.0 --port 8000 \
        --tensor-parallel-size 2 \
        --gpu-memory-utilization 0.85 \
        --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
        >> \"${LOG_DIR}/trace1_server.log\" 2>&1
    ' > /dev/null 2>&1 &"
  
  wait_health "http://${IP1}:8000/health"
  echo "[✓] collocated_1x_tp2 server ready."
  
  # Trigger profiling
  echo "[*] Starting profiler and firing burst..."
  curl -s -X POST "http://${IP1}:8000/start_profile" > /dev/null 2>&1 || true
  
  # Fire prefill burst + decode stream
  "${VLLM_BIN}" bench serve --backend vllm --host "${IP1}" --port 8000 --endpoint /v1/completions --model "${MODEL}" \
    --dataset-name random --random-input-len 4096 --random-output-len 16 --num-prompts 4 --max-concurrency 4 > /dev/null 2>&1 &
  BURST_PID=$!
  sleep 0.5
  "${VLLM_BIN}" bench serve --backend vllm --host "${IP1}" --port 8000 --endpoint /v1/completions --model "${MODEL}" \
    --dataset-name random --random-input-len 256 --random-output-len 512 --num-prompts 4 --max-concurrency 2 > /dev/null 2>&1 || true
  wait "${BURST_PID}" 2>/dev/null || true
  
  curl -s -X POST "http://${IP1}:8000/stop_profile" > /dev/null 2>&1 || true
  echo "[✓] Profile range stopped. Finalizing trace..."
  sleep 5
  cleanup
  ls -lh "${trace_out}"* 2>/dev/null || true
}

# ==============================================================================
# TRACE 2: disagg_1p1d under Injected Burst (Proves P/D Decoupling)
# ==============================================================================
run_trace2() {
  echo ""
  echo "================================================================="
  echo " [2/8] TRACE 2: disagg_1p1d under Burst (P/D Decoupling)"
  echo "================================================================="
  local trace_out="${OUT_DIR}/trace2_disagg_1p1d_burst"
  if [ -f "${trace_out}.nsys-rep" ]; then
    echo "[✓] Trace file ${trace_out}.nsys-rep already exists. Skipping."
    return 0
  fi
  cleanup
  
  # Prefill on GPU 0
  ssh "${NODE1}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=0 \
    UCX_NET_DEVICES=all \
    VLLM_NIXL_SIDE_CHANNEL_PORT=5559 \
    vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8100 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 \
      --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
      --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_producer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
      >> \"${LOG_DIR}/trace2_prefill.log\" 2>&1
  ' > /dev/null 2>&1 &"

  # Decoder on GPU 1 wrapped with nsys
  ssh "${NODE1}" "nohup nsys profile -c cudaProfilerApi --capture-range-end=stop -t cuda,nvtx,osrt --force-overwrite=true -o '${trace_out}' \
    bash -c '
      export PATH=\"${VENV_DIR}/bin:\$PATH\"
      CUDA_VISIBLE_DEVICES=1 \
      UCX_NET_DEVICES=all \
      VLLM_NIXL_SIDE_CHANNEL_PORT=6000 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8200 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 \
        --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
        --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_consumer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
        >> \"${LOG_DIR}/trace2_decode.log\" 2>&1
    ' > /dev/null 2>&1 &"

  wait_health "http://${IP1}:8100/health"
  wait_health "http://${IP1}:8200/health"
  
  # Launch Proxy
  ssh "${NODE1}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    python3 \"${TOY_PROXY}\" --host 0.0.0.0 --port 8000 \
      --prefiller-hosts 127.0.0.1 --prefiller-ports 8100 \
      --decoder-hosts 127.0.0.1 --decoder-ports 8200 \
      >> \"${LOG_DIR}/trace2_proxy.log\" 2>&1
  ' > /dev/null 2>&1 &"
  
  wait_health "http://${IP1}:8000/healthcheck" 60
  echo "[✓] disagg_1p1d ready."
  
  curl -s -X POST "http://${IP1}:8100/start_profile" > /dev/null 2>&1 || true
  curl -s -X POST "http://${IP1}:8200/start_profile" > /dev/null 2>&1 || true
  
  "${VLLM_BIN}" bench serve --backend vllm --host "${IP1}" --port 8000 --endpoint /v1/completions --model "${MODEL}" \
    --dataset-name random --random-input-len 4096 --random-output-len 16 --num-prompts 4 --max-concurrency 4 > /dev/null 2>&1 &
  BURST_PID=$!
  sleep 0.5
  "${VLLM_BIN}" bench serve --backend vllm --host "${IP1}" --port 8000 --endpoint /v1/completions --model "${MODEL}" \
    --dataset-name random --random-input-len 256 --random-output-len 512 --num-prompts 4 --max-concurrency 2 > /dev/null 2>&1 || true
  wait "${BURST_PID}" 2>/dev/null || true

  curl -s -X POST "http://${IP1}:8100/stop_profile" > /dev/null 2>&1 || true
  curl -s -X POST "http://${IP1}:8200/stop_profile" > /dev/null 2>&1 || true
  echo "[✓] Profile range stopped. Finalizing trace..."
  sleep 5
  cleanup
  ls -lh "${trace_out}"* 2>/dev/null || true
}

# ==============================================================================
# TRACE 3: disagg_1p1d Context Sweep 8k (Raw NVLink Transfer)
# ==============================================================================
run_trace3() {
  echo ""
  echo "================================================================="
  echo " [3/8] TRACE 3: disagg_1p1d 8k Sweep (NVLink KV Transfer Timeline)"
  echo "================================================================="
  local trace_out="${OUT_DIR}/trace3_disagg_1p1d_nvlink_8k"
  if [ -f "${trace_out}.nsys-rep" ]; then
    echo "[✓] Trace file ${trace_out}.nsys-rep already exists. Skipping."
    return 0
  fi
  cleanup

  ssh "${NODE1}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=0 \
    UCX_NET_DEVICES=all \
    VLLM_NIXL_SIDE_CHANNEL_PORT=5559 \
    vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8100 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 \
      --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
      --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_producer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
      >> \"${LOG_DIR}/trace3_prefill.log\" 2>&1
  ' > /dev/null 2>&1 &"

  ssh "${NODE1}" "nohup nsys profile -c cudaProfilerApi --capture-range-end=stop -t cuda,nvtx,osrt --force-overwrite=true -o '${trace_out}' \
    bash -c '
      export PATH=\"${VENV_DIR}/bin:\$PATH\"
      CUDA_VISIBLE_DEVICES=1 \
      UCX_NET_DEVICES=all \
      VLLM_NIXL_SIDE_CHANNEL_PORT=6000 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8200 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 \
        --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
        --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_consumer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
        >> \"${LOG_DIR}/trace3_decode.log\" 2>&1
    ' > /dev/null 2>&1 &"

  wait_health "http://${IP1}:8100/health"
  wait_health "http://${IP1}:8200/health"
  
  ssh "${NODE1}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    python3 \"${TOY_PROXY}\" --host 0.0.0.0 --port 8000 \
      --prefiller-hosts 127.0.0.1 --prefiller-ports 8100 \
      --decoder-hosts 127.0.0.1 --decoder-ports 8200 \
      >> \"${LOG_DIR}/trace3_proxy.log\" 2>&1
  ' > /dev/null 2>&1 &"
  
  wait_health "http://${IP1}:8000/healthcheck" 60
  echo "[✓] disagg_1p1d ready."

  curl -s -X POST "http://${IP1}:8200/start_profile" > /dev/null 2>&1 || true
  "${VLLM_BIN}" bench serve --backend vllm --host "${IP1}" --port 8000 --endpoint /v1/completions --model "${MODEL}" \
    --dataset-name random --random-input-len 8192 --random-output-len 32 --num-prompts 2 --max-concurrency 1 > /dev/null 2>&1 || true
  curl -s -X POST "http://${IP1}:8200/stop_profile" > /dev/null 2>&1 || true
  echo "[✓] Profile range stopped. Finalizing trace..."
  sleep 5
  cleanup
  ls -lh "${trace_out}"* 2>/dev/null || true
}

# ==============================================================================
# TRACE 4: disagg_2p2d Context Sweep 8k (InfiniBand RDMA Transfer)
# ==============================================================================
run_trace4() {
  echo ""
  echo "================================================================="
  echo " [4/8] TRACE 4: disagg_2p2d 8k Sweep (100G InfiniBand RDMA Timeline)"
  echo "================================================================="
  local trace_out="${OUT_DIR}/trace4_disagg_2p2d_infiniband_8k"
  if [ -f "${trace_out}.nsys-rep" ]; then
    echo "[✓] Trace file ${trace_out}.nsys-rep already exists. Skipping."
    return 0
  fi
  cleanup

  # Prefill on a100-04 GPUs 0,1 (TP=2)
  ssh "${NODE1}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=0,1 \
    UCX_NET_DEVICES=mlx5_0:1 \
    VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP1}\" \
    VLLM_NIXL_SIDE_CHANNEL_PORT=5559 \
    vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8100 --tensor-parallel-size 2 --gpu-memory-utilization 0.85 \
      --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
      --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_producer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
      >> \"${LOG_DIR}/trace4_prefill.log\" 2>&1
  ' > /dev/null 2>&1 &"

  # Decoder on a100-02 GPUs 0,1 (TP=2) wrapped with nsys
  ssh "${NODE2}" "nohup nsys profile -c cudaProfilerApi --capture-range-end=stop -t cuda,nvtx,osrt --force-overwrite=true -o '${trace_out}' \
    bash -c '
      export PATH=\"${VENV_DIR}/bin:\$PATH\"
      CUDA_VISIBLE_DEVICES=0,1 \
      UCX_NET_DEVICES=mlx5_0:1 \
      VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP2}\" \
      VLLM_NIXL_SIDE_CHANNEL_PORT=6000 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8200 --tensor-parallel-size 2 --gpu-memory-utilization 0.85 \
        --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
        --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_consumer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
        >> \"${LOG_DIR}/trace4_decode.log\" 2>&1
    ' > /dev/null 2>&1 &"

  wait_health "http://${IP1}:8100/health"
  wait_health "http://${IP2}:8200/health"

  # Proxy on a100-04:8000
  ssh "${NODE2}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    python3 \"${TOY_PROXY}\" --host 0.0.0.0 --port 8000 \
      --prefiller-hosts \"${IP1}\" --prefiller-ports 8100 \
      --decoder-hosts \"${IP2}\" --decoder-ports 8200 \
      >> \"${LOG_DIR}/trace4_proxy.log\" 2>&1
  ' > /dev/null 2>&1 &"

  wait_health "http://${IP2}:8000/healthcheck" 60
  echo "[✓] disagg_2p2d ready."

  curl -s -X POST "http://${IP2}:8200/start_profile" > /dev/null 2>&1 || true
  "${VLLM_BIN}" bench serve --backend vllm --host "${IP2}" --port 8000 --endpoint /v1/completions --model "${MODEL}" \
    --dataset-name random --random-input-len 8192 --random-output-len 32 --num-prompts 2 --max-concurrency 1 > /dev/null 2>&1 || true
  curl -s -X POST "http://${IP2}:8200/stop_profile" > /dev/null 2>&1 || true
  echo "[✓] Profile range stopped. Finalizing trace..."
  sleep 5
  cleanup
  ls -lh "${trace_out}"* 2>/dev/null || true
}

# ==============================================================================
# TRACE 5: collocated_2x_tp2 Decode-Heavy (NCCL AllReduce Barrier Overhead)
# ==============================================================================
run_trace5() {
  echo ""
  echo "================================================================="
  echo " [5/8] TRACE 5: collocated_2x_tp2 Decode-Heavy (NCCL AllReduce Tax)"
  echo "================================================================="
  local trace_out="${OUT_DIR}/trace5_collocated_2x_tp2_allreduce"
  if [ -f "${trace_out}.nsys-rep" ]; then
    echo "[✓] Trace file ${trace_out}.nsys-rep already exists. Skipping."
    return 0
  fi
  cleanup

  # Engine 1 on a100-04 (TP=2)
  ssh "${NODE1}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=0,1 \
    vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8001 --tensor-parallel-size 2 --gpu-memory-utilization 0.85 \
      >> \"${LOG_DIR}/trace5_engine1.log\" 2>&1
  ' > /dev/null 2>&1 &"

  # Engine 2 on a100-02 (TP=2) wrapped with nsys
  ssh "${NODE2}" "nohup nsys profile -c cudaProfilerApi --capture-range-end=stop -t cuda,nvtx,osrt --force-overwrite=true -o '${trace_out}' \
    bash -c '
      export PATH=\"${VENV_DIR}/bin:\$PATH\"
      CUDA_VISIBLE_DEVICES=0,1 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8002 --tensor-parallel-size 2 --gpu-memory-utilization 0.85 \
        --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
        >> \"${LOG_DIR}/trace5_engine2.log\" 2>&1
    ' > /dev/null 2>&1 &"

  wait_health "http://${IP1}:8001/health"
  wait_health "http://${IP2}:8002/health"

  # Round-robin proxy on a100-04:8000
  ssh "${NODE2}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    python3 \"${RR_PROXY}\" --host 0.0.0.0 --port 8000 \
      --targets \"${IP1}:8001\" \"${IP2}:8002\" \
      >> \"${LOG_DIR}/trace5_proxy.log\" 2>&1
  ' > /dev/null 2>&1 &"

  wait_health "http://${IP2}:8000/health" 60
  echo "[✓] collocated_2x_tp2 ready."

  curl -s -X POST "http://${IP2}:8002/start_profile" > /dev/null 2>&1 || true
  "${VLLM_BIN}" bench serve --backend vllm --host "${IP2}" --port 8000 --endpoint /v1/completions --model "${MODEL}" \
    --dataset-name random --random-input-len 256 --random-output-len 512 --num-prompts 8 --max-concurrency 4 > /dev/null 2>&1 || true
  curl -s -X POST "http://${IP2}:8002/stop_profile" > /dev/null 2>&1 || true
  echo "[✓] Profile range stopped. Finalizing trace..."
  sleep 5
  cleanup
  ls -lh "${trace_out}"* 2>/dev/null || true
}

# ==============================================================================
# TRACE 6: collocated_4x_tp1 Decode-Heavy (Zero-NCCL Pure Compute Contrast)
# ==============================================================================
run_trace6() {
  echo ""
  echo "================================================================="
  echo " [6/8] TRACE 6: collocated_4x_tp1 Decode-Heavy (Zero-NCCL Streaming)"
  echo "================================================================="
  local trace_out="${OUT_DIR}/trace6_collocated_4x_tp1_noallreduce"
  if [ -f "${trace_out}.nsys-rep" ]; then
    echo "[✓] Trace file ${trace_out}.nsys-rep already exists. Skipping."
    return 0
  fi
  cleanup

  # Engines on a100-04 (GPUs 0, 1)
  ssh "${NODE1}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=0 vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8001 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 >> \"${LOG_DIR}/trace6_eng1.log\" 2>&1 &
    CUDA_VISIBLE_DEVICES=1 vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8002 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 >> \"${LOG_DIR}/trace6_eng2.log\" 2>&1 &
  ' > /dev/null 2>&1 &"

  # Engines on a100-02 (GPUs 0, 1 - Engine 3 wrapped with nsys)
  ssh "${NODE2}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=1 vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8004 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 >> \"${LOG_DIR}/trace6_eng4.log\" 2>&1 &
  ' > /dev/null 2>&1 &"

  ssh "${NODE2}" "nohup nsys profile -c cudaProfilerApi --capture-range-end=stop -t cuda,nvtx,osrt --force-overwrite=true -o '${trace_out}' \
    bash -c '
      export PATH=\"${VENV_DIR}/bin:\$PATH\"
      CUDA_VISIBLE_DEVICES=0 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8003 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 \
        --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
        >> \"${LOG_DIR}/trace6_eng3.log\" 2>&1
    ' > /dev/null 2>&1 &"

  wait_health "http://${IP1}:8001/health"
  wait_health "http://${IP1}:8002/health"
  wait_health "http://${IP2}:8003/health"
  wait_health "http://${IP2}:8004/health"

  ssh "${NODE2}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    python3 \"${RR_PROXY}\" --host 0.0.0.0 --port 8000 \
      --targets \"${IP1}:8001\" \"${IP1}:8002\" \"${IP2}:8003\" \"${IP2}:8004\" \
      >> \"${LOG_DIR}/trace6_proxy.log\" 2>&1
  ' > /dev/null 2>&1 &"

  wait_health "http://${IP2}:8000/health" 60
  echo "[✓] collocated_4x_tp1 ready."

  curl -s -X POST "http://${IP2}:8003/start_profile" > /dev/null 2>&1 || true
  "${VLLM_BIN}" bench serve --backend vllm --host "${IP2}" --port 8000 --endpoint /v1/completions --model "${MODEL}" \
    --dataset-name random --random-input-len 256 --random-output-len 512 --num-prompts 8 --max-concurrency 4 > /dev/null 2>&1 || true
  curl -s -X POST "http://${IP2}:8003/stop_profile" > /dev/null 2>&1 || true
  echo "[✓] Profile range stopped. Finalizing trace..."
  sleep 5
  cleanup
  ls -lh "${trace_out}"* 2>/dev/null || true
}

# ==============================================================================
# TRACE 7: disagg_2p2d under Burst (Cross-Node Network Burst Isolation)
# ==============================================================================
run_trace7() {
  echo ""
  echo "================================================================="
  echo " [7/8] TRACE 7: disagg_2p2d under Burst (InfiniBand SLA Isolation)"
  echo "================================================================="
  local trace_out="${OUT_DIR}/trace7_disagg_2p2d_burst"
  if [ -f "${trace_out}.nsys-rep" ]; then
    echo "[✓] Trace file ${trace_out}.nsys-rep already exists. Skipping."
    return 0
  fi
  cleanup

  ssh "${NODE1}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=0,1 \
    UCX_NET_DEVICES=mlx5_0:1 \
    VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP1}\" \
    VLLM_NIXL_SIDE_CHANNEL_PORT=5559 \
    vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8100 --tensor-parallel-size 2 --gpu-memory-utilization 0.85 \
      --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
      --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_producer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
      >> \"${LOG_DIR}/trace7_prefill.log\" 2>&1
  ' > /dev/null 2>&1 &"

  ssh "${NODE2}" "nohup nsys profile -c cudaProfilerApi --capture-range-end=stop -t cuda,nvtx,osrt --force-overwrite=true -o '${trace_out}' \
    bash -c '
      export PATH=\"${VENV_DIR}/bin:\$PATH\"
      CUDA_VISIBLE_DEVICES=0,1 \
      UCX_NET_DEVICES=mlx5_0:1 \
      VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP2}\" \
      VLLM_NIXL_SIDE_CHANNEL_PORT=6000 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8200 --tensor-parallel-size 2 --gpu-memory-utilization 0.85 \
        --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
        --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_consumer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
        >> \"${LOG_DIR}/trace7_decode.log\" 2>&1
    ' > /dev/null 2>&1 &"

  wait_health "http://${IP1}:8100/health"
  wait_health "http://${IP2}:8200/health"

  ssh "${NODE2}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    python3 \"${TOY_PROXY}\" --host 0.0.0.0 --port 8000 \
      --prefiller-hosts \"${IP1}\" --prefiller-ports 8100 \
      --decoder-hosts \"${IP2}\" --decoder-ports 8200 \
      >> \"${LOG_DIR}/trace7_proxy.log\" 2>&1
  ' > /dev/null 2>&1 &"

  wait_health "http://${IP2}:8000/healthcheck" 60
  echo "[✓] disagg_2p2d ready."

  curl -s -X POST "http://${IP2}:8200/start_profile" > /dev/null 2>&1 || true
  "${VLLM_BIN}" bench serve --backend vllm --host "${IP2}" --port 8000 --endpoint /v1/completions --model "${MODEL}" \
    --dataset-name random --random-input-len 4096 --random-output-len 16 --num-prompts 4 --max-concurrency 4 > /dev/null 2>&1 &
  BURST_PID=$!
  sleep 0.5
  "${VLLM_BIN}" bench serve --backend vllm --host "${IP2}" --port 8000 --endpoint /v1/completions --model "${MODEL}" \
    --dataset-name random --random-input-len 256 --random-output-len 512 --num-prompts 4 --max-concurrency 2 > /dev/null 2>&1 || true
  wait "${BURST_PID}" 2>/dev/null || true

  curl -s -X POST "http://${IP2}:8200/stop_profile" > /dev/null 2>&1 || true
  echo "[✓] Profile range stopped. Finalizing trace..."
  sleep 5
  cleanup
  ls -lh "${trace_out}"* 2>/dev/null || true
}

# ==============================================================================
# TRACE 8: disagg_1p3d Balanced (Asymmetric Dual-Fabric Fan-Out)
# ==============================================================================
run_trace8() {
  echo ""
  echo "================================================================="
  echo " [8/8] TRACE 8: disagg_1p3d Balanced (Asymmetric Dual-Fabric Fan-Out)"
  echo "================================================================="
  local trace_out="${OUT_DIR}/trace8_disagg_1p3d_asymmetric"
  if [ -f "${trace_out}.nsys-rep" ]; then
    echo "[✓] Trace file ${trace_out}.nsys-rep already exists. Skipping."
    return 0
  fi
  cleanup

  # Prefiller on a100-04 GPU 0 wrapped with nsys
  ssh "${NODE1}" "nohup nsys profile -c cudaProfilerApi --capture-range-end=stop -t cuda,nvtx,osrt --force-overwrite=true -o '${trace_out}' \
    bash -c '
      export PATH=\"${VENV_DIR}/bin:\$PATH\"
      CUDA_VISIBLE_DEVICES=0 \
      UCX_NET_DEVICES=mlx5_0:1 \
      VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP1}\" \
      VLLM_NIXL_SIDE_CHANNEL_PORT=5559 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8100 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 \
        --profiler-config \"{\\\"profiler\\\": \\\"cuda\\\"}\" \
        --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_producer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
        >> \"${LOG_DIR}/trace8_prefill.log\" 2>&1
    ' > /dev/null 2>&1 &"

  # Decoder 1 on a100-04 GPU 1 (NVLink)
  ssh "${NODE1}" "nohup bash -c '
      export PATH=\"${VENV_DIR}/bin:\$PATH\"
      CUDA_VISIBLE_DEVICES=1 \
      UCX_NET_DEVICES=mlx5_0:1 \
      VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP1}\" \
      VLLM_NIXL_SIDE_CHANNEL_PORT=6001 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8201 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 \
      --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_consumer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
      >> \"${LOG_DIR}/trace8_dec1.log\" 2>&1
  ' > /dev/null 2>&1 &"

  # Decoders 2 & 3 on a100-02 GPUs 0, 1 (InfiniBand)
  ssh "${NODE2}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    CUDA_VISIBLE_DEVICES=0 UCX_NET_DEVICES=mlx5_0:1 VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP2}\" VLLM_NIXL_SIDE_CHANNEL_PORT=6002 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8202 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 \
      --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_consumer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
      >> \"${LOG_DIR}/trace8_dec2.log\" 2>&1 &
    CUDA_VISIBLE_DEVICES=1 UCX_NET_DEVICES=mlx5_0:1 VLLM_NIXL_SIDE_CHANNEL_HOST=\"${IP2}\" VLLM_NIXL_SIDE_CHANNEL_PORT=6003 \
      vllm serve \"${MODEL}\" --host 0.0.0.0 --port 8203 --tensor-parallel-size 1 --gpu-memory-utilization 0.85 \
      --kv-transfer-config \"{\\\"kv_connector\\\": \\\"NixlConnector\\\", \\\"kv_role\\\": \\\"kv_consumer\\\", \\\"kv_buffer_device\\\": \\\"cuda\\\", \\\"kv_connector_extra_config\\\": {\\\"kv_lease_duration\\\": 300}}\" \
      >> \"${LOG_DIR}/trace8_dec3.log\" 2>&1 &
  ' > /dev/null 2>&1 &"

  wait_health "http://${IP1}:8100/health"
  wait_health "http://${IP1}:8201/health"
  wait_health "http://${IP2}:8202/health"
  wait_health "http://${IP2}:8203/health"

  ssh "${NODE2}" "nohup bash -c '
    export PATH=\"${VENV_DIR}/bin:\$PATH\"
    python3 \"${TOY_PROXY}\" --host 0.0.0.0 --port 8000 \
      --prefiller-hosts \"${IP1}\" --prefiller-ports 8100 \
      --decoder-hosts \"${IP1}\" \"${IP2}\" \"${IP2}\" --decoder-ports 8201 8202 8203 \
      >> \"${LOG_DIR}/trace8_proxy.log\" 2>&1
  ' > /dev/null 2>&1 &"

  wait_health "http://${IP2}:8000/healthcheck" 60
  echo "[✓] disagg_1p3d ready."

  curl -s -X POST "http://${IP1}:8100/start_profile" > /dev/null 2>&1 || true
  "${VLLM_BIN}" bench serve --backend vllm --host "${IP2}" --port 8000 --endpoint /v1/completions --model "${MODEL}" \
    --dataset-name random --random-input-len 1024 --random-output-len 512 --num-prompts 6 --max-concurrency 3 > /dev/null 2>&1 || true
  curl -s -X POST "http://${IP1}:8100/stop_profile" > /dev/null 2>&1 || true
  echo "[✓] Profile range stopped. Finalizing trace..."
  sleep 5
  cleanup
  ls -lh "${trace_out}"* 2>/dev/null || true
}

# Execute all 8 traces (skips already captured ones)
run_trace1
run_trace2
run_trace3
run_trace4
run_trace5
run_trace6
run_trace7
run_trace8

echo "================================================================="
echo " 8-TRACE NSIGHT PROFILING SUITE COMPLETE!"
echo " All traces saved in: ${OUT_DIR}"
echo "================================================================="
ls -lh "${OUT_DIR}"
