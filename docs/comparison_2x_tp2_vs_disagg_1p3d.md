# Benchmark Report: Collocated (2x TP2) vs. Disaggregated (P:3D)

- **Collocated Dataset:** `results/collocated_2x_tp2`
- **Disaggregated Dataset:** `results/disagg_1p3d`

## 1. Decode-Heavy Workload ($256\text{ in} \times 1024\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP2) | 131.6 | 23.2 | 25.8 | 7.58 | 7.58 | 7.70 |
| **C=1** | Disaggregated (P:3D) | 85.3 | 87.9 | 111.9 | 11.64 | 11.64 | 11.84 |
| **C=4** | Collocated (2x TP2) | 527.3 | 30.3 | 47.4 | 7.56 | 7.56 | 7.72 |
| **C=4** | Disaggregated (P:3D) | 337.9 | 107.1 | 173.9 | 11.70 | 11.70 | 11.93 |
| **C=16** | Collocated (2x TP2) | 1999.9 | 59.6 | 112.2 | 7.94 | 7.94 | 8.48 |
| **C=16** | Disaggregated (P:3D) | 1295.6 | 198.2 | 429.6 | 12.10 | 12.10 | 12.68 |
| **C=32** | Collocated (2x TP2) | 3685.5 | 132.7 | 456.9 | 8.51 | 8.51 | 9.64 |
| **C=32** | Disaggregated (P:3D) | 2418.0 | 348.1 | 680.0 | 12.69 | 12.69 | 13.76 |
| **C=64** | Collocated (2x TP2) | 6536.5 | 242.6 | 475.0 | 9.48 | 9.48 | 11.90 |
| **C=64** | Disaggregated (P:3D) | 4265.4 | 690.2 | 1682.3 | 13.61 | 13.61 | 15.70 |

## 2. Balanced Dialogue Workload ($1024\text{ in} \times 512\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP2) | 130.3 | 44.8 | 53.1 | 7.60 | 7.60 | 7.84 |
| **C=1** | Disaggregated (P:3D) | 82.6 | 194.0 | 260.0 | 11.74 | 11.74 | 11.90 |
| **C=4** | Collocated (2x TP2) | 514.3 | 58.8 | 92.9 | 7.67 | 7.67 | 7.86 |
| **C=4** | Disaggregated (P:3D) | 325.2 | 226.2 | 364.9 | 11.81 | 11.81 | 12.03 |
| **C=16** | Collocated (2x TP2) | 1861.1 | 143.0 | 531.6 | 8.25 | 8.25 | 8.70 |
| **C=16** | Disaggregated (P:3D) | 1180.2 | 341.9 | 1474.0 | 12.39 | 12.39 | 13.13 |
| **C=32** | Collocated (2x TP2) | 3326.5 | 219.7 | 542.9 | 9.17 | 9.17 | 10.10 |
| **C=32** | Disaggregated (P:3D) | 1993.6 | 798.8 | 2031.9 | 13.17 | 13.17 | 14.36 |

## 3. Enterprise RAG Workload ($8192\text{ in} \times 128\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP2) | 88.8 | 426.9 | 433.5 | 7.99 | 7.99 | 8.41 |
| **C=1** | Disaggregated (P:3D) | 39.8 | 1635.9 | 2120.7 | 12.41 | 12.41 | 12.69 |
| **C=4** | Collocated (2x TP2) | 342.2 | 300.9 | 820.2 | 9.36 | 9.36 | 79.79 |
| **C=4** | Disaggregated (P:3D) | 125.5 | 2355.2 | 5587.8 | 12.47 | 12.47 | 13.34 |
| **C=8** | Collocated (2x TP2) | 559.1 | 341.8 | 908.9 | 11.33 | 11.33 | 111.84 |
| **C=8** | Disaggregated (P:3D) | 182.6 | 3626.5 | 5928.2 | 12.50 | 12.50 | 13.68 |
| **C=16** | Collocated (2x TP2) | 741.8 | 580.5 | 2051.5 | 16.56 | 16.62 | 122.53 |
| **C=16** | Disaggregated (P:3D) | 156.5 | 9137.6 | 18044.8 | 12.53 | 12.53 | 13.44 |

## 4. Sustained Injected Burst Shockwave SLA Isolation

| Architecture | Burst Clearance Time (s) | Burst Mean TTFT (ms) | Burst P99 TTFT (ms) | Burst Throughput (tok/s) | Decode P99 ITL Under Burst (ms) |
| --- | --- | --- | --- | --- | --- |
| Collocated (2x TP2) | 3.84 s | 148.9 ms | 869.7 ms | 102673.7 tok/s | **20.11 ms** |
| Disaggregated (P:3D) | **41.99 s** | **3175.9 ms** | **6833.1 ms** | **9383.0 tok/s** | **13.24 ms** |

