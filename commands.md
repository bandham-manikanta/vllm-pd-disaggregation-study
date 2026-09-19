# Experimental Execution Playbook: Bounded 4-GPU Matrix

This document lists the exact, copy-pasteable execution commands for running the entire benchmark study.

---

## 1. Hardware Topology (Bounded 4-GPU Architecture)

All experiments run strictly on **NUMA 0** on both nodes, guaranteeing that **every transfer is either NVLink 12 or 100G InfiniBand GPUDirect RDMA** (zero cross-NUMA / CPU motherboard PCIe stalls):

- **Node A (`a100-04` / `10.10.4.174`):** NVIDIA A100-80GB PCIe GPUs `0` & `1` (NVLink 12: ~150 GB/s, Mellanox CX-6 HDR 100G `mlx5_0`)
- **Node B (`a100-02` / `10.10.4.172`):** NVIDIA A100-80GB PCIe GPUs `0` & `1` (NVLink 12: ~150 GB/s, Mellanox CX-6 HDR 100G `mlx5_0`)
- **Cluster Filesystem:** `/gpfs/projects/MaffeiGroup/open-source-contributions/vllm-pd-disaggregation-study`
- **Virtual Environment:** `/gpfs/projects/MaffeiGroup/venvs/vllm_venv`
- **Target Model:** `Qwen/Qwen3-8B`

All launch scripts automatically clean up prior processes, bind to the correct GPUs and network devices, start the required vLLM instances and local proxy on port 8000, and wait until health checks return 200 OK.

---

## 2. Emergency Teardown Command

Run this at any time if you want to cleanly kill all vLLM processes and free GPU memory across both nodes:

```bash
bash scripts/stop_services.sh a100-04 a100-02
```

---

## 3. Tier 1: 2-GPU Experiments (Single Node & Cross-Node)

### Experiment 1: Collocated 2x TP=1 (`collocated_2x_tp1`)
- **Hardware:** `a100-04` GPU 0 and GPU 1 (2 independent data-parallel replicas)
- **Proxy:** Round-robin HTTP load balancer on port 8000

```bash
# 1. Launch services
bash scripts/launch_collocated_2x_tp1.sh Qwen/Qwen3-8B

# 2. Run benchmark suite
bash scripts/run_benchmarks.sh collocated_2x_tp1
```

---

### Experiment 2: Collocated 1x TP=2 (`collocated_1x_tp2`)
- **Hardware:** `a100-04` GPUs [0, 1] connected via NVLink 12 (Tensor Parallelism = 2)
- **Port:** 8000

```bash
# 1. Launch services
bash scripts/launch_collocated_1x_tp2.sh Qwen/Qwen3-8B

# 2. Run benchmark suite
bash scripts/run_benchmarks.sh collocated_1x_tp2
```

---

### Experiment 3: Disaggregated 1P:1D over NVLink 12 (`disagg_1p1d`)
- **Hardware:** `a100-04` GPU 0 (Prefill) $\to$ GPU 1 (Decode)
- **Interconnect:** **NVLink 12 (~150 GB/s)**
- **Proxy:** Port 8000

```bash
# 1. Launch services
bash scripts/launch_disagg_1p1d.sh Qwen/Qwen3-8B

# 2. Run benchmark suite
bash scripts/run_benchmarks.sh disagg_1p1d
```

---

### Experiment 4: Disaggregated 1P:1D over 100G InfiniBand (`disagg_1p1d_ib`)
- **Hardware:** `a100-04` GPU 0 (Prefill) $\to$ `a100-02` GPU 0 (Decode)
- **Interconnect:** **Mellanox HDR 100G InfiniBand (`mlx5_0:1`)**
- **Proxy:** Port 8000 on `a100-04`
- **Key Insight:** Comparing Exp 3 vs Exp 4 yields the exact KV transfer latency tax of NVLink vs. InfiniBand.

```bash
# 1. Launch services
bash scripts/launch_disagg_1p1d_ib.sh Qwen/Qwen3-8B

# 2. Run benchmark suite
bash scripts/run_benchmarks.sh disagg_1p1d_ib
```

---

## 4. Tier 2: 3-GPU Experiments (The Sweet-Spot Ratio)

### Experiment 5: Disaggregated 1P:2D over InfiniBand (`disagg_1p2d`)
- **Hardware:** `a100-04` GPU 0 (Prefill) $\to$ `a100-02` GPUs 0 & 1 (Decoders 1 & 2)
- **Interconnect:** **Mellanox HDR 100G InfiniBand (`mlx5_0:1`)**
- **Proxy:** Port 8000 on `a100-04`
- **Key Insight:** Validates the ideal $1\text{P}:2\text{D}$ asymmetric multiplexing ratio under mixed dialogue and RAG workloads.

