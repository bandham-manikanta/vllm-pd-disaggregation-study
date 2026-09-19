# Benchmark Report: Collocated (2x TP1) vs. Disaggregated (1P:2D)

- **Collocated Dataset:** `results/collocated_2x_tp1`
- **Disaggregated Dataset:** `results/disagg_1p2d`

## 1. Decode-Heavy Workload ($256\text{ in} \times 1024\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP1) | 85.7 | 29.8 | 32.3 | 11.65 | 11.65 | 11.87 |
| **C=1** | Disaggregated (1P:2D) | 85.2 | 100.7 | 110.6 | 11.65 | 11.65 | 11.83 |
| **C=4** | Collocated (2x TP1) | 340.5 | 38.0 | 52.5 | 11.72 | 11.72 | 11.94 |
| **C=4** | Disaggregated (1P:2D) | 337.7 | 113.5 | 195.4 | 11.73 | 11.73 | 11.94 |
| **C=16** | Collocated (2x TP1) | 1288.5 | 138.5 | 287.5 | 12.27 | 12.27 | 12.90 |
| **C=16** | Disaggregated (1P:2D) | 1273.2 | 210.8 | 544.0 | 12.27 | 12.27 | 12.99 |
| **C=32** | Collocated (2x TP1) | 2385.8 | 191.9 | 456.2 | 13.17 | 13.17 | 14.46 |
| **C=32** | Disaggregated (1P:2D) | 2298.8 | 553.8 | 1255.7 | 13.09 | 13.09 | 14.39 |
| **C=64** | Collocated (2x TP1) | 4092.2 | 296.9 | 659.5 | 15.27 | 15.27 | 18.02 |
| **C=64** | Disaggregated (1P:2D) | 3886.9 | 752.7 | 1457.4 | 15.03 | 15.03 | 17.88 |

## 2. Balanced Dialogue Workload ($1024\text{ in} \times 512\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP1) | 84.4 | 71.1 | 89.0 | 11.73 | 11.73 | 11.93 |
| **C=1** | Disaggregated (1P:2D) | 81.9 | 246.1 | 270.7 | 11.75 | 11.75 | 11.89 |
| **C=4** | Collocated (2x TP1) | 332.4 | 94.1 | 153.5 | 11.87 | 11.87 | 12.04 |
| **C=4** | Disaggregated (1P:2D) | 326.0 | 204.4 | 515.1 | 11.83 | 11.83 | 12.05 |
| **C=16** | Collocated (2x TP1) | 1218.7 | 164.0 | 429.6 | 12.80 | 12.80 | 13.20 |
| **C=16** | Disaggregated (1P:2D) | 1133.6 | 484.9 | 1508.1 | 12.64 | 12.64 | 13.65 |
| **C=32** | Collocated (2x TP1) | 2119.0 | 298.1 | 757.4 | 14.47 | 14.47 | 15.28 |
| **C=32** | Disaggregated (1P:2D) | 1832.7 | 1118.9 | 3446.9 | 13.66 | 13.66 | 15.13 |

## 3. Enterprise RAG Workload ($8192\text{ in} \times 128\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP1) | 56.9 | 672.5 | 683.9 | 12.42 | 12.42 | 12.75 |
| **C=1** | Disaggregated (1P:2D) | 33.5 | 2249.7 | 2303.4 | 12.39 | 12.39 | 12.62 |
| **C=4** | Collocated (2x TP1) | 189.6 | 707.5 | 1321.7 | 15.52 | 15.52 | 161.69 |
| **C=4** | Disaggregated (1P:2D) | 143.6 | 1790.1 | 7165.1 | 12.89 | 12.89 | 14.13 |
| **C=8** | Collocated (2x TP1) | 369.8 | 480.0 | 1467.8 | 17.90 | 17.90 | 176.21 |
| **C=8** | Disaggregated (1P:2D) | 175.7 | 3802.6 | 5842.7 | 12.71 | 12.71 | 15.11 |
| **C=16** | Collocated (2x TP1) | 462.9 | 946.3 | 3995.5 | 26.37 | 26.37 | 207.44 |
| **C=16** | Disaggregated (1P:2D) | 135.7 | 10719.0 | 25116.5 | 12.72 | 12.72 | 15.02 |

## 4. Sustained Injected Burst Shockwave SLA Isolation

| Architecture | Burst Clearance Time (s) | Burst Mean TTFT (ms) | Burst P99 TTFT (ms) | Burst Throughput (tok/s) | Decode P99 ITL Under Burst (ms) |
| --- | --- | --- | --- | --- | --- |
| Collocated (2x TP1) | 7.14 s | 294.7 ms | 1126.6 ms | 55149.8 tok/s | **31.75 ms** |
| Disaggregated (1P:2D) | **34.22 s** | **2581.6 ms** | **2850.7 ms** | **11512.9 tok/s** | **13.78 ms** |

