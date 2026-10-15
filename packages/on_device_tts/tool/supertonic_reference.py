"""Makes reference tensors for the Kotlin/Swift Supertonic parity tests.

Runs Supertone's own `supertonic` Python package (MIT) with the noise of the
contract's PRNG (see doc/native_contract.md), and writes every intermediate
tensor plus the final audio as little-endian binaries, with a manifest.json
that the platform parity tests read.

Dev tooling only, never shipped. In a scratch virtualenv:

    python -m venv venv && venv/bin/pip install supertonic==1.3.1
    venv/bin/python -I tool/supertonic_reference.py <model dir> <out dir>

<model dir> is a download of the Hugging Face repo Supertone/supertonic-3
(`onnx/` and `voice_styles/`).
"""

import json
import math
import sys
from pathlib import Path
from unittest import mock

import numpy as np
from supertonic import TTS
from supertonic import core

MASK = (1 << 64) - 1


class NoiseGenerator:
    """SplitMix64 words, Box-Muller normals; see doc/native_contract.md."""

    def __init__(self, seed: int):
        self.state = seed & MASK

    def next_u64(self) -> int:
        self.state = (self.state + 0x9E3779B97F4A7C15) & MASK
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)

    def next_double(self) -> float:
        return (self.next_u64() >> 11) * (1.0 / (1 << 53))

    def next_gaussian(self) -> float:
        u1 = self.next_double()
        u2 = self.next_double()
        return math.sqrt(-2.0 * math.log(1.0 - u1)) * math.cos(2.0 * math.pi * u2)

    def randn(self, *shape: int) -> np.ndarray:
        count = int(np.prod(shape))
        values = [self.next_gaussian() for _ in range(count)]
        return np.array(values, dtype=np.float64).astype(np.float32).reshape(shape)


CASES = [
    dict(name="en_chat", text="xQcOW said that was the cleanest clutch I have seen all week, GG!",
         lang="en", voice="M1", speed=1.0, steps=5, seed=1),
    dict(name="en_short", text="Thanks for the follow, Daisy.",
         lang="en", voice="F2", speed=1.25, steps=5, seed=2),
    dict(name="es", text="Hola a todos, ¿cómo están hoy? Bienvenidos al stream.",
         lang="es", voice="F1", speed=1.0, steps=5, seed=3),
    dict(name="ru", text="Привет, чат! Сегодня играем до самого вечера.",
         lang="ru", voice="M3", speed=1.0, steps=5, seed=4),
    dict(name="ko", text="안녕하세요, 오늘 방송에 와 주셔서 감사합니다.",
         lang="ko", voice="F3", speed=1.0, steps=8, seed=5),
]

# Max abs diff allowed per tensor (latent_N use "latent").
TOLERANCES = {"duration": 1e-4, "text": 1e-3, "noise": 1e-6, "latent": 1e-3, "wav": 1e-3}


def main(model_dir: str, out_dir: str) -> None:
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    tts = TTS(model_dir=model_dir, auto_download=False, intra_op_num_threads=2)
    engine = tts.model
    manifest = {"model_dir": str(Path(model_dir).resolve()), "tolerances": TOLERANCES, "cases": []}

    for case in CASES:
        name = case["name"]
        style = tts.get_voice_style(case["voice"])
        tensors = {}

        def save(tensor_name, array, dtype):
            array = np.ascontiguousarray(array, dtype=dtype)
            file = f"{name}_{tensor_name}.bin"
            array.tofile(out / file)
            tensors[tensor_name] = {"file": file, "shape": list(array.shape), "dtype": np.dtype(dtype).name}

        text_ids, text_mask = engine.text_processor([case["text"]], case["lang"])
        save("text_ids", text_ids, "<i8")
        dur, *_ = engine.dp_ort.run(None, {"text_ids": text_ids, "style_dp": style.dp, "text_mask": text_mask})
        dur = dur / case["speed"]
        save("duration", dur, "<f4")
        text_emb, *_ = engine.text_enc_ort.run(
            None, {"text_ids": text_ids, "style_ttl": style.ttl, "text_mask": text_mask})
        save("text_emb", text_emb, "<f4")

        noise = NoiseGenerator(case["seed"])
        with mock.patch.object(core.np.random, "randn", noise.randn):
            xt, latent_mask = engine.sample_noisy_latent(dur)
        save("noise", xt, "<f4")

        steps = case["steps"]
        total_step = np.array([steps], dtype=np.float32)
        for step in range(steps):
            xt, *_ = engine.vector_est_ort.run(None, {
                "noisy_latent": xt, "text_emb": text_emb, "style_ttl": style.ttl,
                "text_mask": text_mask, "latent_mask": latent_mask,
                "current_step": np.array([step], dtype=np.float32), "total_step": total_step,
            })
            save(f"latent_{step}", xt, "<f4")
        wav, *_ = engine.vocoder_ort.run(None, {"latent": xt})
        save("wav", wav, "<f4")

        # Sanity check: the package's own call, with the same noise, agrees.
        with mock.patch.object(core.np.random, "randn", NoiseGenerator(case["seed"]).randn):
            wav_pkg, _ = engine([case["text"]], style, steps, case["speed"], case["lang"])
        assert np.array_equal(wav_pkg, wav), "manual pipeline differs from the package"

        # Trimmed to the predicted duration (computed in float32, like the
        # Java sample and the Kotlin port).
        trim = int(np.float32(engine.sample_rate) * np.float32(dur[0]))
        pcm_file = f"{name}_pcm.f32"
        np.ascontiguousarray(wav[0, :trim], dtype="<f4").tofile(out / pcm_file)

        manifest["cases"].append({**case, "tensors": tensors, "pcm": pcm_file,
                                  "sample_rate": engine.sample_rate})
        print(f"{name}: {text_ids.shape[1]} ids, {dur[0]:.3f} s, latent {xt.shape}, {trim} samples")

    (out / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
