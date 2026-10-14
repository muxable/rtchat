"""Reference outputs for the Swift Supertonic 3 port.

Runs the official `supertonic` PyPI package (CPU) with the noise replaced by
the cross-platform xorshift64* + Box-Muller generator, and writes a small
JSON fixture for the XCTests. Development tooling only; nothing ships it.

    python3 -m venv venv && venv/bin/pip install supertonic==1.3.1
    venv/bin/python -I make_parity_fixture.py <supertonic-3 dir> \\
        ../Tests/OnDeviceTtsCoreTests/Fixtures/supertonic3_parity.json

<supertonic-3 dir> is a download of huggingface.co/Supertone/supertonic-3 at
revision 3cadd1ee6394adea1bd021217a0e650ede09a323. The "gaussian" values are
rounded to float32, as the generator's output is. tool/supertonic_reference.py
(at the package root) dumps every intermediate tensor instead, for debugging.
"""

import hashlib
import json
import math
import sys

import numpy as np
import supertonic.core as core
from supertonic.loader import load_model, load_voice_style_from_json_file

MASK64 = (1 << 64) - 1


class Noise:
    """SplitMix64 words, Box-Muller normals (cosine branch only); see
    doc/native_contract.md."""

    def __init__(self, seed: int):
        self.s = seed & MASK64

    def next_u64(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK64
        return z ^ (z >> 31)

    def uniform(self):
        return (self.next_u64() >> 11) * (1.0 / 9007199254740992.0)

    def gaussian(self):
        u1 = self.uniform()
        u2 = self.uniform()
        return math.sqrt(-2.0 * math.log(1.0 - u1)) * math.cos(2.0 * math.pi * u2)

    def fill(self, n):
        return np.array([self.gaussian() for _ in range(n)], dtype=np.float64).astype(np.float32)


def main():
    model_dir, out = sys.argv[1], sys.argv[2]
    model = load_model(model_dir, False, 2, 1, "supertonic-3")
    tp = model.text_processor

    noise_holder = {}

    def sample_noisy_latent(self, duration):
        bsz = len(duration)
        wav_len_max = duration.max() * self.sample_rate
        wav_lengths = (duration * self.sample_rate).astype(np.int64)
        chunk_size = self.base_chunk_size * self.chunk_compress_factor
        latent_len = ((wav_len_max + chunk_size - 1) / chunk_size).astype(np.int32)
        latent_dim = self.ldim * self.chunk_compress_factor
        gen = noise_holder["gen"]
        noisy = gen.fill(bsz * latent_dim * int(latent_len)).reshape(bsz, latent_dim, int(latent_len))
        latent_mask = core.get_latent_mask(wav_lengths, self.base_chunk_size, self.chunk_compress_factor)
        return noisy * latent_mask, latent_mask

    core.Supertonic.sample_noisy_latent = sample_noisy_latent

    fixture = {
        "generator": "SplitMix64 + Box-Muller (see doc/native_contract.md)",
        "reference": "supertonic PyPI 1.3.1, onnxruntime CPU",
        "noise": {},
        "preprocess": [],
        "synthesis": [],
    }

    for seed in [0, 42, -1]:
        g = Noise(seed)
        fixture["noise"][str(seed)] = {
            "u64": [str(g.next_u64()) for _ in range(4)],
        }
        g = Noise(seed)
        fixture["noise"][str(seed)]["gaussian"] = [float(v) for v in g.fill(8)]

    pre_cases = [
        ("Hello, world", "en"),
        ("Café — naïve “quotes” and ‘single’ ones", "en"),
        ("xXslayerXx said POGGERS 😂🔥 that clutch!!", "en"),
        ("email me @ home e.g., now _now_ [ok] | a/b #tag", "en"),
        ("Hello  ,  world .  How are you ?", "en"),
        ("안녕하세요 반갑습니다", "ko"),
        ("Привет, как дела", "ru"),
        ("ﬁne ① ＡＢＣ", "es"),
        ("Он сказал ``да'' и \"\"нет\"\"", "na"),
    ]
    for text, lang in pre_cases:
        processed = tp._preprocess_text(text, lang)
        ids, mask = tp([text], lang)
        fixture["preprocess"].append(
            {"text": text, "lang": lang, "processed": processed, "ids": ids[0].tolist()}
        )

    cases = [
        ("Hello! This is a test of the native speech engine.", "en", "F1", 1234),
        ("xXslayerXx said that clutch was absolutely insane, wow.", "en", "M1", 99),
        ("Привет! Это проверка синтеза речи на устройстве.", "ru", "F2", 7),
    ]
    stride = 251
    for text, lang, voice, seed in cases:
        style = load_voice_style_from_json_file(f"{model_dir}/voice_styles/{voice}.json")
        noise_holder["gen"] = Noise(seed)
        wav, dur = model([text], style, 5, 1.0, lang)
        wav = wav[0]
        n = int(model.sample_rate * float(dur[0]))
        trimmed = wav[:n]
        fixture["synthesis"].append(
            {
                "text": text,
                "lang": lang,
                "voice": voice,
                "seed": seed,
                "steps": 5,
                "speed": 1.0,
                "sampleRate": model.sample_rate,
                "duration": float(dur[0]),
                "numSamples": n,
                "rms": float(np.sqrt(np.mean(trimmed.astype(np.float64) ** 2))),
                "stride": stride,
                "samples": [round(float(v), 6) for v in trimmed[::stride]],
                "sha256_int16": hashlib.sha256(
                    (np.clip(trimmed, -1, 1) * 32767).astype(np.int16).tobytes()
                ).hexdigest(),
            }
        )
        print(text, lang, voice, float(dur[0]), n, len(wav), file=sys.stderr)

    with open(out, "w") as f:
        json.dump(fixture, f, ensure_ascii=False, separators=(",", ":"))


if __name__ == "__main__":
    main()
