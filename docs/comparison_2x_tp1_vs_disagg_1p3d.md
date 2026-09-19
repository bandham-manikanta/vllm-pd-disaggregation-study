# Benchmark Report: Collocated (2x TP1) vs. Disaggregated (P:3D)

- **Collocated Dataset:** `results/collocated_2x_tp1`
- **Disaggregated Dataset:** `results/disagg_1p3d`

## 1. Decode-Heavy Workload ($256\text{ in} \times 1024\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP1) | 85.7 | 29.8 | 32.3 | 11.65 | 11.65 | 11.87 |
| **C=1** | Disaggregated (P:3D) | 85.3 | 87.9 | 111.9 | 11.64 | 11.64 | 11.84 |
| **C=4** | Collocated (2x TP1) | 340.5 | 38.0 | 52.5 | 11.72 | 11.72 | 11.94 |
| **C=4** | Disaggregated (P:3D) | 337.9 | 107.1 | 173.9 | 11.70 | 11.70 | 11.93 |
| **C=16** | Collocated (2x TP1) | 1288.5 | 138.5 | 287.5 | 12.27 | 12.27 | 12.90 |
| **C=16** | Disaggregated (P:3D) | 1295.6 | 198.2 | 429.6 | 12.10 | 12.10 | 12.68 |
| **C=32** | Collocated (2x TP1) | 2385.8 | 191.9 | 456.2 | 13.17 | 13.17 | 14.46 |
| **C=32** | Disaggregated (P:3D) | 2418.0 | 348.1 | 680.0 | 12.69 | 12.69 | 13.76 |
| **C=64** | Collocated (2x TP1) | 4092.2 | 296.9 | 659.5 | 15.27 | 15.27 | 18.02 |
| **C=64** | Disaggregated (P:3D) | 4265.4 | 690.2 | 1682.3 | 13.61 | 13.61 | 15.70 |

## 2. Balanced Dialogue Workload ($1024\text{ in} \times 512\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP1) | 84.4 | 71.1 | 89.0 | 11.73 | 11.73 | 11.93 |
| **C=1** | Disaggregated (P:3D) | 82.6 | 194.0 | 260.0 | 11.74 | 11.74 | 11.90 |
| **C=4** | Collocated (2x TP1) | 332.4 | 94.1 | 153.5 | 11.87 | 11.87 | 12.04 |
| **C=4** | Disaggregated (P:3D) | 325.2 | 226.2 | 364.9 | 11.81 | 11.81 | 12.03 |
| **C=16** | Collocated (2x TP1) | 1218.7 | 164.0 | 429.6 | 12.80 | 12.80 | 13.20 |
| **C=16** | Disaggregated (P:3D) | 1180.2 | 341.9 | 1474.0 | 12.39 | 12.39 | 13.13 |
| **C=32** | Collocated (2x TP1) | 2119.0 | 298.1 | 757.4 | 14.47 | 14.47 | 15.28 |
| **C=32** | Disaggregated (P:3D) | 1993.6 | 798.8 | 2031.9 | 13.17 | 13.17 | 14.36 |

## 3. Enterprise RAG Workload ($8192\text{ in} \times 128\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (2x TP1) | 56.9 | 672.5 | 683.9 | 12.42 | 12.42 | 12.75 |
| **C=1** | Disaggregated (P:3D) | 39.8 | 1635.9 | 2120.7 | 12.41 | 12.41 | 12.69 |
| **C=4** | Collocated (2x TP1) | 189.6 | 707.5 | 1321.7 | 15.52 | 15.52 | 161.69 |
| **C=4** | Disaggregated (P:3D) | 125.5 | 2355.2 | 5587.8 | 12.47 | 12.47 | 13.34 |
| **C=8** | Collocated (2x TP1) | 369.8 | 480.0 | 1467.8 | 17.90 | 17.90 | 176.21 |
| **C=8** | Disaggregated (P:3D) | 182.6 | 3626.5 | 5928.2 | 12.50 | 12.50 | 13.68 |
| **C=16** | Collocated (2x TP1) | 462.9 | 946.3 | 3995.5 | 26.37 | 26.37 | 207.44 |
| **C=16** | Disaggregated (P:3D) | 156.5 | 9137.6 | 18044.8 | 12.53 | 12.53 | 13.44 |

## 4. Sustained Injected Burst Shockwave SLA Isolation

| Architecture | Burst Clearance Time (s) | Burst Mean TTFT (ms) | Burst P99 TTFT (ms) | Burst Throughput (tok/s) | Decode P99 ITL Under Burst (ms) |
| --- | --- | --- | --- | --- | --- |
| Collocated (2x TP1) | 7.14 s | 294.7 ms | 1126.6 ms | 55149.8 tok/s | **31.75 ms** |
| Disaggregated (P:3D) | **41.99 s** | **3175.9 ms** | **6833.1 ms** | **9383.0 tok/s** | **13.24 ms** |

