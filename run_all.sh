#!/usr/bin/env bash
#
# run_all.sh - Automated Sequential Execution of all 9 Bounded 4-GPU Benchmarks
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$SCRIPT_DIR}"
cd "${PROJECT_DIR}"

MODEL=${1:-"Qwen/Qwen3-8B"}

echo "================================================================="
echo " Starting Full Benchmark Automation: 9 Experiments"
echo " Working Directory: ${PROJECT_DIR}"
echo " Model: ${MODEL}"
echo " Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================================="

# Experiment 1: Disaggregated 2P:2D Symmetric
echo "[+] Starting Experiment 1/9: disagg_2p2d..."
bash scripts/launch_disagg_2p2d.sh "${MODEL}"
bash scripts/run_benchmarks.sh disagg_2p2d
echo "[✓] Finished disagg_2p2d. Cooling down 30s..."
sleep 30

# Experiment 2: Disaggregated 1P:3D Asymmetric
echo "[+] Starting Experiment 2/9: disagg_1p3d..."
bash scripts/launch_disagg_1p3d.sh "${MODEL}"
bash scripts/run_benchmarks.sh disagg_1p3d
echo "[✓] Finished disagg_1p3d. Cooling down 30s..."
sleep 30

# Experiment 3: Collocated 2x TP=2 Cluster
echo "[+] Starting Experiment 3/9: collocated_2x_tp2..."
bash scripts/launch_collocated_2x_tp2.sh "${MODEL}"
bash scripts/run_benchmarks.sh collocated_2x_tp2
echo "[✓] Finished collocated_2x_tp2. Cooling down 30s..."
sleep 30

# Experiment 4: Collocated 4x TP=1 Cluster
echo "[+] Starting Experiment 4/9: collocated_4x_tp1..."
bash scripts/launch_collocated_4x_tp1.sh "${MODEL}"
bash scripts/run_benchmarks.sh collocated_4x_tp1
echo "[✓] Finished collocated_4x_tp1. Cooling down 30s..."
sleep 30

# Experiment 5: Disaggregated 1P:2D Sweet Spot
echo "[+] Starting Experiment 5/9: disagg_1p2d..."
bash scripts/launch_disagg_1p2d.sh "${MODEL}"
bash scripts/run_benchmarks.sh disagg_1p2d
echo "[✓] Finished disagg_1p2d. Cooling down 30s..."
sleep 30

# Experiment 6: Disaggregated 1P:1D over InfiniBand
echo "[+] Starting Experiment 6/9: disagg_1p1d_ib..."
bash scripts/launch_disagg_1p1d_ib.sh "${MODEL}"
bash scripts/run_benchmarks.sh disagg_1p1d_ib
echo "[✓] Finished disagg_1p1d_ib. Cooling down 30s..."
sleep 30

# Experiment 7: Disaggregated 1P:1D over NVLink
echo "[+] Starting Experiment 7/9: disagg_1p1d..."
bash scripts/launch_disagg_1p1d.sh "${MODEL}"
bash scripts/run_benchmarks.sh disagg_1p1d
echo "[✓] Finished disagg_1p1d. Cooling down 30s..."
sleep 30

# Experiment 8: Collocated 1x TP=2 NVLink
echo "[+] Starting Experiment 8/9: collocated_1x_tp2..."
bash scripts/launch_collocated_1x_tp2.sh "${MODEL}"
bash scripts/run_benchmarks.sh collocated_1x_tp2
echo "[✓] Finished collocated_1x_tp2. Cooling down 30s..."
sleep 30

# Experiment 9: Collocated 2x TP=1 Local Replicas
echo "[+] Starting Experiment 9/9: collocated_2x_tp1..."
bash scripts/launch_collocated_2x_tp1.sh "${MODEL}"
bash scripts/run_benchmarks.sh collocated_2x_tp1
echo "[✓] Finished collocated_2x_tp1."

echo "================================================================="
echo " ALL 9 BENCHMARKS COMPLETED SUCCESSFULLY!"
echo " Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================================="
