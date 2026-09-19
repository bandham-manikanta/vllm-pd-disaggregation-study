# Low-Level Systems Profiling & Analysis Guide

A systems-level technical guide for analyzing the hardware mechanics of **Collocated Serving vs. Prefill-Decode Disaggregation** on NVIDIA A100 GPUs.

---

## 1. First-Principles KV-Cache Tensor Math

In Transformer architectures (e.g. `Qwen/Qwen3-8B`), each token generates Key and Value activation vectors across all attention layers:

$$\text{Bytes per Token} = 2 \times L \times H_{\text{kv}} \times D_{\text{head}} \times B_{\text{dtype}}$$

Where:
- $L = 36$ (Transformer layers)
- $H_{\text{kv}} = 8$ (Grouped-Query Attention KV heads)
- $D_{\text{head}} = 128$ (Head dimension)
- $B_{\text{dtype}} = 2$ bytes (FP16 / BF16)

### Calculation:
$$\text{Bytes per Token} = 2 \times 36 \times 8 \times 128 \times 2 = 147,456\text{ bytes} \approx \mathbf{144\text{ KB / token}}$$

### Burst Payload Scaling:
| Prompt Tokens | Uncompressed KV Size | P2P NVLink Transfer Time ($27.35\text{ GB/s}$) |
| :--- | :--- | :--- |
| **512 tokens** | $73.7\text{ MB}$ | **$2.69\text{ ms}$** |
| **1,024 tokens** | $147.5\text{ MB}$ | **$5.39\text{ ms}$** |
| **3,000 tokens (Burst)** | **$432.4\text{ MB}$** | **$15.81\text{ ms}$** |
| **4,096 tokens** | $589.8\text{ MB}$ | **$21.57\text{ ms}$** |
| **8,192 tokens** | $1,179.6\text{ MB}$ ($1.18\text{ GB}$) | **$43.13\text{ ms}$** |

---

## 2. Hardware-Level Root Cause Analysis

### A. The Collocated Bottleneck: Compute vs. Memory Bandwidth Starvation
1. **Arithmetic Intensity Disparity:**
   - **Prefill:** Compute-bound. Arithmetic intensity is high ($\mathcal{O}(\text{seq\_len})$ ops per byte loaded). Tensor Cores run at near-peak FLOPs.
   - **Decode:** Memory-bandwidth-bound. Arithmetic intensity is low ($\approx 1$ op per byte loaded from HBM3). Every token requires reading the entire model weights and KV history from memory.
2. **Interference Mechanism:**
   When a 3,000-token prefill prompt arrives while 4 decode streams are active:
   - The vLLM scheduler creates a batch prioritizing the large prefill to keep SMs saturated.
   - The prefill GEMMs monopolize the SM execution units and consume high HBM bus bandwidth.
   - The decode streams are starved of memory read slots and SM warps.
   - **Result:** Inter-Token Latency (ITL) spikes from $\approx 20\text{ ms}$ to $300 - 800\text{ ms}$ (Head-of-Line blocking).

---

### B. Disaggregated P/D Mechanics (NIXL over NVLink)
1. **Physical Decoupling:**
   - **GPU 0 (Prefill Engine):** Executes only compute-bound prefill GEMMs. It never performs memory-bound autoregressive decoding.
   - **GPU 1 (Decode Engine):** Executes only autoregressive decoding. It never gets blocked by prefill compute.
2. **Zero Compute Contention:**
   - The 3,000-token prompt is processed entirely on GPU 0.
   - The resulting $432\text{ MB}$ KV tensor is transferred to GPU 1 via **NIXL (NVIDIA Inference Transfer Layer)** using asynchronous peer-to-peer DMA (`cudaMemcpyPeerAsync`) over the $27.35\text{ GB/s}$ NVLink bridge in **$15.8\text{ ms}$**.
   - GPU 1 simply links the received memory descriptors into its PagedAttention block table.
   - **Result:** Ongoing decode iterations on GPU 1 never stall, and ITL stays flat at $\approx 20 - 25\text{ ms}$.

---

## 3. The "Transfer Tax" vs. "Recomputation" Tradeoff

When evaluating disaggregation, the fundamental architectural tradeoff is:

$$\text{Latency}_{\text{Disagg}} = \text{Time}_{\text{Prefill}}(\text{GPU 0}) + \text{Time}_{\text{NIXL Transfer}}(\text{NVLink}) + \text{Time}_{\text{Decode Step}}(\text{GPU 1})$$

$$\text{Latency}_{\text{Collocated}} = \text{Time}_{\text{Prefill}}(\text{GPU 0,1}) + \text{Time}_{\text{Interference Delay}} + \text{Time}_{\text{Decode Step}}(\text{GPU 0,1})$$

Since the NIXL transfer time over NVLink is only **$15.8\text{ ms}$ for 3,000 tokens** (compared to hundreds of milliseconds of compute delay in a collocated queue), disaggregation provides strict tail-SLA guarantees with near-zero transfer tax.