```bash
# 1. Launch services
bash scripts/launch_disagg_1p2d.sh Qwen/Qwen3-8B

# 2. Run benchmark suite
bash scripts/run_benchmarks.sh disagg_1p2d
```

---

## 5. Tier 3: 4-GPU Experiments (Cluster Scale)

### Experiment 6: Collocated 4x TP=1 across Cluster (`collocated_4x_tp1`)
- **Hardware:** `a100-04` GPUs 0, 1 (Engines 1 & 2) + `a100-02` GPUs 0, 1 (Engines 3 & 4)
- **Proxy:** Central load balancer on `a100-04` Port 8000

```bash
# 1. Launch services
bash scripts/launch_collocated_4x_tp1.sh Qwen/Qwen3-8B

# 2. Run benchmark suite
bash scripts/run_benchmarks.sh collocated_4x_tp1
```

---

### Experiment 7: Collocated 2x TP=2 across Cluster (`collocated_2x_tp2`)
- **Hardware:** `a100-04` GPUs [0, 1] (TP=2) + `a100-02` GPUs [0, 1] (TP=2)
- **Interconnect:** In-node NVLink 12 within each TP=2 pair
- **Proxy:** Central load balancer on `a100-04` Port 8000

```bash
# 1. Launch services
bash scripts/launch_collocated_2x_tp2.sh Qwen/Qwen3-8B

# 2. Run benchmark suite
bash scripts/run_benchmarks.sh collocated_2x_tp2
```

---

### Experiment 8: Disaggregated 1P:3D Asymmetric Serving (`disagg_1p3d`)
- **Hardware:** 
  - `a100-04`: GPU 0 (Prefill), GPU 1 (Decoder 1)
  - `a100-02`: GPU 0 (Decoder 2), GPU 1 (Decoder 3)
- **Interconnect:** NVLink 12 (D1) + 100G InfiniBand (D2, D3)
- **Proxy:** Port 8000 on `a100-04`

```bash
# 1. Launch services
bash scripts/launch_disagg_1p3d.sh Qwen/Qwen3-8B

# 2. Run benchmark suite
bash scripts/run_benchmarks.sh disagg_1p3d
```

---

### Experiment 9: Disaggregated 2P:2D Symmetric Serving (`disagg_2p2d`)
- **Hardware:** 
  - `a100-04`: GPUs [0, 1] (Prefill TP=2)
  - `a100-02`: GPUs [0, 1] (Decode TP=2)
- **Interconnect:** **100G InfiniBand GPUDirect RDMA (`mlx5_0:1`)**
- **Proxy:** Port 8000 on `a100-04`

```bash
# 1. Launch services
bash scripts/launch_disagg_2p2d.sh Qwen/Qwen3-8B

# 2. Run benchmark suite
bash scripts/run_benchmarks.sh disagg_2p2d
```

---

## 6. Nsys Kernel Profiling & Micro-Benchmarks

To capture deep kernel execution traces, GEMM vs Attention rooflines, and KV transfer overlap:

```bash
# Profile NVLink 1P:1D KV transfer
bash scripts/capture_nsys_traces.sh disagg_1p1d

# Profile InfiniBand 1P:1D KV transfer
bash scripts/capture_nsys_traces.sh disagg_1p1d_ib

# Profile Collocated Head-of-Line prefill interference
bash scripts/capture_nsys_traces.sh collocated_2x_tp1
```

---

## 7. Results Parsing & Comparative Verification

### Step 1: Verify All Artifacts
Checks that all JSON benchmark files are complete with zero failed requests:
```bash
python3 scripts/verify_all_artifacts.py
```

### Step 2: Generate Comparative Markdown Analysis
```bash
# Compare Collocated 2-GPU vs Disaggregated NVLink
python3 scripts/parse_results.py \
  --collocated-dir results/collocated_2x_tp1 \
  --disagg-dir results/disagg_1p1d \
  --col-label "Collocated (2x TP1)" \
  --dis-label "Disaggregated (1P:1D NVLink)" \
  --output analysis_2gpu_nvlink.md

# Compare NVLink vs InfiniBand KV Transfer Tax
python3 scripts/parse_results.py \
  --collocated-dir results/disagg_1p1d \
  --disagg-dir results/disagg_1p1d_ib \
  --col-label "Disagg NVLink (1P:1D)" \
  --dis-label "Disagg InfiniBand (1P:1D)" \
  --output analysis_nvlink_vs_ib.md

# Compare 4-GPU Collocated vs 4-GPU Disaggregated
python3 scripts/parse_results.py \
  --collocated-dir results/collocated_4x_tp1 \
  --disagg-dir results/disagg_1p3d \
  --col-label "Collocated (4x TP1)" \
  --dis-label "Disaggregated (1P:3D)" \
  --output analysis_4gpu_disagg.md
```
