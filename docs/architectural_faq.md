# Systems Architecture FAQ & Design Deep-Dive

A comprehensive architectural reference addressing the critical systems engineering questions, trade-offs, and failure modes of **Prefill-Decode Disaggregation vs. Collocated Serving**.

---

## 1. Algorithmic Scheduling vs. Disaggregation: The Chunked Prefill Question

### *Q: "Why do P/D disaggregation when vLLM already supports Chunked Prefill?"*

**The Nuance:** Chunked prefill is an **engine scheduling policy**, not a model architecture property. It slices long prefill prompts into smaller chunks (e.g. 512 tokens) and co-schedules them alongside decode tokens in a single mixed forward pass.

While chunked prefill was optional in vLLM V0 (`--enable-chunked-prefill`), it is enabled by default in vLLM V1. **However, it introduces unavoidable hardware trade-offs:**

| Metric | Collocated with Chunked Prefill | Disaggregated P/D Serving |
| :--- | :--- | :--- |
| **SM Contention** | **High:** In every mixed batch, chunk GEMMs and decode attention compete for the same SM warps. | **Zero:** Prefill GEMMs run on GPU 0; decode attention runs on GPU 1. |
| **Decode Latency (TPOT)** | **Degrades by 20%–40%:** Token generation is slowed down across all 6 consecutive chunks of a 3,000-token prompt. | **Unperturbed:** Stays flat at the theoretical memory bandwidth ceiling. |
| **Time-to-First-Token (TTFT)** | **High / Delayed:** Evaluating a 3,000-token prompt across 6 separate forward passes prolongs prefill time. | **Minimal:** Evaluated in a single, high-throughput forward pass on the prefill engine. |
| **Pareto Optimality** | Sub-optimal compromise. | **Pareto Frontier:** Optimal TTFT and optimal TPOT simultaneously. |

---

## 2. Context Window & Sizing Decisions

### *Q: "Why benchmark up to 4K tokens instead of 32K or 64K?"*

In P/D Disaggregation, **context length directly dictates the KV-cache transfer payload size across the interconnect**:

$$\text{Transfer Payload} = 2 \times \text{layers} \times \text{heads} \times \text{head\_dim} \times \text{seq\_len} \times \text{dtype\_bytes}$$

For `Qwen3-8B` ($36\text{ layers}, 8\text{ heads}, \text{dim } 128, \text{BF16}$):
$$\text{Transfer Rate} = 144\text{ KB per token}$$

| Context Length | KV Payload | P2P NVLink Transfer Time ($27.35\text{ GB/s}$) | Prefill Compute Time (A100) | ROI Advantage |
| :--- | :--- | :--- | :--- | :--- |
| **512 tokens** | $73.7\text{ MB}$ | **$2.69\text{ ms}$** | $\approx 15\text{ ms}$ | **$5.6\times$ faster** than recompute |
| **1,024 tokens** | $147.5\text{ MB}$ | **$5.39\text{ ms}$** | $\approx 25\text{ ms}$ | **$4.6\times$ faster** than recompute |
| **3,000 tokens** | **$432.4\text{ MB}$** | **$15.81\text{ ms}$** | $\approx 55\text{ ms}$ | **$3.5\times$ faster** than recompute |
| **4,096 tokens** | $589.8\text{ MB}$ | **$21.57\text{ ms}$** | $\approx 75\text{ ms}$ | **$3.5\times$ faster** than recompute |
| **16,384 tokens** | $2.36\text{ GB}$ | **$86.3\text{ ms}$** | $\approx 220\text{ ms}$ | **$2.5\times$ faster** than recompute |
| **32,768 tokens** | $4.72\text{ GB}$ | **$172.5\text{ ms}$** | $\approx 400\text{ ms}$ | Interconnect transfer time starts approaching compute time. |

**Defense:** Benchmarking up to 4K/8K tokens isolates the primary operational regime of production chatbots and agent tool loops where P/D disaggregation achieves its maximum latency reduction.

---

## 3. Production Provisioning Economics

### *Q: "Is a 1 Prefill : 1 Decode (1P:1D) GPU ratio realistic in production?"*

**No.** A 1:1 ratio is used here strictly as a minimal 2-GPU laboratory testbed to isolate micro-architectural transfer latency and interference.

In real-world LLM inference:
- **Prefill duration:** Tens of milliseconds (compute-saturated).
- **Decode duration:** Tens of seconds (generating 500–1000 tokens at ~40 tokens/s).
- **Optimal Production Ratio:** Because decode takes orders of magnitude longer than prefill, a single Prefill instance can feed **$8$ to $32$ Decode instances** ($1\text{P} : 8\text{D}$ or $1\text{P} : 16\text{D}$ pool).
- Running 1:1 in production would leave the Prefill GPU idle for ~90% of the time. In production architectures (e.g. Mooncake, DistServe), prefillers are centralized into a small, high-utilization pool.

---

## 4. Interconnect Requirements & Multi-Node Scaling

### *Q: "Can this work across distributed nodes over standard Cloud Ethernet?"*

**No. P/D disaggregation is strictly interconnect-bound:**
- **Over NVLink ($27 - 300\text{ GB/s}$):** P2P DMA takes $<20\text{ ms}$ for 3,000 tokens. Transfer tax is negligible.
- **Over InfiniBand / RoCE with GPUDirect RDMA ($50\text{ GB/s}$ via 400Gbps):** Transfer takes $\approx 10-15\text{ ms}$. Highly viable for multi-node.
- **Over Standard 10Gbps Cloud Ethernet ($1.25\text{ GB/s}$):** Transferring a 432 MB KV cache takes **$3.5\text{ seconds}$**! Disaggregation completely fails, and collocated chunked prefill is strictly superior.

---

## 5. Fault Tolerance & Failure Modes

### *Q: "What happens if a Prefill GPU crashes mid-transfer?"*

1. **Failure Signature:** The decode engine has already allocated PagedAttention blocks waiting for the NIXL RDMA transfer signal. If the prefiller crashes, the transfer never signals completion.
2. **Mitigation Strategy:**
   - **Heartbeat & Transfer Timeouts:** The proxy enforces a strict timeout on the prefiller sidechannel (e.g. 50ms).
   - **Local Recompute Fallback:** If the NIXL transfer times out, the decode engine falls back to evaluating the prompt locally on the decoder GPU.
