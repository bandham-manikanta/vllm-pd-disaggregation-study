# Empirical Systems Report: Collocated (2x TP1) vs. Disaggregated (1P:1D)

- **Collocated Dataset:** `results/collocated_2x_tp1`
- **Disaggregated Dataset:** `results/disagg_1p1d`

## 1. Decode-Heavy Workload ($256\text{ in} \times 1024\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP1) | 85.7 | 29.8 | 32.3 | 11.65 | 11.65 | 11.87 |
| **C=1** | Disaggregated (1P:1D) | 85.6 | 53.6 | 58.4 | 11.64 | 11.64 | 11.82 |
| **C=4** | Collocated (2x TP1) | 340.5 | 38.0 | 52.5 | 11.72 | 11.72 | 11.94 |
| **C=4** | Disaggregated (1P:1D) | 334.7 | 94.1 | 134.7 | 11.87 | 11.87 | 12.16 |
| **C=16** | Collocated (2x TP1) | 1288.5 | 138.5 | 287.5 | 12.27 | 12.27 | 12.90 |
| **C=16** | Disaggregated (1P:1D) | 1194.1 | 256.6 | 694.3 | 13.10 | 13.10 | 14.02 |
| **C=32** | Collocated (2x TP1) | 2385.8 | 191.9 | 456.2 | 13.17 | 13.17 | 14.46 |
| **C=32** | Disaggregated (1P:1D) | 2063.9 | 255.9 | 510.0 | 15.17 | 15.17 | 17.30 |
| **C=64** | Collocated (2x TP1) | 4092.2 | 296.9 | 659.5 | 15.27 | 15.27 | 18.02 |
| **C=64** | Disaggregated (1P:1D) | 3395.3 | 552.3 | 951.8 | 18.06 | 18.06 | 21.73 |

## 2. Balanced Dialogue Workload ($1024\text{ in} \times 512\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP1) | 84.4 | 71.1 | 89.0 | 11.73 | 11.73 | 11.93 |
| **C=1** | Disaggregated (1P:1D) | 83.9 | 101.1 | 113.2 | 11.74 | 11.74 | 11.89 |
| **C=4** | Collocated (2x TP1) | 332.4 | 94.1 | 153.5 | 11.87 | 11.87 | 12.04 |
| **C=4** | Disaggregated (1P:1D) | 325.4 | 115.1 | 213.8 | 12.07 | 12.07 | 12.35 |
| **C=16** | Collocated (2x TP1) | 1218.7 | 164.0 | 429.6 | 12.80 | 12.80 | 13.20 |
| **C=16** | Disaggregated (1P:1D) | 1105.9 | 222.8 | 790.8 | 13.87 | 13.87 | 14.63 |
| **C=32** | Collocated (2x TP1) | 2119.0 | 298.1 | 757.4 | 14.47 | 14.47 | 15.28 |
| **C=32** | Disaggregated (1P:1D) | 1745.2 | 437.9 | 1631.9 | 16.99 | 16.99 | 18.60 |

## 3. Enterprise RAG Workload ($8192\text{ in} \times 128\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP1) | 56.9 | 672.5 | 683.9 | 12.42 | 12.42 | 12.75 |
| **C=1** | Disaggregated (1P:1D) | 54.2 | 783.3 | 834.7 | 12.42 | 12.42 | 12.71 |
| **C=4** | Collocated (2x TP1) | 189.6 | 707.5 | 1321.7 | 15.52 | 15.52 | 161.69 |
| **C=4** | Disaggregated (1P:1D) | 211.0 | 487.7 | 2253.3 | 14.65 | 14.65 | 20.08 |
| **C=8** | Collocated (2x TP1) | 369.8 | 480.0 | 1467.8 | 17.90 | 17.90 | 176.21 |
| **C=8** | Disaggregated (1P:1D) | 174.2 | 3642.3 | 5145.7 | 14.56 | 14.56 | 64.24 |
| **C=16** | Collocated (2x TP1) | 462.9 | 946.3 | 3995.5 | 26.37 | 26.37 | 207.44 |
| **C=16** | Disaggregated (1P:1D) | 192.6 | 7436.7 | 9563.6 | 15.17 | 15.17 | 64.35 |

## 4. Sustained Injected Burst Shockwave SLA Isolation

| Architecture | Burst Clearance Time (s) | Burst Mean TTFT (ms) | Burst P99 TTFT (ms) | Burst Throughput (tok/s) | Decode P99 ITL Under Burst (ms) |
| --- | --- | --- | --- | --- | --- |
| Collocated (2x TP1) | 7.14 s | 294.7 ms | 1126.6 ms | 55149.8 tok/s | **31.75 ms** |
| Disaggregated (1P:1D) | **34.20 s** | **2568.3 ms** | **2868.2 ms** | **11518.8 tok/s** | **62.47 ms** |

