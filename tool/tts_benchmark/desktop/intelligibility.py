#!/usr/bin/env python3
"""Round-trip intelligibility check: TTS -> ASR -> word error rate.

A cheap, objective proxy for "does this model produce the right words" (it
catches broken quantization, dropped phonemes and garbage audio). It is not
a naturalness score; listen to the WAVs for that.

Uses the multilingual NeMo Parakeet TDT 0.6b v3 int8 model from the
sherpa-onnx asr-models release as the recognizer.

Usage:
  python3 -I intelligibility.py --models-dir <dir> --asr-dir <parakeet dir> \
      --corpus ../app/assets/corpus/en.txt [--lang en] <model> [<model> ...]
"""

import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bench import build_config, model_kind  # noqa: E402


def norm(text):
    text = text.lower().replace("'", "")
    return re.sub(r"[^\w\s]", " ", text).split()


def wer(ref, hyp):
    d = list(range(len(hyp) + 1))
    for i, r in enumerate(ref, 1):
        prev, d[0] = d[0], i
        for j, h in enumerate(hyp, 1):
            cur = min(d[j] + 1, d[j - 1] + 1, prev + (r != h))
            prev, d[j] = d[j], cur
    return d[len(hyp)], len(ref)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--models-dir", required=True)
    ap.add_argument("--asr-dir", required=True)
    ap.add_argument("--corpus", required=True)
    ap.add_argument("--lang", default="en")
    ap.add_argument("--threads", type=int, default=8)
    ap.add_argument("--wav-dir", default="")
    ap.add_argument("models", nargs="+")
    args = ap.parse_args()

    import sherpa_onnx

    a = args.asr_dir
    asr = sherpa_onnx.OfflineRecognizer.from_transducer(
        encoder=os.path.join(a, "encoder.int8.onnx"),
        decoder=os.path.join(a, "decoder.int8.onnx"),
        joiner=os.path.join(a, "joiner.int8.onnx"),
        tokens=os.path.join(a, "tokens.txt"),
        model_type="nemo_transducer",
        num_threads=args.threads,
    )
    with open(args.corpus, encoding="utf-8") as f:
        lines = [l.strip() for l in f if l.strip()]

    for name in args.models:
        root = os.path.join(args.models_dir, name)
        tts = sherpa_onnx.OfflineTts(
            build_config(sherpa_onnx, root, name, args.threads, "cpu", 1)
        )
        kind = model_kind(name)
        errs = words = 0
        worst = []
        for i, text in enumerate(lines):
            if kind == "supertonic":
                g = sherpa_onnx.GenerationConfig()
                g.extra["lang"] = args.lang
                audio = tts.generate(text, g)
            else:
                audio = tts.generate(text, sid=0, speed=1.0)
            if args.wav_dir:
                d = os.path.join(args.wav_dir, name)
                os.makedirs(d, exist_ok=True)
                sherpa_onnx.write_wave(
                    os.path.join(d, f"{i:02d}.wav"), audio.samples, audio.sample_rate
                )
            s = asr.create_stream()
            s.accept_waveform(audio.sample_rate, audio.samples)
            asr.decode_stream(s)
            hyp = s.result.text
            e, n = wer(norm(text), norm(hyp))
            errs += e
            words += n
            worst.append((e / max(n, 1), text, hyp))
        worst.sort(reverse=True)
        print(
            json.dumps(
                {
                    "model": name,
                    "corpus": os.path.basename(args.corpus),
                    "wer": errs / words,
                    "worst": [{"ref": r, "hyp": h} for _, r, h in worst[:3]],
                },
                ensure_ascii=False,
            )
        )
        sys.stdout.flush()


if __name__ == "__main__":
    main()
