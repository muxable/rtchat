#!/usr/bin/env python3
"""Desktop benchmark for sherpa-onnx TTS models.

Runs each (model, threads, provider) combination in a fresh subprocess so
that load time and peak RSS are measured in isolation, synthesizes every
message of a corpus, and writes one JSON line per combination.

Usage:
  python3 -I bench.py --models-dir ~/.cache/rtchat-tts-spike/models \
      --corpus ../app/assets/corpus/en.txt --threads 1 2 4 --out results.jsonl \
      kitten-nano-en-v0_8-int8 kokoro-int8-multi-lang-v1_1

Model directories are untrusted data: run with `python3 -I` and keep this
script outside of the models directory.
"""

import argparse
import json
import os
import resource
import statistics
import subprocess
import sys
import time


def _find(root, *names):
    for dirpath, _, files in os.walk(root):
        for n in names:
            if n in files:
                return os.path.join(dirpath, n)
    return ""


def _find_dir(root, name):
    for dirpath, dirs, _ in os.walk(root):
        if name in dirs:
            return os.path.join(dirpath, name)
    return ""


def model_kind(name):
    if name.startswith("kokoro"):
        return "kokoro"
    if name.startswith("kitten"):
        return "kitten"
    if "supertonic" in name:
        return "supertonic"
    if name.startswith("vits") or "piper" in name:
        return "vits"
    if name.startswith("matcha"):
        return "matcha"
    raise ValueError(f"unknown model type for {name}")


def build_config(sherpa_onnx, root, name, threads, provider, max_sentences):
    kind = model_kind(name)
    m = sherpa_onnx.OfflineTtsModelConfig(num_threads=threads, provider=provider)
    if kind == "kokoro":
        lex = ",".join(
            p for p in (_find(root, "lexicon-us-en.txt"), _find(root, "lexicon-zh.txt")) if p
        )
        m.kokoro = sherpa_onnx.OfflineTtsKokoroModelConfig(
            model=_find(root, "model.int8.onnx", "model.onnx"),
            voices=_find(root, "voices.bin"),
            tokens=_find(root, "tokens.txt"),
            lexicon=lex,
            data_dir=_find_dir(root, "espeak-ng-data"),
            dict_dir=_find_dir(root, "dict"),
        )
    elif kind == "kitten":
        m.kitten = sherpa_onnx.OfflineTtsKittenModelConfig(
            model=_find(root, "model.int8.onnx", "model.fp32.onnx", "model.fp16.onnx", "model.onnx"),
            voices=_find(root, "voices.bin"),
            tokens=_find(root, "tokens.txt"),
            data_dir=_find_dir(root, "espeak-ng-data"),
        )
    elif kind == "vits":
        onnx = [
            os.path.join(d, f)
            for d, _, fs in os.walk(root)
            for f in fs
            if f.endswith(".onnx")
        ]
        m.vits = sherpa_onnx.OfflineTtsVitsModelConfig(
            model=onnx[0],
            tokens=_find(root, "tokens.txt"),
            data_dir=_find_dir(root, "espeak-ng-data"),
        )
    elif kind == "supertonic":
        m.supertonic = sherpa_onnx.OfflineTtsSupertonicModelConfig(
            duration_predictor=_find(root, "duration_predictor.int8.onnx", "duration_predictor.onnx"),
            text_encoder=_find(root, "text_encoder.int8.onnx", "text_encoder.onnx"),
            vector_estimator=_find(root, "vector_estimator.int8.onnx", "vector_estimator.onnx"),
            vocoder=_find(root, "vocoder.int8.onnx", "vocoder.onnx"),
            tts_json=_find(root, "tts.json"),
            unicode_indexer=_find(root, "unicode_indexer.bin"),
            voice_style=_find(root, "voice.bin"),
        )
    return sherpa_onnx.OfflineTtsConfig(model=m, max_num_sentences=max_sentences)


def dir_size(root):
    total = 0
    for d, _, fs in os.walk(root):
        for f in fs:
            total += os.path.getsize(os.path.join(d, f))
    return total


