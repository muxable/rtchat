#!/usr/bin/env python3
"""Turns benchmark JSONL (desktop bench.py or the app's results.jsonl) into a
Markdown table.

Usage: python3 -I summarize.py results.jsonl [more.jsonl ...]
"""

import json
import sys


def fmt_ms(x):
    return "" if x is None else f"{x * 1000:.0f}"


def main():
    rows = []
    for path in sys.argv[1:]:
        with open(path, encoding="utf-8") as f:
            rows += [json.loads(l) for l in f if l.strip()]

    print(
        "| model | runtime | provider | threads | corpus | load s | "
        "TTFA median ms | TTFA p90 ms | RTF | peak RSS MB | disk MB |"
    )
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    for r in rows:
        if "error" in r:
            print(
                f"| {r.get('model', '?')} | {r.get('runtime', 'sherpa')} | "
                f"{r.get('provider', 'cpu')} | {r.get('threads', '')} | "
                f"{r.get('corpus', '')} | error: {r['error'][:60]} |||||"
            )
            continue
        ttfa = r.get("ttfa_median_s", r.get("synth_median_s"))
        ttfa90 = r.get("ttfa_p90_s", r.get("synth_p90_s"))
        rss = r.get("rss_peak_mb", r.get("rss_max_mb"))
        disk = r.get("disk_bytes")
        print(
            f"| {r['model']} | {r.get('runtime', 'sherpa')} | "
            f"{r.get('provider', 'cpu')} | {r['threads']} | "
            f"{str(r.get('corpus', '')).replace('.txt', '')} | {r['load_s']:.2f} | "
            f"{fmt_ms(ttfa)} | {fmt_ms(ttfa90)} | {r['rtf']:.3f} | "
            f"{rss:.0f} | {'' if disk is None else f'{disk / 1e6:.0f}'} |"
        )


if __name__ == "__main__":
    main()
