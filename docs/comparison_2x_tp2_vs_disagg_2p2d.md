# Empirical Systems Report: Collocated (2x TP2) vs. Disaggregated (2P:2D)

- **Collocated Dataset:** `results/collocated_2x_tp2`
- **Disaggregated Dataset:** `results/disagg_2p2d`

## 1. Decode-Heavy Workload ($256\text{ in} \times 1024\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP2) | 131.6 | 23.2 | 25.8 | 7.58 | 7.58 | 7.70 |
| **C=1** | Disaggregated (2P:2D) | 130.4 | 67.3 | 74.3 | 7.61 | 7.61 | 7.70 |
| **C=4** | Collocated (2x TP2) | 527.3 | 30.3 | 47.4 | 7.56 | 7.56 | 7.72 |
| **C=4** | Disaggregated (2P:2D) | 507.7 | 78.4 | 101.2 | 7.81 | 7.81 | 8.09 |
| **C=16** | Collocated (2x TP2) | 1999.9 | 59.6 | 112.2 | 7.94 | 7.94 | 8.48 |
| **C=16** | Disaggregated (2P:2D) | 1856.7 | 143.2 | 318.7 | 8.44 | 8.44 | 9.50 |
| **C=32** | Collocated (2x TP2) | 3685.5 | 132.7 | 456.9 | 8.51 | 8.51 | 9.64 |
| **C=32** | Disaggregated (2P:2D) | 3266.7 | 259.0 | 732.8 | 9.41 | 9.41 | 10.79 |
| **C=64** | Collocated (2x TP2) | 6536.5 | 242.6 | 475.0 | 9.48 | 9.48 | 11.90 |
| **C=64** | Disaggregated (2P:2D) | 5206.3 | 583.6 | 1189.4 | 11.42 | 11.42 | 14.89 |

## 2. Balanced Dialogue Workload ($1024\text{ in} \times 512\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP2) | 130.3 | 44.8 | 53.1 | 7.60 | 7.60 | 7.84 |
| **C=1** | Disaggregated (2P:2D) | 126.8 | 144.5 | 158.9 | 7.62 | 7.62 | 7.71 |
| **C=4** | Collocated (2x TP2) | 514.3 | 58.8 | 92.9 | 7.67 | 7.67 | 7.86 |
| **C=4** | Disaggregated (2P:2D) | 491.9 | 115.1 | 307.5 | 7.90 | 7.90 | 8.13 |
| **C=16** | Collocated (2x TP2) | 1861.1 | 143.0 | 531.6 | 8.25 | 8.25 | 8.70 |
| **C=16** | Disaggregated (2P:2D) | 1667.4 | 258.4 | 1155.9 | 8.83 | 8.83 | 9.98 |
| **C=32** | Collocated (2x TP2) | 3326.5 | 219.7 | 542.9 | 9.17 | 9.17 | 10.10 |
| **C=32** | Disaggregated (2P:2D) | 2687.3 | 545.5 | 2320.3 | 10.12 | 10.12 | 11.84 |

## 3. Enterprise RAG Workload ($8192\text{ in} \times 128\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP2) | 88.8 | 426.9 | 433.5 | 7.99 | 7.99 | 8.41 |
| **C=1** | Disaggregated (2P:2D) | 57.7 | 1201.4 | 1227.1 | 7.99 | 7.99 | 8.19 |
| **C=4** | Collocated (2x TP2) | 342.2 | 300.9 | 820.2 | 9.36 | 9.36 | 79.79 |
| **C=4** | Disaggregated (2P:2D) | 243.9 | 871.1 | 4409.9 | 8.90 | 8.90 | 13.23 |
| **C=8** | Collocated (2x TP2) | 559.1 | 341.8 | 908.9 | 11.33 | 11.33 | 111.84 |
| **C=8** | Disaggregated (2P:2D) | 651.8 | 178.9 | 377.2 | 10.79 | 10.79 | 16.52 |
| **C=16** | Collocated (2x TP2) | 741.8 | 580.5 | 2051.5 | 16.56 | 16.62 | 122.53 |
| **C=16** | Disaggregated (2P:2D) | 398.5 | 2041.9 | 12726.8 | 12.53 | 12.53 | 20.23 |

## 4. Sustained Injected Burst Shockwave SLA Isolation

| Architecture | Burst Clearance Time (s) | Burst Mean TTFT (ms) | Burst P99 TTFT (ms) | Burst Throughput (tok/s) | Decode P99 ITL Under Burst (ms) |
| --- | --- | --- | --- | --- | --- |
| Collocated (2x TP2) | 3.84 s | 148.9 ms | 869.7 ms | 102673.7 tok/s | **20.11 ms** |
| Disaggregated (2P:2D) | **3.53 s** | **155.3 ms** | **241.1 ms** | **111530.6 tok/s** | **14.52 ms** |

