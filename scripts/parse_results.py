#!/usr/bin/env python3
"""
parse_results.py - Systems-Grade Disaggregation vs Collocated Benchmark Parser

Extracts metrics from official `vllm bench serve` JSON outputs and generates
rigorous Markdown comparative analysis tables across all phases:
- Decode-Heavy (256 in x 1024 out)
- Balanced (1024 in x 512 out)
- Enterprise RAG (8192 in x 128 out)
- Sustained Injected Burst Shockwave Test
- Silicon Limit Context Length & KV-Transfer Bandwidth vs Bus Ceilings
- Calibrated Poisson Open-Loop SLA Capacity Sweeps
"""

import argparse
import glob
import json
import os
import re
import sys
from typing import Any, Dict, List, Optional

# Default Qwen/Qwen3-8B KV Cache constants: 36 layers, 8 heads, 128 dim, 2 bytes/element, K+V
DEFAULT_BYTES_PER_TOKEN = 2 * 36 * 8 * 128 * 2  # 147,456 bytes (144.0 KiB/token)
PCIE_GEN4_CEILING_GBPS = 24.0
IB_100G_CEILING_GBPS = 11.5
NVLINK12_CEILING_GBPS = 150.0


def load_json(path: Optional[str]) -> Optional[Dict[str, Any]]:
    if not path or not os.path.exists(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        print(f"[!] Warning: failed to load {path}: {e}", file=sys.stderr)
        return None


def find_latest_file(pattern: str) -> Optional[str]:
    """Finds the most recently modified file matching the glob pattern."""
    matches = glob.glob(pattern)
    if not matches:
        return None
    return max(matches, key=os.path.getmtime)


def extract_metrics(d: Optional[Dict[str, Any]]) -> Dict[str, Any]:
    if not d:
        return {
            "completed": 0,
            "failed": 0,
            "duration": 0.0,
            "out_tok_s": 0.0,
            "tot_tok_s": 0.0,
            "mean_ttft": 0.0,
            "median_ttft": 0.0,
            "p99_ttft": 0.0,
            "mean_tpot": 0.0,
            "median_tpot": 0.0,
            "p99_tpot": 0.0,
            "mean_itl": 0.0,
            "median_itl": 0.0,
            "p99_itl": 0.0,
        }
    return {
        "completed": d.get("completed", 0),
        "failed": d.get("failed", 0),
        "duration": d.get("duration", 0.0),
        "out_tok_s": d.get("output_throughput", 0.0),
        "tot_tok_s": d.get("total_token_throughput", 0.0),
        "mean_ttft": d.get("mean_ttft_ms", 0.0),
        "median_ttft": d.get("median_ttft_ms", 0.0),
        "p99_ttft": d.get("p99_ttft_ms", 0.0),
        "mean_tpot": d.get("mean_tpot_ms", 0.0),
        "median_tpot": d.get("median_tpot_ms", 0.0),
        "p99_tpot": d.get("p99_tpot_ms", 0.0),
        "mean_itl": d.get("mean_itl_ms", 0.0),
        "median_itl": d.get("median_itl_ms", 0.0),
        "p99_itl": d.get("p99_itl_ms", 0.0),
    }


def format_row(cols: List[str]) -> str:
    return "| " + " | ".join(cols) + " |"


def generate_report(
    collocated_dir: str,
    disagg_dir: str,
    col_label: str = "Collocated",
    dis_label: str = "Disaggregated",
    bytes_per_token: int = DEFAULT_BYTES_PER_TOKEN,
) -> str:
    lines = []
    lines.append(f"# Empirical Systems Report: {col_label} vs. {dis_label}")
    lines.append("")
    lines.append(f"- **Collocated Dataset:** `{collocated_dir}`")
    lines.append(f"- **Disaggregated Dataset:** `{disagg_dir}`")
    lines.append("")

    # Workload table generator
    def render_workload_section(title: str, wl_prefix: str, in_len: int, out_len: int, concurrencies: List[int]):
        has_any = any(
            glob.glob(os.path.join(collocated_dir, f"{wl_prefix}_{in_len}x{out_len}_*.json")) or
            glob.glob(os.path.join(disagg_dir, f"{wl_prefix}_{in_len}x{out_len}_*.json"))
            for _ in [1]
        )
        if not has_any:
            return

        lines.append(f"## {title} (${in_len}\\text{{ in}} \\times {out_len}\\text{{ out}}$)")
        lines.append("")
        headers = [
            "Concurrency",
            "Architecture",
            "Throughput (out tok/s)",
            "Mean TTFT (ms)",
            "P99 TTFT (ms)",
            "Mean TPOT (ms)",
            "Mean ITL (ms)",
            "P99 ITL (ms)",
        ]
        lines.append(format_row(headers))
        lines.append(format_row(["---"] * len(headers)))

        for c in concurrencies:
            f_col = find_latest_file(os.path.join(collocated_dir, f"{wl_prefix}_{in_len}x{out_len}_c{c}_*.json"))
            f_dis = find_latest_file(os.path.join(disagg_dir, f"{wl_prefix}_{in_len}x{out_len}_c{c}_*.json"))

            m_col = extract_metrics(load_json(f_col)) if f_col else None
            m_dis = extract_metrics(load_json(f_dis)) if f_dis else None

            if m_col:
                lines.append(format_row([
                    f"**C={c}**",
                    col_label,
                    f"{m_col['out_tok_s']:.1f}",
                    f"{m_col['mean_ttft']:.1f}",
                    f"{m_col['p99_ttft']:.1f}",
                    f"{m_col['mean_tpot']:.2f}",
                    f"{m_col['mean_itl']:.2f}",
                    f"{m_col['p99_itl']:.2f}",
                ]))
            if m_dis:
                lines.append(format_row([
                    f"**C={c}**",
                    dis_label,
                    f"{m_dis['out_tok_s']:.1f}",
                    f"{m_dis['mean_ttft']:.1f}",
                    f"{m_dis['p99_ttft']:.1f}",
                    f"{m_dis['mean_tpot']:.2f}",
                    f"{m_dis['mean_itl']:.2f}",
                    f"{m_dis['p99_itl']:.2f}",
                ]))
        lines.append("")

    all_concs = [1, 4, 8, 16, 32, 64]
    render_workload_section("1. Decode-Heavy Workload", "decode_heavy", 256, 1024, [1, 4, 16, 32, 64])
    render_workload_section("2. Balanced Dialogue Workload", "balanced", 1024, 512, [1, 4, 16, 32])
    render_workload_section("3. Enterprise RAG Workload", "enterprise_rag", 8192, 128, [1, 4, 8, 16])
    # Fallback to older prefill_heavy if present
    render_workload_section("3b. Legacy Prefill-Heavy Workload", "prefill_heavy", 4096, 128, [1, 4, 16])

    # Injected Burst Table
    f_col_inj = find_latest_file(os.path.join(collocated_dir, "injected_burst_*.json"))
    f_dis_inj = find_latest_file(os.path.join(disagg_dir, "injected_burst_*.json"))
    f_col_bst = find_latest_file(os.path.join(collocated_dir, "decode_under_burst_*.json"))
    f_dis_bst = find_latest_file(os.path.join(disagg_dir, "decode_under_burst_*.json"))

    if f_col_inj or f_dis_inj or f_col_bst or f_dis_bst:
        lines.append("## 4. Sustained Injected Burst Shockwave SLA Isolation")
        lines.append("")
        headers = [
            "Architecture",
            "Burst Clearance Time (s)",
            "Burst Mean TTFT (ms)",
            "Burst P99 TTFT (ms)",
            "Burst Throughput (tok/s)",
            "Decode P99 ITL Under Burst (ms)",
        ]
        lines.append(format_row(headers))
        lines.append(format_row(["---"] * len(headers)))

        if f_col_inj or f_col_bst:
            m_inj = extract_metrics(load_json(f_col_inj)) if f_col_inj else extract_metrics(None)
            m_bst = extract_metrics(load_json(f_col_bst)) if f_col_bst else extract_metrics(None)
            lines.append(format_row([
                col_label,
                f"{m_inj['duration']:.2f} s" if f_col_inj else "N/A",
                f"{m_inj['mean_ttft']:.1f} ms" if f_col_inj else "N/A",
                f"{m_inj['p99_ttft']:.1f} ms" if f_col_inj else "N/A",
                f"{m_inj['tot_tok_s']:.1f} tok/s" if f_col_inj else "N/A",
                f"**{m_bst['p99_itl']:.2f} ms**",
            ]))

        if f_dis_inj or f_dis_bst:
            m_inj = extract_metrics(load_json(f_dis_inj)) if f_dis_inj else extract_metrics(None)
            m_bst = extract_metrics(load_json(f_dis_bst)) if f_dis_bst else extract_metrics(None)
            lines.append(format_row([
                dis_label,
                f"**{m_inj['duration']:.2f} s**" if f_dis_inj else "N/A",
                f"**{m_inj['mean_ttft']:.1f} ms**" if f_dis_inj else "N/A",
                f"**{m_inj['p99_ttft']:.1f} ms**" if f_dis_inj else "N/A",
                f"**{m_inj['tot_tok_s']:.1f} tok/s**" if f_dis_inj else "N/A",
                f"**{m_bst['p99_itl']:.2f} ms**",
            ]))
        lines.append("")

    # Context Length & Silicon Limit Bandwidth Sweep
    ctx_sweep_files = glob.glob(os.path.join(disagg_dir, "context_sweep_*in_32out_*.json"))
    if ctx_sweep_files:
        lines.append("## 5. Low-Level Systems: NIXL KV-Transfer Bandwidth vs. Silicon Limits")
        lines.append("")
        
        is_ib = "ib" in disagg_dir.lower() or "multinode" in disagg_dir.lower()
        bus_ceiling = IB_100G_CEILING_GBPS if is_ib else NVLINK12_CEILING_GBPS
        bus_name = "100G InfiniBand" if is_ib else "NVLink 12"

        lines.append(f"Evaluates physical bus utilization across context lengths (${bytes_per_token / 1024:.1f}\\text{{ KiB/token}}$) against **{bus_name}** ceiling (${bus_ceiling:.1f}\\text{{ GB/s}}$):")
        lines.append("")
        headers = [
            "Context Length",
            "KV Cache Size (MB)",
            "Collocated TTFT (ms)",
            "Disagg TTFT (ms)",
            "KV Transfer Tax (ms)",
            "Effective NIXL Bandwidth (GB/s)",
            "% of Bus Limit",
        ]
        lines.append(format_row(headers))
        lines.append(format_row(["---"] * len(headers)))

        ctx_lengths = [512, 1024, 2048, 4096, 8192, 16384]
        for ctx in ctx_lengths:
            f_col = find_latest_file(os.path.join(collocated_dir, f"context_sweep_{ctx}in_32out_*.json"))
            f_dis = find_latest_file(os.path.join(disagg_dir, f"context_sweep_{ctx}in_32out_*.json"))
            if not f_dis:
                continue

            m_col = extract_metrics(load_json(f_col)) if f_col else None
            m_dis = extract_metrics(load_json(f_dis))

            kv_bytes = ctx * bytes_per_token
            kv_mb = kv_bytes / (1024 * 1024)
            kv_gb = kv_bytes / 1e9

            col_ttft = m_col['mean_ttft'] if m_col else 0.0
            dis_ttft = m_dis['mean_ttft']
            delta = dis_ttft - col_ttft

            if delta > 0:
                transfer_tax = delta
                eff_bw = kv_gb / (transfer_tax / 1000.0)
                pct = min((eff_bw / bus_ceiling) * 100.0, 100.0)
                tax_str = f"{transfer_tax:.1f} ms"
                eff_bw_str = f"**{eff_bw:.2f} GB/s**"
                pct_str = f"{pct:.1f}% {bus_name}"
            else:
                tax_str = f"Gain: -{abs(delta):.1f} ms"
                eff_bw_str = "N/A (Disagg Faster)"
                pct_str = "100% Isolated"

            lines.append(format_row([
                f"{ctx} tokens",
                f"{kv_mb:.1f} MB",
                f"{col_ttft:.1f} ms" if col_ttft else "N/A",
                f"{dis_ttft:.1f} ms",
                tax_str,
                eff_bw_str,
                pct_str,
            ]))
        lines.append("")

    # Calibrated Poisson Open-Loop SLA Table
    poisson_files = glob.glob(os.path.join(collocated_dir, "poisson_*.json")) + glob.glob(os.path.join(disagg_dir, "poisson_*.json"))
    if poisson_files:
        lines.append("## 6. Calibrated Poisson Open-Loop SLA Capacity Sweeps")
        lines.append("")
        headers = [
            "Workload",
            "Target Rate (req/s)",
            "Architecture",
            "Realized Out Tok/s",
            "Mean TTFT (ms)",
            "P99 TTFT (ms)",
            "Mean ITL (ms)",
            "P99 ITL (ms)",
        ]
        lines.append(format_row(headers))
        lines.append(format_row(["---"] * len(headers)))

        # Find all unique workload and rate pairs
        seen_pairs = set()
        for p in poisson_files:
            match = re.search(r"poisson_([a-zA-Z0-9_]+)_rate([0-9\.]+)_", os.path.basename(p))
            if match:
                wl_name, rate = match.group(1), match.group(2)
                seen_pairs.add((wl_name, float(rate)))

        for wl_name, rate in sorted(seen_pairs, key=lambda x: (x[0], x[1])):
            rate_str = f"{rate:g}"
            f_col = find_latest_file(os.path.join(collocated_dir, f"poisson_{wl_name}_rate{rate_str}_*.json"))
            f_dis = find_latest_file(os.path.join(disagg_dir, f"poisson_{wl_name}_rate{rate_str}_*.json"))

            m_col = extract_metrics(load_json(f_col)) if f_col else None
            m_dis = extract_metrics(load_json(f_dis)) if f_dis else None

            if m_col:
                lines.append(format_row([
                    wl_name,
                    rate_str,
                    col_label,
                    f"{m_col['out_tok_s']:.1f}",
                    f"{m_col['mean_ttft']:.1f}",
                    f"{m_col['p99_ttft']:.1f}",
                    f"{m_col['mean_tpot']:.2f}",
                    f"{m_col['p99_itl']:.2f}",
                ]))
            if m_dis:
                lines.append(format_row([
                    wl_name,
                    rate_str,
                    dis_label,
                    f"{m_dis['out_tok_s']:.1f}",
                    f"{m_dis['mean_ttft']:.1f}",
                    f"{m_dis['p99_ttft']:.1f}",
                    f"{m_dis['mean_tpot']:.2f}",
                    f"{m_dis['p99_itl']:.2f}",
                ]))
        lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Parse vLLM P/D vs Collocated Benchmark Results")
    parser.add_argument("--collocated", "--collocated-dir", dest="collocated_dir", default="results/collocated_1x_tp2", help="Path to collocated results directory")
    parser.add_argument("--disaggregated", "--disagg-dir", dest="disagg_dir", default="results/disagg_2p2d", help="Path to disaggregated results directory")
    parser.add_argument("--col-label", default="Collocated (TP=2)", help="Label for collocated system")
    parser.add_argument("--dis-label", default="Disaggregated (2P:2D)", help="Label for disaggregated system")
    parser.add_argument("--bytes-per-token", type=int, default=DEFAULT_BYTES_PER_TOKEN, help="KV cache bytes per token")
    parser.add_argument("--output", default=None, help="Path to write output markdown file")
    args = parser.parse_args()

    report = generate_report(
        args.collocated_dir,
        args.disagg_dir,
        args.col_label,
        args.dis_label,
        bytes_per_token=args.bytes_per_token,
    )
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(report)
        print(f"[✓] Analysis successfully written to: {args.output}")
    else:
        print(report)


if __name__ == "__main__":
    main()
