import glob
import json
import os

results_dir = "/gpfs/projects/MaffeiGroup/open-source-contributions/vllm-pd-disaggregation-study/results"
topologies = sorted(os.listdir(results_dir))

header = "{:<22} | {:<6} | {:<14} | {:<10} | {}".format(
    "Topology", "Files", "Req Completed", "Req Failed", "Status"
)
print(header)
print("-" * 75)

all_passed = True
for topo in topologies:
    topo_dir = os.path.join(results_dir, topo)
    if not os.path.isdir(topo_dir):
        continue
    files = glob.glob(os.path.join(topo_dir, "*.json"))
    tot_completed = 0
    tot_failed = 0
    corrupt = 0
    for f in files:
        try:
            with open(f, "r") as fp:
                d = json.load(fp)
            c = d.get("completed", 0)
            fail = d.get("failed", 0)
            tot_completed += c
            tot_failed += fail
        except Exception:
            corrupt += 1
    
    is_pass = (tot_failed == 0 and len(files) >= 30 and corrupt == 0)
    status = "PASS (0 Failed)" if is_pass else "FLAGGED"
    if not is_pass:
        all_passed = False
    
    row = "{:<22} | {:<6} | {:<14} | {:<10} | {}".format(
        topo, len(files), tot_completed, tot_failed, status
    )
    print(row)

print("-" * 75)
if all_passed:
    print("[ALL TOPOLOGIES 100% CLEAN - ZERO FAILED REQUESTS]")
