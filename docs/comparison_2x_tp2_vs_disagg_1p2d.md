# Benchmark Report: Collocated (2x TP2) vs. Disaggregated (P:2D)

- **Collocated Dataset:** `results/collocated_2x_tp2`
- **Disaggregated Dataset:** `results/disagg_1p2d`

## 1. Decode-Heavy Workload ($256\text{ in} \times 1024\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP2) | 131.6 | 23.2 | 25.8 | 7.58 | 7.58 | 7.70 |
| **C=1** | Disaggregated (P:2D) | 85.2 | 100.7 | 110.6 | 11.65 | 11.65 | 11.83 |
| **C=4** | Collocated (2x TP2) | 527.3 | 30.3 | 47.4 | 7.56 | 7.56 | 7.72 |
| **C=4** | Disaggregated (P:2D) | 337.7 | 113.5 | 195.4 | 11.73 | 11.73 | 11.94 |
| **C=16** | Collocated (2x TP2) | 1999.9 | 59.6 | 112.2 | 7.94 | 7.94 | 8.48 |
| **C=16** | Disaggregated (P:2D) | 1273.2 | 210.8 | 544.0 | 12.27 | 12.27 | 12.99 |
| **C=32** | Collocated (2x TP2) | 3685.5 | 132.7 | 456.9 | 8.51 | 8.51 | 9.64 |
| **C=32** | Disaggregated (P:2D) | 2298.8 | 553.8 | 1255.7 | 13.09 | 13.09 | 14.39 |
| **C=64** | Collocated (2x TP2) | 6536.5 | 242.6 | 475.0 | 9.48 | 9.48 | 11.90 |
| **C=64** | Disaggregated (P:2D) | 3886.9 | 752.7 | 1457.4 | 15.03 | 15.03 | 17.88 |

## 2. Balanced Dialogue Workload ($1024\text{ in} \times 512\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP2) | 130.3 | 44.8 | 53.1 | 7.60 | 7.60 | 7.84 |
| **C=1** | Disaggregated (P:2D) | 81.9 | 246.1 | 270.7 | 11.75 | 11.75 | 11.89 |
| **C=4** | Collocated (2x TP2) | 514.3 | 58.8 | 92.9 | 7.67 | 7.67 | 7.86 |
| **C=4** | Disaggregated (P:2D) | 326.0 | 204.4 | 515.1 | 11.83 | 11.83 | 12.05 |
| **C=16** | Collocated (2x TP2) | 1861.1 | 143.0 | 531.6 | 8.25 | 8.25 | 8.70 |
| **C=16** | Disaggregated (P:2D) | 1133.6 | 484.9 | 1508.1 | 12.64 | 12.64 | 13.65 |
| **C=32** | Collocated (2x TP2) | 3326.5 | 219.7 | 542.9 | 9.17 | 9.17 | 10.10 |
| **C=32** | Disaggregated (P:2D) | 1832.7 | 1118.9 | 3446.9 | 13.66 | 13.66 | 15.13 |

## 3. Enterprise RAG Workload ($8192\text{ in} \times 128\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP2) | 88.8 | 426.9 | 433.5 | 7.99 | 7.99 | 8.41 |
| **C=1** | Disaggregated (P:2D) | 33.5 | 2249.7 | 2303.4 | 12.39 | 12.39 | 12.62 |
| **C=4** | Collocated (2x TP2) | 342.2 | 300.9 | 820.2 | 9.36 | 9.36 | 79.79 |
| **C=4** | Disaggregated (P:2D) | 143.6 | 1790.1 | 7165.1 | 12.89 | 12.89 | 14.13 |
| **C=8** | Collocated (2x TP2) | 559.1 | 341.8 | 908.9 | 11.33 | 11.33 | 111.84 |
| **C=8** | Disaggregated (P:2D) | 175.7 | 3802.6 | 5842.7 | 12.71 | 12.71 | 15.11 |
| **C=16** | Collocated (2x TP2) | 741.8 | 580.5 | 2051.5 | 16.56 | 16.62 | 122.53 |
| **C=16** | Disaggregated (P:2D) | 135.7 | 10719.0 | 25116.5 | 12.72 | 12.72 | 15.02 |

## 4. Sustained Injected Burst Shockwave SLA Isolation

| Architecture | Burst Clearance Time (s) | Burst Mean TTFT (ms) | Burst P99 TTFT (ms) | Burst Throughput (tok/s) | Decode P99 ITL Under Burst (ms) |
| --- | --- | --- | --- | --- | --- |
| Collocated (2x TP2) | 3.84 s | 148.9 ms | 869.7 ms | 102673.7 tok/s | **20.11 ms** |
| Disaggregated (P:2D) | **34.22 s** | **2581.6 ms** | **2850.7 ms** | **11512.9 tok/s** | **13.78 ms** |

