#!/usr/bin/env python3
"""Checks what the sherpa-onnx generation callback yields for each model type.

For a few texts (one short sentence, a long single sentence, and a
multi-sentence message) it records how many times the callback fires, how
many samples each call carries, and the time to the first chunk versus the
full synthesis. It also runs the app-side alternative: splitting the text on
clause punctuation and synthesizing each piece separately.

Usage:
  python3 -I streaming.py --models-dir <dir> --threads 2 <model> [<model> ...]
"""

import argparse
import json
import os
import re
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bench import build_config, model_kind  # noqa: E402

TEXTS = {
    "short": "Daisy said POGGERS that clutch",
    "long_one_sentence": (
        "Rook said okay that boss fight was actually really hard, respect for "
        "not giving up after twelve attempts, and honestly the second phase "
        "with the falling rocks looked impossible to dodge"
    ),
    "three_sentences": (
        "Sol said is the giveaway still running? I want to enter. "
        "I've been watching since the start of the stream!"
    ),
}

RU_TEXTS = {
    "short": "Привет чат",
    "three_sentences": "Не ходи туда. Там босс! Он ещё жив, я видел.",
}


def clause_split(text):
    parts = re.split(r"(?<=[.!?,;:])\s+", text)
    return [p for p in parts if p.strip()]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--models-dir", required=True)
    ap.add_argument("--threads", type=int, default=2)
    ap.add_argument("--lang", default="en")
    ap.add_argument("models", nargs="+")
    args = ap.parse_args()

    import sherpa_onnx

    texts = RU_TEXTS if args.lang == "ru" else TEXTS
    for name in args.models:
        root = os.path.join(args.models_dir, name)
        tts = sherpa_onnx.OfflineTts(
            build_config(sherpa_onnx, root, name, args.threads, "cpu", 1)
        )
        kind = model_kind(name)

        def gen(text, cb):
            if kind == "supertonic":
                g = sherpa_onnx.GenerationConfig()
                g.extra["lang"] = args.lang
                return tts.generate(text, g, callback=cb)
            return tts.generate(text, sid=0, speed=1.0, callback=cb)

        gen("warm up", None)
        for label, text in texts.items():
            calls = []
            start = time.perf_counter()

            def cb(samples, progress):
                calls.append(
                    {
                        "t_s": round(time.perf_counter() - start, 4),
                        "samples": len(samples),
                        "progress": round(float(progress), 3),
                    }
                )
                return 1

            audio = gen(text, cb)
            total = time.perf_counter() - start

            # App-side chunking: synthesize clause by clause; the first clause
            # can start playing as soon as it is ready.
            pieces = clause_split(text)
            t0 = time.perf_counter()
            first_piece = None
            for p in pieces:
                gen(p, None)
                if first_piece is None:
                    first_piece = time.perf_counter() - t0
            print(
                json.dumps(
                    {
                        "model": name,
                        "kind": kind,
                        "threads": args.threads,
                        "text": label,
                        "audio_s": round(len(audio.samples) / audio.sample_rate, 3),
                        "full_s": round(total, 4),
                        "callbacks": calls,
                        "first_callback_s": calls[0]["t_s"] if calls else None,
                        "clauses": len(pieces),
                        "first_clause_s": round(first_piece, 4),
                    }
                )
            )
            sys.stdout.flush()


if __name__ == "__main__":
    main()
