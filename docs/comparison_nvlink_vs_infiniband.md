# Empirical Systems Report: Disagg (NVLink 12) vs. Disagg (100G InfiniBand)

- **Collocated Dataset:** `results/disagg_1p1d`
- **Disaggregated Dataset:** `results/disagg_1p1d_ib`

## 1. Decode-Heavy Workload ($256\text{ in} \times 1024\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Disagg (NVLink 12) | 85.6 | 53.6 | 58.4 | 11.64 | 11.64 | 11.82 |
| **C=1** | Disagg (100G InfiniBand) | 85.3 | 93.7 | 103.4 | 11.65 | 11.65 | 11.84 |
| **C=4** | Disagg (NVLink 12) | 334.7 | 94.1 | 134.7 | 11.87 | 11.87 | 12.16 |
| **C=4** | Disagg (100G InfiniBand) | 333.9 | 112.2 | 196.3 | 11.87 | 11.87 | 12.21 |
| **C=16** | Disagg (NVLink 12) | 1194.1 | 256.6 | 694.3 | 13.10 | 13.10 | 14.02 |
| **C=16** | Disagg (100G InfiniBand) | 1182.9 | 331.0 | 1067.0 | 13.14 | 13.14 | 14.24 |
| **C=32** | Disagg (NVLink 12) | 2063.9 | 255.9 | 510.0 | 15.17 | 15.17 | 17.30 |
| **C=32** | Disagg (100G InfiniBand) | 2027.1 | 404.2 | 1355.6 | 15.27 | 15.27 | 18.38 |
| **C=64** | Disagg (NVLink 12) | 3395.3 | 552.3 | 951.8 | 18.06 | 18.06 | 21.73 |
| **C=64** | Disagg (100G InfiniBand) | 3345.2 | 620.3 | 1730.0 | 18.16 | 18.16 | 28.73 |

## 2. Balanced Dialogue Workload ($1024\text{ in} \times 512\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Disagg (NVLink 12) | 83.9 | 101.1 | 113.2 | 11.74 | 11.74 | 11.89 |
| **C=1** | Disagg (100G InfiniBand) | 82.0 | 246.2 | 266.3 | 11.74 | 11.74 | 11.89 |
| **C=4** | Disagg (NVLink 12) | 325.4 | 115.1 | 213.8 | 12.07 | 12.07 | 12.35 |
| **C=4** | Disagg (100G InfiniBand) | 321.0 | 192.6 | 608.0 | 12.07 | 12.07 | 12.37 |
| **C=16** | Disagg (NVLink 12) | 1105.9 | 222.8 | 790.8 | 13.87 | 13.87 | 14.63 |
| **C=16** | Disagg (100G InfiniBand) | 1046.1 | 510.8 | 2471.3 | 13.85 | 13.85 | 14.84 |
| **C=32** | Disagg (NVLink 12) | 1745.2 | 437.9 | 1631.9 | 16.99 | 16.99 | 18.60 |
| **C=32** | Disagg (100G InfiniBand) | 1580.2 | 1167.1 | 5031.1 | 16.69 | 16.69 | 18.87 |

## 3. Enterprise RAG Workload ($8192\text{ in} \times 128\text{ out}$)

| Concurrency | Architecture | Throughput (out tok/s) | Mean TTFT (ms) | P99 TTFT (ms) | Mean TPOT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **C=1** | Disagg (NVLink 12) | 54.2 | 783.3 | 834.7 | 12.42 | 12.42 | 12.71 |
| **C=1** | Disagg (100G InfiniBand) | 33.6 | 2227.8 | 2244.0 | 12.41 | 12.41 | 12.68 |
| **C=4** | Disagg (NVLink 12) | 211.0 | 487.7 | 2253.3 | 14.65 | 14.65 | 20.08 |
| **C=4** | Disagg (100G InfiniBand) | 131.2 | 1911.0 | 6621.3 | 14.00 | 14.00 | 16.94 |
| **C=8** | Disagg (NVLink 12) | 174.2 | 3642.3 | 5145.7 | 14.56 | 14.56 | 64.24 |
| **C=8** | Disagg (100G InfiniBand) | 69.8 | 12088.1 | 14640.9 | 12.50 | 12.50 | 13.36 |
| **C=16** | Disagg (NVLink 12) | 192.6 | 7436.7 | 9563.6 | 15.17 | 15.17 | 64.35 |
| **C=16** | Disagg (100G InfiniBand) | 74.3 | 22799.1 | 27603.9 | 12.60 | 12.60 | 14.91 |

## 4. Sustained Injected Burst Shockwave SLA Isolation

| Architecture | Burst Clearance Time (s) | Burst Mean TTFT (ms) | Burst P99 TTFT (ms) | Burst Throughput (tok/s) | Decode P99 ITL Under Burst (ms) |
| --- | --- | --- | --- | --- | --- |
| Disagg (NVLink 12) | 34.20 s | 2568.3 ms | 2868.2 ms | 11518.8 tok/s | **62.47 ms** |
| Disagg (100G InfiniBand) | **86.88 s** | **6839.0 ms** | **7683.5 ms** | **4534.8 tok/s** | **15.16 ms** |