## 5. Low-Level Systems: NIXL KV-Transfer Bandwidth vs. Silicon Limits

Evaluates physical bus utilization across context lengths ($144.0\text{ KiB/token}$) against **NVLink 12** ceiling ($150.0\text{ GB/s}$):

| Context Length | KV Cache Size (MB) | Collocated TTFT (ms) | Disagg TTFT (ms) | KV Transfer Tax (ms) | Effective NIXL Bandwidth (GB/s) | % of Bus Limit |
| --- | --- | --- | --- | --- | --- | --- |
| 512 tokens | 72.0 MB | 17.5 ms | 58.9 ms | 41.4 ms | **1.82 GB/s** | 1.2% NVLink 12 |
| 1024 tokens | 144.0 MB | 20.3 ms | 64.9 ms | 44.6 ms | **3.39 GB/s** | 2.3% NVLink 12 |
| 2048 tokens | 288.0 MB | 27.7 ms | 81.7 ms | 54.0 ms | **5.59 GB/s** | 3.7% NVLink 12 |
| 4096 tokens | 576.0 MB | 35.1 ms | 182.4 ms | 147.3 ms | **4.10 GB/s** | 2.7% NVLink 12 |
| 8192 tokens | 1152.0 MB | 75.7 ms | 570.1 ms | 494.4 ms | **2.44 GB/s** | 1.6% NVLink 12 |
| 16384 tokens | 2304.0 MB | 636.2 ms | 4004.7 ms | 3368.5 ms | **0.72 GB/s** | 0.5% NVLink 12 |

## 6. Calibrated Poisson Open-Loop SLA Capacity Sweeps

| Workload | Target Rate (req/s) | Architecture | Realized Out Tok/s | Mean TTFT (ms) | P99 TTFT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| balanced_1024x512 | 2 | Collocated (2x TP2) | 908.1 | 30.9 | 48.7 | 7.90 | 8.70 |
| balanced_1024x512 | 2 | Disaggregated (P:2D) | 851.3 | 124.4 | 263.9 | 12.49 | 13.75 |
| balanced_1024x512 | 4 | Collocated (2x TP2) | 1620.1 | 32.7 | 39.4 | 8.20 | 10.08 |
| balanced_1024x512 | 4 | Disaggregated (P:2D) | 1431.3 | 103.9 | 117.8 | 13.35 | 15.20 |
| balanced_1024x512 | 8 | Collocated (2x TP2) | 2629.0 | 36.2 | 48.4 | 8.79 | 11.56 |
| balanced_1024x512 | 8 | Disaggregated (P:2D) | 2112.7 | 109.9 | 131.7 | 14.60 | 17.12 |
| balanced_1024x512 | 12 | Collocated (2x TP2) | 3278.0 | 38.9 | 54.0 | 9.19 | 13.33 |
| balanced_1024x512 | 12 | Disaggregated (P:2D) | 2455.9 | 126.0 | 562.8 | 15.48 | 18.13 |
| balanced_1024x512 | 16 | Collocated (2x TP2) | 3718.2 | 40.3 | 71.0 | 9.48 | 14.22 |
| balanced_1024x512 | 16 | Disaggregated (P:2D) | 2671.4 | 113.5 | 154.9 | 15.94 | 19.06 |
| enterprise_rag_8192x128 | 1.1 | Collocated (2x TP2) | 137.6 | 146.4 | 535.0 | 8.56 | 9.46 |
| enterprise_rag_8192x128 | 1.1 | Disaggregated (P:2D) | 127.1 | 1282.4 | 4473.2 | 12.56 | 14.26 |
| enterprise_rag_8192x128 | 2.2 | Collocated (2x TP2) | 267.2 | 85.4 | 477.8 | 8.76 | 11.38 |
| enterprise_rag_8192x128 | 2.2 | Disaggregated (P:2D) | 172.5 | 6818.6 | 16380.6 | 12.63 | 14.68 |
| enterprise_rag_8192x128 | 3.1 | Collocated (2x TP2) | 374.5 | 69.7 | 229.8 | 8.76 | 19.66 |
| enterprise_rag_8192x128 | 3.1 | Disaggregated (P:2D) | 173.8 | 11458.2 | 24477.3 | 12.62 | 14.59 |
| enterprise_rag_8192x128 | 3.8 | Collocated (2x TP2) | 451.7 | 86.2 | 476.1 | 9.16 | 20.11 |
| enterprise_rag_8192x128 | 3.8 | Disaggregated (P:2D) | 174.4 | 13535.4 | 28126.1 | 12.61 | 14.57 |
| enterprise_rag_8192x128 | 4.3 | Collocated (2x TP2) | 508.7 | 63.2 | 78.0 | 8.97 | 20.13 |
| enterprise_rag_8192x128 | 4.3 | Disaggregated (P:2D) | 174.3 | 14645.9 | 30101.1 | 12.62 | 14.59 |