## 5. Low-Level Systems: NIXL KV-Transfer Bandwidth vs. Silicon Limits

Evaluates physical bus utilization across context lengths ($144.0\text{ KiB/token}$) against **NVLink 12** ceiling ($150.0\text{ GB/s}$):

| Context Length | KV Cache Size (MB) | Collocated TTFT (ms) | Disagg TTFT (ms) | KV Transfer Tax (ms) | Effective NIXL Bandwidth (GB/s) | % of Bus Limit |
| --- | --- | --- | --- | --- | --- | --- |
| 512 tokens | 72.0 MB | 24.3 ms | 65.9 ms | 41.5 ms | **1.82 GB/s** | 1.2% NVLink 12 |
| 1024 tokens | 144.0 MB | 29.5 ms | 58.8 ms | 29.3 ms | **5.16 GB/s** | 3.4% NVLink 12 |
| 2048 tokens | 288.0 MB | 53.8 ms | 82.4 ms | 28.6 ms | **10.56 GB/s** | 7.0% NVLink 12 |
| 4096 tokens | 576.0 MB | 63.8 ms | 410.5 ms | 346.7 ms | **1.74 GB/s** | 1.2% NVLink 12 |
| 8192 tokens | 1152.0 MB | 395.5 ms | 509.3 ms | 113.8 ms | **10.62 GB/s** | 7.1% NVLink 12 |
| 16384 tokens | 2304.0 MB | 1153.8 ms | 3520.5 ms | 2366.7 ms | **1.02 GB/s** | 0.7% NVLink 12 |

## 6. Calibrated Poisson Open-Loop SLA Capacity Sweeps

| Workload | Target Rate (req/s) | Architecture | Realized Out Tok/s | Mean TTFT (ms) | P99 TTFT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| balanced_1024x512 | 2 | Collocated (2x TP1) | 852.6 | 64.3 | 117.6 | 12.68 | 15.36 |
| balanced_1024x512 | 2 | Disaggregated (P:3D) | 852.1 | 297.4 | 685.8 | 12.17 | 13.08 |
| balanced_1024x512 | 4 | Collocated (2x TP1) | 1437.8 | 54.0 | 122.7 | 13.53 | 17.25 |
| balanced_1024x512 | 4 | Disaggregated (P:3D) | 1452.3 | 111.8 | 349.8 | 12.70 | 14.15 |
| balanced_1024x512 | 8 | Collocated (2x TP1) | 2125.8 | 54.7 | 134.8 | 14.79 | 20.78 |
| balanced_1024x512 | 8 | Disaggregated (P:3D) | 2184.3 | 103.3 | 172.9 | 13.58 | 15.58 |
| balanced_1024x512 | 12 | Collocated (2x TP1) | 2478.9 | 51.3 | 72.1 | 15.52 | 20.60 |
| balanced_1024x512 | 12 | Disaggregated (P:3D) | 2606.0 | 102.5 | 127.7 | 14.02 | 16.11 |
| balanced_1024x512 | 16 | Collocated (2x TP1) | 2654.6 | 81.0 | 196.9 | 16.97 | 81.08 |
| balanced_1024x512 | 16 | Disaggregated (P:3D) | 2880.7 | 102.9 | 133.0 | 14.21 | 16.06 |
| enterprise_rag_8192x128 | 1.1 | Collocated (2x TP1) | 133.9 | 488.2 | 1332.6 | 17.43 | 188.61 |
| enterprise_rag_8192x128 | 1.1 | Disaggregated (P:3D) | 113.7 | 2990.6 | 12373.1 | 12.46 | 13.35 |
| enterprise_rag_8192x128 | 2.2 | Collocated (2x TP1) | 251.7 | 768.2 | 1877.2 | 28.19 | 213.06 |
| enterprise_rag_8192x128 | 2.2 | Disaggregated (P:3D) | 113.8 | 13833.5 | 40966.4 | 12.45 | 13.26 |
| enterprise_rag_8192x128 | 3.1 | Collocated (2x TP1) | 323.5 | 923.3 | 2691.7 | 41.95 | 229.83 |
| enterprise_rag_8192x128 | 3.1 | Disaggregated (P:3D) | 101.8 | 25047.2 | 58355.2 | 12.44 | 13.19 |
| enterprise_rag_8192x128 | 3.8 | Collocated (2x TP1) | 317.5 | 2422.4 | 5732.4 | 89.36 | 253.38 |
| enterprise_rag_8192x128 | 3.8 | Disaggregated (P:3D) | 100.5 | 28476.0 | 62949.5 | 12.48 | 13.42 |
| enterprise_rag_8192x128 | 4.3 | Collocated (2x TP1) | 270.3 | 5265.1 | 11444.8 | 115.02 | 273.89 |
| enterprise_rag_8192x128 | 4.3 | Disaggregated (P:3D) | 101.0 | 28125.6 | 64340.8 | 12.44 | 13.20 |
