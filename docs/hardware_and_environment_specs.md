# Experimental Hardware and Software Specifications

## 1. Node a100-06 (Prefill / Decode / Standalone)

### System & Kernel
```
Linux a100-06 5.14.0-570.33.2.el9_6.x86_64 #1 SMP PREEMPT_DYNAMIC Fri Aug 15 17:42:51 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
PRETTY_NAME="Rocky Linux 9.6 (Blue Onyx)"
```

### Host CPU & Memory
```
CPU op-mode(s):                       32-bit, 64-bit
CPU(s):                               64
On-line CPU(s) list:                  0-63
Model name:                           Intel(R) Xeon(R) Gold 6338 CPU @ 2.00GHz
CPU family:                           6
Thread(s) per core:                   1
Socket(s):                            2
CPU(s) scaling MHz:                   89%
CPU max MHz:                          3200.0000
CPU min MHz:                          800.0000
NUMA node(s):                         2
NUMA node0 CPU(s):                    0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58,60,62
NUMA node1 CPU(s):                    1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59,61,63

RAM:
total        used        free      shared  buff/cache   available
Mem:           251Gi        18Gi       231Gi       228Mi       3.1Gi       232Gi
Swap:             0B          0B          0B
```

### InfiniBand Fabric (100 Gbps HDR)
```
CA 'mlx5_0'
	CA type: MT4125
	Number of ports: 1
	Firmware version: 22.32.2306
	Hardware version: 0
	Node GUID: 0x1070fd0300cda3d0
	System image GUID: 0x1070fd0300cda3d0
	Port 1:
		State: Active
		Physical state: LinkUp
		Rate: 100
		Base lid: 181
		LMC: 0
		SM lid: 20
		Capability mask: 0x2651e848
		Port GUID: 0x1070fd0300cda3d0
		Link layer: InfiniBand
```

### Network Interfaces & IP Configuration
```
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.10.1.176/22 fe80::ca4b:d6ff:fe7b:de88/64 
eth1             DOWN           
ib0              UP             10.10.4.176/23 fe80::1270:fd03:cd:a3d0/64
```

### NVIDIA GPU Configuration & Driver
```
Mon Sep 14 15:21:24 2026       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 595.71.05              Driver Version: 595.71.05      CUDA Version: 13.2     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA A100 80GB PCIe          On  |   00000000:17:00.0 Off |                    0 |
| N/A   70C    P0            302W /  300W |   69617MiB /  81920MiB |    100%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+
|   1  NVIDIA A100 80GB PCIe          On  |   00000000:65:00.0 Off |                    0 |
| N/A   33C    P0             55W /  300W |       0MiB /  81920MiB |      0%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+
|   2  NVIDIA A100 80GB PCIe          On  |   00000000:CA:00.0 N/A |                  N/A |
|ERR!   46C    P0            N/A  /  N/A  |       0MiB /  81920MiB |     N/A      Default |
|                                         |                        |                 ERR! |
+-----------------------------------------+------------------------+----------------------+
|   3  NVIDIA A100 80GB PCIe          On  |   00000000:E3:00.0 N/A |                  N/A |
|ERR!   46C    P0            N/A  /  N/A  |       0MiB /  81920MiB |     N/A      Default |
|                                         |                        |                 ERR! |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A         1383739      C   VLLM::EngineCore                      69608MiB |
+-----------------------------------------------------------------------------------------+
```

### NVLink Topology Matrix
```
Command 'nvidia-smi topo -m' returned non-zero exit status 255.
```

---

## 2. Node a100-04 (Multi-Node Peer)

### InfiniBand & Interfaces
```
CA 'mlx5_0'
	CA type: MT4125
	Number of ports: 1
	Firmware version: 22.32.2306
	Hardware version: 0
	Node GUID: 0x1070fd0300cda73c
	System image GUID: 0x1070fd0300cda73c
	Port 1:
		State: Active
		Physical state: LinkUp
		Rate: 100
		Base lid: 185
		LMC: 0
		SM lid: 20
		Capability mask: 0x2651e848
		Port GUID: 0x1070fd0300cda73c
		Link layer: InfiniBand
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.10.1.174/22 fe80::ca4b:d6ff:fe7b:f0ea/64 
eth1             DOWN           
ib0              UP             10.10.4.174/23 fe80::1270:fd03:cd:a73c/64
```

### GPU Configuration
```
Mon Sep 14 15:21:27 2026       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 595.71.05              Driver Version: 595.71.05      CUDA Version: 13.2     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA A100 80GB PCIe          On  |   00000000:17:00.0 Off |                    0 |
| N/A   35C    P0             52W /  300W |       0MiB /  81920MiB |      0%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+
|   1  NVIDIA A100 80GB PCIe          On  |   00000000:65:00.0 Off |                    0 |
| N/A   35C    P0             54W /  300W |       0MiB /  81920MiB |      0%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+
|   2  NVIDIA A100 80GB PCIe          On  |   00000000:CA:00.0 N/A |                  N/A |
|ERR!   43C    P0            N/A  /  N/A  |       0MiB /  81920MiB |     N/A      Default |
|                                         |                        |                 ERR! |
+-----------------------------------------+------------------------+----------------------+
|   3  NVIDIA A100 80GB PCIe          On  |   00000000:E3:00.0 N/A |                  N/A |
|ERR!   45C    P0            N/A  /  N/A  |       0MiB /  81920MiB |     N/A      Default |
|                                         |                        |                 ERR! |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```

### NVLink Topology Matrix
```
Command 'ssh -o StrictHostKeyChecking=no a100-04 'nvidia-smi topo -m'' returned non-zero exit status 255.
```

---

## 3. Python Environment & Package Manifest

### Python & Key Library Versions
```
Python: 3.10.19
PyTorch: 2.13.0+cu130 CUDA: 13.0
vLLM: 0.28.1rc1.dev463+g199cb9b96.d20260907
```

### Full Pip Manifest
<details>
<summary>Click to view full pip list</summary>

```
Command '/gpfs/projects/MaffeiGroup/venvs/vllm_venv/bin/pip list' returned non-zero exit status 127.
```

</details>