## 5. Low-Level Systems: NIXL KV-Transfer Bandwidth vs. Silicon Limits

Evaluates physical bus utilization across context lengths ($144.0\text{ KiB/token}$) against **100G InfiniBand** ceiling ($11.5\text{ GB/s}$):

| Context Length | KV Cache Size (MB) | Collocated TTFT (ms) | Disagg TTFT (ms) | KV Transfer Tax (ms) | Effective NIXL Bandwidth (GB/s) | % of Bus Limit |
| --- | --- | --- | --- | --- | --- | --- |
| 512 tokens | 72.0 MB | 82.4 ms | 122.1 ms | 39.7 ms | **1.90 GB/s** | 16.5% 100G InfiniBand |
| 1024 tokens | 144.0 MB | 96.7 ms | 125.1 ms | 28.4 ms | **5.31 GB/s** | 46.2% 100G InfiniBand |
| 2048 tokens | 288.0 MB | 111.4 ms | 190.8 ms | 79.4 ms | **3.80 GB/s** | 33.1% 100G InfiniBand |
| 4096 tokens | 576.0 MB | 170.8 ms | 344.5 ms | 173.7 ms | **3.48 GB/s** | 30.2% 100G InfiniBand |
| 8192 tokens | 1152.0 MB | 541.3 ms | 1468.9 ms | 927.7 ms | **1.30 GB/s** | 11.3% 100G InfiniBand |
| 16384 tokens | 2304.0 MB | 1537.8 ms | 3303.0 ms | 1765.1 ms | **1.37 GB/s** | 11.9% 100G InfiniBand |

## 6. Calibrated Poisson Open-Loop SLA Capacity Sweeps

| Workload | Target Rate (req/s) | Architecture | Realized Out Tok/s | Mean TTFT (ms) | P99 TTFT (ms) | Mean ITL (ms) | P99 ITL (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| balanced_1024x512 | 2 | Disagg (NVLink 12) | 839.1 | 123.5 | 269.4 | 13.62 | 15.51 |
| balanced_1024x512 | 2 | Disagg (100G InfiniBand) | 838.8 | 226.9 | 938.0 | 13.64 | 15.64 |
| balanced_1024x512 | 4 | Disagg (NVLink 12) | 1362.8 | 104.5 | 138.9 | 15.74 | 18.80 |
| balanced_1024x512 | 4 | Disagg (100G InfiniBand) | 1362.2 | 118.2 | 139.7 | 15.75 | 19.14 |
| balanced_1024x512 | 8 | Disagg (NVLink 12) | 1893.8 | 112.7 | 151.9 | 18.21 | 22.09 |
| balanced_1024x512 | 8 | Disagg (100G InfiniBand) | 1889.6 | 126.4 | 162.1 | 18.23 | 22.90 |
| balanced_1024x512 | 12 | Disagg (NVLink 12) | 2140.1 | 118.2 | 171.6 | 19.32 | 22.94 |
| balanced_1024x512 | 12 | Disagg (100G InfiniBand) | 2137.6 | 125.7 | 160.0 | 19.35 | 23.16 |
| balanced_1024x512 | 16 | Disagg (NVLink 12) | 2291.7 | 117.6 | 157.4 | 19.93 | 23.04 |
| balanced_1024x512 | 16 | Disagg (100G InfiniBand) | 2290.5 | 125.4 | 165.7 | 19.93 | 23.54 |
| enterprise_rag_8192x128 | 1.1 | Disagg (NVLink 12) | 126.9 | 1336.0 | 4530.1 | 13.92 | 20.30 |
| enterprise_rag_8192x128 | 1.1 | Disagg (100G InfiniBand) | 76.9 | 16597.9 | 45754.0 | 12.72 | 14.49 |
| enterprise_rag_8192x128 | 2.2 | Disagg (NVLink 12) | 172.2 | 6866.7 | 16404.6 | 14.55 | 63.70 |
| enterprise_rag_8192x128 | 2.2 | Disagg (100G InfiniBand) | 70.0 | 44350.0 | 85398.6 | 12.50 | 13.27 |
| enterprise_rag_8192x128 | 3.1 | Disagg (NVLink 12) | 172.5 | 11608.8 | 24752.6 | 14.53 | 63.38 |
| enterprise_rag_8192x128 | 3.1 | Disagg (100G InfiniBand) | 69.9 | 49035.9 | 93958.5 | 12.50 | 13.29 |
| enterprise_rag_8192x128 | 3.8 | Disagg (NVLink 12) | 172.7 | 13743.2 | 28496.3 | 14.52 | 63.07 |
| enterprise_rag_8192x128 | 3.8 | Disagg (100G InfiniBand) | 69.9 | 51276.5 | 97809.3 | 12.50 | 13.27 |
| enterprise_rag_8192x128 | 4.3 | Disagg (NVLink 12) | 172.6 | 14864.2 | 30465.4 | 14.53 | 64.42 |
| enterprise_rag_8192x128 | 4.3 | Disagg (100G InfiniBand) | 69.9 | 52334.1 | 99613.2 | 12.49 | 13.47 |