def run_single(args):
    import sherpa_onnx

    root = os.path.join(args.models_dir, args.single)
    with open(args.corpus, encoding="utf-8") as f:
        lines = [l.strip() for l in f if l.strip()]

    rss_before = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    t0 = time.perf_counter()
    cfg = build_config(sherpa_onnx, root, args.single, args.threads[0], args.provider, args.max_sentences)
    if not cfg.validate():
        raise SystemExit(f"invalid config for {args.single}")
    tts = sherpa_onnx.OfflineTts(cfg)
    load_s = time.perf_counter() - t0
    rss_loaded = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss

    kind = model_kind(args.single)

    def gen(text, cb):
        if kind == "supertonic":
            g = sherpa_onnx.GenerationConfig()
            g.sid = args.sid
            g.num_steps = args.num_steps
            g.extra["lang"] = args.lang
            return tts.generate(text, g, callback=cb)
        return tts.generate(text, sid=args.sid, speed=1.0, callback=cb)

    # Warm up (first inference allocates arenas, not representative).
    gen(lines[0], None)

    per = []
    for text in lines:
        chunks = []
        start = time.perf_counter()

        def cb(samples, progress):
            chunks.append((time.perf_counter() - start, len(samples)))
            return 1

        audio = gen(text, cb)
        total = time.perf_counter() - start
        dur = len(audio.samples) / audio.sample_rate
        per.append(
            {
                "text": text,
                "synth_s": total,
                "first_chunk_s": chunks[0][0] if chunks else total,
                "num_chunks": len(chunks),
                "audio_s": dur,
            }
        )
        if args.save_wav_dir and text == lines[-1]:
            os.makedirs(args.save_wav_dir, exist_ok=True)
            sherpa_onnx.write_wave(
                os.path.join(args.save_wav_dir, f"{args.single}.wav"),
                audio.samples,
                audio.sample_rate,
            )

    peak_kb = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    synth = [p["synth_s"] for p in per]
    first = [p["first_chunk_s"] for p in per]
    q = statistics.quantiles(synth, n=10)
    result = {
        "model": args.single,
        "kind": kind,
        "threads": args.threads[0],
        "provider": args.provider,
        "corpus": os.path.basename(args.corpus),
        "messages": len(per),
        "sample_rate": tts.sample_rate,
        "num_speakers": tts.num_speakers,
        "disk_bytes": dir_size(root),
        "load_s": load_s,
        "rss_base_mb": rss_before / 1024,
        "rss_after_load_mb": rss_loaded / 1024,
        "rss_peak_mb": peak_kb / 1024,
        "ttfa_median_s": statistics.median(first),
        "ttfa_p90_s": statistics.quantiles(first, n=10)[8],
        "synth_median_s": statistics.median(synth),
        "synth_p90_s": q[8],
        "rtf": sum(synth) / sum(p["audio_s"] for p in per),
        "audio_total_s": sum(p["audio_s"] for p in per),
    }
    if args.per_message:
        result["per_message"] = per
    print(json.dumps(result))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--models-dir", required=True)
    ap.add_argument("--corpus", required=True)
    ap.add_argument("--threads", type=int, nargs="+", default=[1, 2, 4])
    ap.add_argument("--provider", default="cpu")
    ap.add_argument("--sid", type=int, default=0)
    ap.add_argument("--lang", default="en", help="supertonic language")
    ap.add_argument("--num-steps", type=int, default=5, help="supertonic flow steps")
    ap.add_argument("--max-sentences", type=int, default=1)
    ap.add_argument("--per-message", action="store_true")
    ap.add_argument("--save-wav-dir", default="")
    ap.add_argument("--out", default="-")
    ap.add_argument("--single", help=argparse.SUPPRESS)
    ap.add_argument("models", nargs="*")
    args = ap.parse_args()

    if args.single:
        run_single(args)
        return

    out = sys.stdout if args.out == "-" else open(args.out, "a", encoding="utf-8")
    for model in args.models:
        for t in args.threads:
            cmd = [
                sys.executable, "-I", os.path.abspath(__file__),
                "--models-dir", args.models_dir, "--corpus", args.corpus,
                "--threads", str(t), "--provider", args.provider,
                "--sid", str(args.sid), "--lang", args.lang,
                "--num-steps", str(args.num_steps),
                "--max-sentences", str(args.max_sentences),
                "--single", model,
            ]
            if args.per_message:
                cmd.append("--per-message")
            if args.save_wav_dir:
                cmd += ["--save-wav-dir", args.save_wav_dir]
            # Pin to t cores so a thread count of N really means N cores.
            cmd = ["taskset", "-c", f"0-{t - 1}"] + cmd
            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode != 0:
                print(f"FAILED {model} t={t}: {res.stderr[-2000:]}", file=sys.stderr)
                continue
            line = res.stdout.strip().splitlines()[-1]
            out.write(line + "\n")
            out.flush()
            r = json.loads(line)
            print(
                f"{model:48s} t={t} load={r['load_s']:.2f}s rss={r['rss_peak_mb']:.0f}MB "
                f"ttfa_med={r['ttfa_median_s'] * 1000:.0f}ms p90={r['ttfa_p90_s'] * 1000:.0f}ms rtf={r['rtf']:.3f}",
                file=sys.stderr,
            )


if __name__ == "__main__":
    main()