## 5. Low-Level Systems: NIXL KV-Transfer Bandwidth vs. Silicon Limits

Evaluates physical bus utilization across context lengths ($144.0\text{ KiB/token}$) against **NVLink 12** ceiling ($150.0\text{ GB/s}$):

| Context Length | KV Cache Size (MB) | Collocated TTFT (ms) | Disagg TTFT (ms) | KV Transfer Tax (ms) | Effective NIXL Bandwidth (GB/s) | % of Bus Limit |
| --- | --- | --- | --- | --- | --- | --- |
| 512 tokens | 72.0 MB | 24.3 ms | 58.9 ms | 34.6 ms | **2.18 GB/s** | 1.5% NVLink 12 |
| 1024 tokens | 144.0 MB | 29.5 ms | 64.9 ms | 35.4 ms | **4.27 GB/s** | 2.8% NVLink 12 |
| 2048 tokens | 288.0 MB | 53.8 ms | 81.7 ms | 27.9 ms | **10.82 GB/s** | 7.2% NVLink 12 |
| 4096 tokens | 576.0 MB | 63.8 ms | 182.4 ms | 118.6 ms | **5.09 GB/s** | 3.4% NVLink 12 |
| 8192 tokens | 1152.0 MB | 395.5 ms | 570.1 ms | 174.5 ms | **6.92 GB/s** | 4.6% NVLink 12 |
| 16384 tokens | 2304.0 MB | 1153.8 ms | 4004.7 ms | 2850.9 ms | **0.85 GB/s** | 0.6% NVLink 12 |

## 6. Calibrated Poisson Open-Loop SLA Capacity Sweeps

| Workload | Target Rate (req/s) | Architecture | Realized Out Tok/s | Mean TTFT (ms) | P99 TTFT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| balanced_1024x512 | 2 | Collocated (2x TP1) | 852.6 | 64.3 | 117.6 | 12.68 | 15.36 |
| balanced_1024x512 | 2 | Disaggregated (1P:2D) | 851.3 | 124.4 | 263.9 | 12.49 | 13.75 |
| balanced_1024x512 | 4 | Collocated (2x TP1) | 1437.8 | 54.0 | 122.7 | 13.53 | 17.25 |
| balanced_1024x512 | 4 | Disaggregated (1P:2D) | 1431.3 | 103.9 | 117.8 | 13.35 | 15.20 |
| balanced_1024x512 | 8 | Collocated (2x TP1) | 2125.8 | 54.7 | 134.8 | 14.79 | 20.78 |
| balanced_1024x512 | 8 | Disaggregated (1P:2D) | 2112.7 | 109.9 | 131.7 | 14.60 | 17.12 |
| balanced_1024x512 | 12 | Collocated (2x TP1) | 2478.9 | 51.3 | 72.1 | 15.52 | 20.60 |
| balanced_1024x512 | 12 | Disaggregated (1P:2D) | 2455.9 | 126.0 | 562.8 | 15.48 | 18.13 |
| balanced_1024x512 | 16 | Collocated (2x TP1) | 2654.6 | 81.0 | 196.9 | 16.97 | 81.08 |
| balanced_1024x512 | 16 | Disaggregated (1P:2D) | 2671.4 | 113.5 | 154.9 | 15.94 | 19.06 |
| enterprise_rag_8192x128 | 1.1 | Collocated (2x TP1) | 133.9 | 488.2 | 1332.6 | 17.43 | 188.61 |
| enterprise_rag_8192x128 | 1.1 | Disaggregated (1P:2D) | 127.1 | 1282.4 | 4473.2 | 12.56 | 14.26 |
| enterprise_rag_8192x128 | 2.2 | Collocated (2x TP1) | 251.7 | 768.2 | 1877.2 | 28.19 | 213.06 |
| enterprise_rag_8192x128 | 2.2 | Disaggregated (1P:2D) | 172.5 | 6818.6 | 16380.6 | 12.63 | 14.68 |
| enterprise_rag_8192x128 | 3.1 | Collocated (2x TP1) | 323.5 | 923.3 | 2691.7 | 41.95 | 229.83 |
| enterprise_rag_8192x128 | 3.1 | Disaggregated (1P:2D) | 173.8 | 11458.2 | 24477.3 | 12.62 | 14.59 |
| enterprise_rag_8192x128 | 3.8 | Collocated (2x TP1) | 317.5 | 2422.4 | 5732.4 | 89.36 | 253.38 |
| enterprise_rag_8192x128 | 3.8 | Disaggregated (1P:2D) | 174.4 | 13535.4 | 28126.1 | 12.61 | 14.57 |
| enterprise_rag_8192x128 | 4.3 | Collocated (2x TP1) | 270.3 | 5265.1 | 11444.8 | 115.02 | 273.89 |
| enterprise_rag_8192x128 | 4.3 | Disaggregated (1P:2D) | 174.3 | 14645.9 | 30101.1 | 12.62 | 14.59 |