## 5. Low-Level Systems: NIXL KV-Transfer Bandwidth vs. Silicon Limits

Evaluates physical bus utilization across context lengths ($144.0\text{ KiB/token}$) against **NVLink 12** ceiling ($150.0\text{ GB/s}$):

| Context Length | KV Cache Size (MB) | Collocated TTFT (ms) | Disagg TTFT (ms) | KV Transfer Tax (ms) | Effective NIXL Bandwidth (GB/s) | % of Bus Limit |
| --- | --- | --- | --- | --- | --- | --- |
| 512 tokens | 72.0 MB | 17.5 ms | 61.8 ms | 44.3 ms | **1.70 GB/s** | 1.1% NVLink 12 |
| 1024 tokens | 144.0 MB | 20.3 ms | 68.2 ms | 47.8 ms | **3.16 GB/s** | 2.1% NVLink 12 |
| 2048 tokens | 288.0 MB | 27.7 ms | 76.8 ms | 49.1 ms | **6.15 GB/s** | 4.1% NVLink 12 |
| 4096 tokens | 576.0 MB | 35.1 ms | 97.2 ms | 62.1 ms | **9.72 GB/s** | 6.5% NVLink 12 |
| 8192 tokens | 1152.0 MB | 75.7 ms | 135.4 ms | 59.7 ms | **20.24 GB/s** | 13.5% NVLink 12 |
| 16384 tokens | 2304.0 MB | 636.2 ms | 1761.4 ms | 1125.2 ms | **2.15 GB/s** | 1.4% NVLink 12 |

## 6. Calibrated Poisson Open-Loop SLA Capacity Sweeps

| Workload | Target Rate (req/s) | Architecture | Realized Out Tok/s | Mean TTFT (ms) | P99 TTFT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| balanced_1024x512 | 2 | Collocated (2x TP2) | 908.1 | 30.9 | 48.7 | 7.90 | 8.70 |
| balanced_1024x512 | 2 | Disaggregated (2P:2D) | 901.1 | 74.8 | 87.5 | 8.32 | 9.50 |
| balanced_1024x512 | 4 | Collocated (2x TP2) | 1620.1 | 32.7 | 39.4 | 8.20 | 10.08 |
| balanced_1024x512 | 4 | Disaggregated (2P:2D) | 1587.2 | 79.8 | 90.0 | 8.99 | 10.66 |
| balanced_1024x512 | 8 | Collocated (2x TP2) | 2629.0 | 36.2 | 48.4 | 8.79 | 11.56 |
| balanced_1024x512 | 8 | Disaggregated (2P:2D) | 2481.8 | 88.3 | 105.0 | 10.19 | 12.49 |
| balanced_1024x512 | 12 | Collocated (2x TP2) | 3278.0 | 38.9 | 54.0 | 9.19 | 13.33 |
| balanced_1024x512 | 12 | Disaggregated (2P:2D) | 2990.1 | 92.5 | 115.7 | 11.00 | 14.22 |
| balanced_1024x512 | 16 | Collocated (2x TP2) | 3718.2 | 40.3 | 71.0 | 9.48 | 14.22 |
| balanced_1024x512 | 16 | Disaggregated (2P:2D) | 3291.4 | 95.8 | 138.3 | 11.56 | 14.90 |
| enterprise_rag_8192x128 | 1.1 | Collocated (2x TP2) | 137.6 | 146.4 | 535.0 | 8.56 | 9.46 |
| enterprise_rag_8192x128 | 1.1 | Disaggregated (2P:2D) | 137.9 | 135.2 | 157.4 | 8.47 | 11.23 |
| enterprise_rag_8192x128 | 2.2 | Collocated (2x TP2) | 267.2 | 85.4 | 477.8 | 8.76 | 11.38 |
| enterprise_rag_8192x128 | 2.2 | Disaggregated (2P:2D) | 269.1 | 143.7 | 168.1 | 9.18 | 15.24 |
| enterprise_rag_8192x128 | 3.1 | Collocated (2x TP2) | 374.5 | 69.7 | 229.8 | 8.76 | 19.66 |
| enterprise_rag_8192x128 | 3.1 | Disaggregated (2P:2D) | 371.0 | 148.6 | 174.7 | 9.74 | 15.94 |
| enterprise_rag_8192x128 | 3.8 | Collocated (2x TP2) | 451.7 | 86.2 | 476.1 | 9.16 | 20.11 |
| enterprise_rag_8192x128 | 3.8 | Disaggregated (2P:2D) | 446.0 | 151.2 | 180.7 | 10.15 | 16.73 |
| enterprise_rag_8192x128 | 4.3 | Collocated (2x TP2) | 508.7 | 63.2 | 78.0 | 8.97 | 20.13 |
| enterprise_rag_8192x128 | 4.3 | Disaggregated (2P:2D) | 497.9 | 153.0 | 184.5 | 10.49 | 16.81 |
