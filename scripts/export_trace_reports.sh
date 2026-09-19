#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${PROJECT_DIR:-$SCRIPT_DIR/..}"
mkdir -p results/traces/reports
for i in {1..8}; do
    trace_file=$(ls results/traces/trace${i}_*.nsys-rep 2>/dev/null || true)
    if [ -n "$trace_file" ]; then
        echo "Exporting stats for trace ${i}: ${trace_file}"
        nsys stats --report cuda_gpu_kern_sum,cuda_api_sum,nvtx_sum --format csv --output "results/traces/reports/trace${i}" "$trace_file"
    fi
done
rm -f results/traces/*.sqlite
echo "All CSV reports exported successfully."
ls -lh results/traces/reports/