## 5. Low-Level Systems: NIXL KV-Transfer Bandwidth vs. Silicon Limits

Evaluates physical bus utilization across context lengths ($144.0\text{ KiB/token}$) against **NVLink 12** ceiling ($150.0\text{ GB/s}$):

| Context Length | KV Cache Size (MB) | Collocated TTFT (ms) | Disagg TTFT (ms) | KV Transfer Tax (ms) | Effective NIXL Bandwidth (GB/s) | % of Bus Limit |
| --- | --- | --- | --- | --- | --- | --- |
| 512 tokens | 72.0 MB | 17.5 ms | 65.9 ms | 48.4 ms | **1.56 GB/s** | 1.0% NVLink 12 |
| 1024 tokens | 144.0 MB | 20.3 ms | 58.8 ms | 38.5 ms | **3.92 GB/s** | 2.6% NVLink 12 |
| 2048 tokens | 288.0 MB | 27.7 ms | 82.4 ms | 54.7 ms | **5.52 GB/s** | 3.7% NVLink 12 |
| 4096 tokens | 576.0 MB | 35.1 ms | 410.5 ms | 375.4 ms | **1.61 GB/s** | 1.1% NVLink 12 |
| 8192 tokens | 1152.0 MB | 75.7 ms | 509.3 ms | 433.6 ms | **2.79 GB/s** | 1.9% NVLink 12 |
| 16384 tokens | 2304.0 MB | 636.2 ms | 3520.5 ms | 2884.3 ms | **0.84 GB/s** | 0.6% NVLink 12 |

## 6. Calibrated Poisson Open-Loop SLA Capacity Sweeps

| Workload | Target Rate (req/s) | Architecture | Realized Out Tok/s | Mean TTFT (ms) | P99 TTFT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| balanced_1024x512 | 2 | Collocated (2x TP2) | 908.1 | 30.9 | 48.7 | 7.90 | 8.70 |
| balanced_1024x512 | 2 | Disaggregated (P:3D) | 852.1 | 297.4 | 685.8 | 12.17 | 13.08 |
| balanced_1024x512 | 4 | Collocated (2x TP2) | 1620.1 | 32.7 | 39.4 | 8.20 | 10.08 |
| balanced_1024x512 | 4 | Disaggregated (P:3D) | 1452.3 | 111.8 | 349.8 | 12.70 | 14.15 |
| balanced_1024x512 | 8 | Collocated (2x TP2) | 2629.0 | 36.2 | 48.4 | 8.79 | 11.56 |
| balanced_1024x512 | 8 | Disaggregated (P:3D) | 2184.3 | 103.3 | 172.9 | 13.58 | 15.58 |
| balanced_1024x512 | 12 | Collocated (2x TP2) | 3278.0 | 38.9 | 54.0 | 9.19 | 13.33 |
| balanced_1024x512 | 12 | Disaggregated (P:3D) | 2606.0 | 102.5 | 127.7 | 14.02 | 16.11 |
| balanced_1024x512 | 16 | Collocated (2x TP2) | 3718.2 | 40.3 | 71.0 | 9.48 | 14.22 |
| balanced_1024x512 | 16 | Disaggregated (P:3D) | 2880.7 | 102.9 | 133.0 | 14.21 | 16.06 |
| enterprise_rag_8192x128 | 1.1 | Collocated (2x TP2) | 137.6 | 146.4 | 535.0 | 8.56 | 9.46 |
| enterprise_rag_8192x128 | 1.1 | Disaggregated (P:3D) | 113.7 | 2990.6 | 12373.1 | 12.46 | 13.35 |
| enterprise_rag_8192x128 | 2.2 | Collocated (2x TP2) | 267.2 | 85.4 | 477.8 | 8.76 | 11.38 |
| enterprise_rag_8192x128 | 2.2 | Disaggregated (P:3D) | 113.8 | 13833.5 | 40966.4 | 12.45 | 13.26 |
| enterprise_rag_8192x128 | 3.1 | Collocated (2x TP2) | 374.5 | 69.7 | 229.8 | 8.76 | 19.66 |
| enterprise_rag_8192x128 | 3.1 | Disaggregated (P:3D) | 101.8 | 25047.2 | 58355.2 | 12.44 | 13.19 |
| enterprise_rag_8192x128 | 3.8 | Collocated (2x TP2) | 451.7 | 86.2 | 476.1 | 9.16 | 20.11 |
| enterprise_rag_8192x128 | 3.8 | Disaggregated (P:3D) | 100.5 | 28476.0 | 62949.5 | 12.48 | 13.42 |
| enterprise_rag_8192x128 | 4.3 | Collocated (2x TP2) | 508.7 | 63.2 | 78.0 | 8.97 | 20.13 |
| enterprise_rag_8192x128 | 4.3 | Disaggregated (P:3D) | 101.0 | 28125.6 | 64340.8 | 12.44 | 13.20 |
