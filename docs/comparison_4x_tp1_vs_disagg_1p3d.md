# Benchmark Report: Collocated (4x TP1) vs. Disaggregated (P:3D)

- **Collocated Dataset:** `results/collocated_4x_tp1`
- **Disaggregated Dataset:** `results/disagg_1p3d`

## 1. Decode-Heavy Workload ($256\text{ in} \times 1024\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (4x TP1) | 85.7 | 41.2 | 277.3 | 11.64 | 11.64 | 11.86 |
| **C=1** | Disaggregated (P:3D) | 85.3 | 87.9 | 111.9 | 11.64 | 11.64 | 11.84 |
| **C=4** | Collocated (4x TP1) | 342.0 | 28.1 | 35.6 | 11.66 | 11.66 | 11.89 |
| **C=4** | Disaggregated (P:3D) | 337.9 | 107.1 | 173.9 | 11.70 | 11.70 | 11.93 |
| **C=16** | Collocated (4x TP1) | 1333.0 | 86.9 | 414.3 | 11.89 | 11.89 | 12.32 |
| **C=16** | Disaggregated (P:3D) | 1295.6 | 198.2 | 429.6 | 12.10 | 12.10 | 12.68 |
| **C=32** | Collocated (4x TP1) | 2569.5 | 123.8 | 196.2 | 12.30 | 12.30 | 13.24 |
| **C=32** | Disaggregated (P:3D) | 2418.0 | 348.1 | 680.0 | 12.69 | 12.69 | 13.76 |
| **C=64** | Collocated (4x TP1) | 4746.1 | 227.2 | 465.5 | 13.22 | 13.22 | 14.93 |
| **C=64** | Disaggregated (P:3D) | 4265.4 | 690.2 | 1682.3 | 13.61 | 13.61 | 15.70 |

## 2. Balanced Dialogue Workload ($1024\text{ in} \times 512\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (4x TP1) | 84.4 | 70.5 | 79.2 | 11.74 | 11.74 | 11.94 |
| **C=1** | Disaggregated (P:3D) | 82.6 | 194.0 | 260.0 | 11.74 | 11.74 | 11.90 |
| **C=4** | Collocated (4x TP1) | 336.2 | 70.7 | 93.1 | 11.77 | 11.77 | 11.99 |
| **C=4** | Disaggregated (P:3D) | 325.2 | 226.2 | 364.9 | 11.81 | 11.81 | 12.03 |
| **C=16** | Collocated (4x TP1) | 1277.4 | 154.3 | 276.0 | 12.20 | 12.20 | 12.60 |
| **C=16** | Disaggregated (P:3D) | 1180.2 | 341.9 | 1474.0 | 12.39 | 12.39 | 13.13 |
| **C=32** | Collocated (4x TP1) | 2354.1 | 270.1 | 504.9 | 12.97 | 12.97 | 13.79 |
| **C=32** | Disaggregated (P:3D) | 1993.6 | 798.8 | 2031.9 | 13.17 | 13.17 | 14.36 |

## 3. Enterprise RAG Workload ($8192\text{ in} \times 128\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Collocated (4x TP1) | 56.9 | 673.2 | 683.6 | 12.41 | 12.41 | 12.72 |
| **C=1** | Disaggregated (P:3D) | 39.8 | 1635.9 | 2120.7 | 12.41 | 12.41 | 12.69 |
| **C=4** | Collocated (4x TP1) | 227.5 | 604.4 | 750.7 | 12.43 | 12.43 | 12.80 |
| **C=4** | Disaggregated (P:3D) | 125.5 | 2355.2 | 5587.8 | 12.47 | 12.47 | 13.34 |
| **C=8** | Collocated (4x TP1) | 392.7 | 578.6 | 1426.8 | 14.92 | 14.92 | 153.78 |
| **C=8** | Disaggregated (P:3D) | 182.6 | 3626.5 | 5928.2 | 12.50 | 12.50 | 13.68 |
| **C=16** | Collocated (4x TP1) | 568.3 | 847.6 | 2215.1 | 20.72 | 20.72 | 193.85 |
| **C=16** | Disaggregated (P:3D) | 156.5 | 9137.6 | 18044.8 | 12.53 | 12.53 | 13.44 |

## 4. Sustained Injected Burst Shockwave SLA Isolation

| Architecture | Burst Clearance Time (s) | Burst Mean TTFT (ms) | Burst P99 TTFT (ms) | Burst Throughput (tok/s) | Decode P99 ITL Under Burst (ms) |
| --- | --- | --- | --- | --- | --- |
| Collocated (4x TP1) | 5.55 s | 257.3 ms | 816.2 ms | 71010.2 tok/s | **24.20 ms** |
| Disaggregated (P:3D) | **41.99 s** | **3175.9 ms** | **6833.1 ms** | **9383.0 tok/s** | **13.24 ms** |

