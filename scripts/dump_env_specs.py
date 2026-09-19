#!/usr/bin/env python3
import subprocess
import os

spec_file = "/gpfs/projects/MaffeiGroup/open-source-contributions/vllm-pd-disaggregation-study/docs/hardware_and_environment_specs.md"

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, universal_newlines=True).strip()
    except Exception as e:
        return str(e)

uname_out = run_cmd("uname -a")
os_out = run_cmd("cat /etc/os-release | grep PRETTY_NAME")
cpu_out = run_cmd("lscpu | grep -E 'Model name|Socket|Thread|NUMA|CPU.*:|CPU max'")
mem_out = run_cmd("free -h")
ib_out = run_cmd("ibstat 2>/dev/null || ibv_devinfo 2>/dev/null || echo ibstat_not_found")
net_out = run_cmd("ip -br addr")
gpu_out = run_cmd("nvidia-smi")
topo_out = run_cmd("nvidia-smi topo -m")

ib_04 = run_cmd("ssh -o StrictHostKeyChecking=no a100-04 'ibstat 2>/dev/null || ibv_devinfo 2>/dev/null || echo ibstat_not_found'")
net_04 = run_cmd("ssh -o StrictHostKeyChecking=no a100-04 'ip -br addr'")
gpu_04 = run_cmd("ssh -o StrictHostKeyChecking=no a100-04 'nvidia-smi'")
topo_04 = run_cmd("ssh -o StrictHostKeyChecking=no a100-04 'nvidia-smi topo -m'")

py_ver = run_cmd("/gpfs/projects/MaffeiGroup/venvs/vllm_venv/bin/python3 -c \"import sys, torch, vllm; print('Python:', sys.version.split()[0]); print('PyTorch:', torch.__version__, 'CUDA:', torch.version.cuda); print('vLLM:', vllm.__version__)\"")
pip_out = run_cmd("/gpfs/projects/MaffeiGroup/venvs/vllm_venv/bin/pip list")

content = f"""# Experimental Hardware and Software Specifications

## 1. Node a100-06 (Prefill / Decode / Standalone)

### System & Kernel
```
{uname_out}
{os_out}
```

### Host CPU & Memory
```
{cpu_out}

RAM:
{mem_out}
```

### InfiniBand Fabric (100 Gbps HDR)
```
{ib_out}
```

### Network Interfaces & IP Configuration
```
{net_out}
```

### NVIDIA GPU Configuration & Driver
```
{gpu_out}
```

### NVLink Topology Matrix
```
{topo_out}
```

---

## 2. Node a100-04 (Multi-Node Peer)

### InfiniBand & Interfaces
```
{ib_04}
{net_04}
```

### GPU Configuration
```
{gpu_04}
```

### NVLink Topology Matrix
```
{topo_04}
```

---

## 3. Python Environment & Package Manifest

### Python & Key Library Versions
```
{py_ver}
```

### Full Pip Manifest
<details>
<summary>Click to view full pip list</summary>

```
{pip_out}
```

</details>
"""

os.makedirs(os.path.dirname(spec_file), exist_ok=True)
with open(spec_file, "w", encoding="utf-8") as f:
    f.write(content)
print(f"Specs successfully written to {spec_file} ({len(content)} bytes)")