## 5. Low-Level Systems: NIXL KV-Transfer Bandwidth vs. Silicon Limits

Evaluates physical bus utilization across context lengths ($144.0\text{ KiB/token}$) against **NVLink 12** ceiling ($150.0\text{ GB/s}$):

| Context Length | KV Cache Size (MB) | Collocated TTFT (ms) | Disagg TTFT (ms) | KV Transfer Tax (ms) | Effective NIXL Bandwidth (GB/s) | % of Bus Limit |
| --- | --- | --- | --- | --- | --- | --- |
| 512 tokens | 72.0 MB | 24.3 ms | 82.4 ms | 58.1 ms | **1.30 GB/s** | 0.9% NVLink 12 |
| 1024 tokens | 144.0 MB | 29.5 ms | 96.7 ms | 67.2 ms | **2.25 GB/s** | 1.5% NVLink 12 |
| 2048 tokens | 288.0 MB | 53.8 ms | 111.4 ms | 57.6 ms | **5.25 GB/s** | 3.5% NVLink 12 |
| 4096 tokens | 576.0 MB | 63.8 ms | 170.8 ms | 107.0 ms | **5.64 GB/s** | 3.8% NVLink 12 |
| 8192 tokens | 1152.0 MB | 395.5 ms | 541.3 ms | 145.8 ms | **8.29 GB/s** | 5.5% NVLink 12 |
| 16384 tokens | 2304.0 MB | 1153.8 ms | 1537.8 ms | 384.0 ms | **6.29 GB/s** | 4.2% NVLink 12 |

## 6. Calibrated Poisson Open-Loop SLA Capacity Sweeps

| Workload | Target Rate (req/s) | Architecture | Realized Out Tok/s | Mean TTFT (ms) | P99 TTFT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| balanced_1024x512 | 2 | Collocated (2x TP1) | 852.6 | 64.3 | 117.6 | 12.68 | 15.36 |
| balanced_1024x512 | 2 | Disaggregated (1P:1D) | 839.1 | 123.5 | 269.4 | 13.62 | 15.51 |
| balanced_1024x512 | 4 | Collocated (2x TP1) | 1437.8 | 54.0 | 122.7 | 13.53 | 17.25 |
| balanced_1024x512 | 4 | Disaggregated (1P:1D) | 1362.8 | 104.5 | 138.9 | 15.74 | 18.80 |
| balanced_1024x512 | 8 | Collocated (2x TP1) | 2125.8 | 54.7 | 134.8 | 14.79 | 20.78 |
| balanced_1024x512 | 8 | Disaggregated (1P:1D) | 1893.8 | 112.7 | 151.9 | 18.21 | 22.09 |
| balanced_1024x512 | 12 | Collocated (2x TP1) | 2478.9 | 51.3 | 72.1 | 15.52 | 20.60 |
| balanced_1024x512 | 12 | Disaggregated (1P:1D) | 2140.1 | 118.2 | 171.6 | 19.32 | 22.94 |
| balanced_1024x512 | 16 | Collocated (2x TP1) | 2654.6 | 81.0 | 196.9 | 16.97 | 81.08 |
| balanced_1024x512 | 16 | Disaggregated (1P:1D) | 2291.7 | 117.6 | 157.4 | 19.93 | 23.04 |
| enterprise_rag_8192x128 | 1.1 | Collocated (2x TP1) | 133.9 | 488.2 | 1332.6 | 17.43 | 188.61 |
| enterprise_rag_8192x128 | 1.1 | Disaggregated (1P:1D) | 126.9 | 1336.0 | 4530.1 | 13.92 | 20.30 |
| enterprise_rag_8192x128 | 2.2 | Collocated (2x TP1) | 251.7 | 768.2 | 1877.2 | 28.19 | 213.06 |
| enterprise_rag_8192x128 | 2.2 | Disaggregated (1P:1D) | 172.2 | 6866.7 | 16404.6 | 14.55 | 63.70 |
| enterprise_rag_8192x128 | 3.1 | Collocated (2x TP1) | 323.5 | 923.3 | 2691.7 | 41.95 | 229.83 |
| enterprise_rag_8192x128 | 3.1 | Disaggregated (1P:1D) | 172.5 | 11608.8 | 24752.6 | 14.53 | 63.38 |
| enterprise_rag_8192x128 | 3.8 | Collocated (2x TP1) | 317.5 | 2422.4 | 5732.4 | 89.36 | 253.38 |
| enterprise_rag_8192x128 | 3.8 | Disaggregated (1P:1D) | 172.7 | 13743.2 | 28496.3 | 14.52 | 63.07 |
| enterprise_rag_8192x128 | 4.3 | Collocated (2x TP1) | 270.3 | 5265.1 | 11444.8 | 115.02 | 273.89 |
| enterprise_rag_8192x128 | 4.3 | Disaggregated (1P:1D) | 172.6 | 14864.2 | 30465.4 | 14.53 | 64.42 |