## 5. Low-Level Systems: NIXL KV-Transfer Bandwidth vs. Silicon Limits

Evaluates physical bus utilization across context lengths ($144.0\text{ KiB/token}$) against **NVLink 12** ceiling ($150.0\text{ GB/s}$):

| Context Length | KV Cache Size (MB) | Collocated TTFT (ms) | Disagg TTFT (ms) | KV Transfer Tax (ms) | Effective NIXL Bandwidth (GB/s) | % of Bus Limit |
| --- | --- | --- | --- | --- | --- | --- |
| 512 tokens | 72.0 MB | 26.0 ms | 65.9 ms | 39.8 ms | **1.90 GB/s** | 1.3% NVLink 12 |
| 1024 tokens | 144.0 MB | 31.7 ms | 58.8 ms | 27.1 ms | **5.57 GB/s** | 3.7% NVLink 12 |
| 2048 tokens | 288.0 MB | 37.2 ms | 82.4 ms | 45.2 ms | **6.68 GB/s** | 4.5% NVLink 12 |
| 4096 tokens | 576.0 MB | 98.5 ms | 410.5 ms | 312.0 ms | **1.94 GB/s** | 1.3% NVLink 12 |
| 8192 tokens | 1152.0 MB | 127.5 ms | 509.3 ms | 381.8 ms | **3.16 GB/s** | 2.1% NVLink 12 |
| 16384 tokens | 2304.0 MB | 1119.3 ms | 3520.5 ms | 2401.2 ms | **1.01 GB/s** | 0.7% NVLink 12 |

## 6. Calibrated Poisson Open-Loop SLA Capacity Sweeps

| Workload | Target Rate (req/s) | Architecture | Realized Out Tok/s | Mean TTFT (ms) | P99 TTFT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| balanced_1024x512 | 2 | Collocated (4x TP1) | 858.2 | 54.8 | 117.1 | 12.08 | 12.85 |
| balanced_1024x512 | 2 | Disaggregated (P:3D) | 852.1 | 297.4 | 685.8 | 12.17 | 13.08 |
| balanced_1024x512 | 4 | Collocated (4x TP1) | 1463.7 | 57.3 | 121.6 | 12.58 | 14.52 |
| balanced_1024x512 | 4 | Disaggregated (P:3D) | 1452.3 | 111.8 | 349.8 | 12.70 | 14.15 |
| balanced_1024x512 | 8 | Collocated (4x TP1) | 2234.1 | 56.4 | 126.4 | 13.27 | 16.65 |
| balanced_1024x512 | 8 | Disaggregated (P:3D) | 2184.3 | 103.3 | 172.9 | 13.58 | 15.58 |
| balanced_1024x512 | 12 | Collocated (4x TP1) | 2693.1 | 46.1 | 116.3 | 13.40 | 16.48 |
| balanced_1024x512 | 12 | Disaggregated (P:3D) | 2606.0 | 102.5 | 127.7 | 14.02 | 16.11 |
| balanced_1024x512 | 16 | Collocated (4x TP1) | 2998.9 | 43.3 | 55.3 | 13.51 | 15.95 |
| balanced_1024x512 | 16 | Disaggregated (P:3D) | 2880.7 | 102.9 | 133.0 | 14.21 | 16.06 |
| enterprise_rag_8192x128 | 1.1 | Collocated (4x TP1) | 135.6 | 300.0 | 859.6 | 12.89 | 13.44 |
| enterprise_rag_8192x128 | 1.1 | Disaggregated (P:3D) | 113.7 | 2990.6 | 12373.1 | 12.46 | 13.35 |
| enterprise_rag_8192x128 | 2.2 | Collocated (4x TP1) | 260.0 | 290.7 | 1321.9 | 13.68 | 15.32 |
| enterprise_rag_8192x128 | 2.2 | Disaggregated (P:3D) | 113.8 | 13833.5 | 40966.4 | 12.45 | 13.26 |
| enterprise_rag_8192x128 | 3.1 | Collocated (4x TP1) | 340.3 | 357.9 | 1533.4 | 14.51 | 25.02 |
| enterprise_rag_8192x128 | 3.1 | Disaggregated (P:3D) | 101.8 | 25047.2 | 58355.2 | 12.44 | 13.19 |
| enterprise_rag_8192x128 | 3.8 | Collocated (4x TP1) | 421.6 | 270.5 | 1272.3 | 15.01 | 28.30 |
| enterprise_rag_8192x128 | 3.8 | Disaggregated (P:3D) | 100.5 | 28476.0 | 62949.5 | 12.48 | 13.42 |
| enterprise_rag_8192x128 | 4.3 | Collocated (4x TP1) | 471.3 | 460.4 | 1214.6 | 17.81 | 184.87 |
| enterprise_rag_8192x128 | 4.3 | Disaggregated (P:3D) | 101.0 | 28125.6 | 64340.8 | 12.44 | 13.20 |
