"""Time the exporter's complete CPU pipeline against the saved codec IDs and PCM."""
import json
import sys
import time
from pathlib import Path
from unittest.mock import patch

import numpy as np
import onnxruntime as ort

from speech_reference import pipeline


def benchmark(root, fixtures):
    options = ort.SessionOptions()
    options.intra_op_num_threads = 2
    options.inter_op_num_threads = 1
    options.add_session_config_entry("session.intra_op.allow_spinning", "0")
    with patch.object(ort, "SessionOptions", return_value=options):
        engine = pipeline(root)
    if engine.provider != "CPUExecutionProvider":
        raise ValueError(engine.provider)
    cases = json.loads((fixtures / "utterances.json").read_text())
    rows = []
    for iteration in range(4):
        for i, case in enumerate(cases):
            expected = np.fromfile(fixtures / f"pcm{i}.bin", dtype="<f4")
            cpu, wall = time.process_time(), time.perf_counter()
            codes = engine.generate(case["text"], language="english", speaker="ryan",
                                    max_new_tokens=128, do_sample=False, sub_do_sample=False, verbose=False)
            wave = engine.decode_chunked(codes[None]).reshape(-1)
            elapsed, spent = time.perf_counter() - wall, time.process_time() - cpu
            if codes.tolist() != case["codes"] or wave.shape != expected.shape or not np.allclose(
                    wave, expected, rtol=0, atol=0.003):
                raise ValueError(f"CPU reference mismatch for {case['text']}")
            if iteration:
                rows.append(dict(text=case["text"], wall_ms=1000*elapsed, cpu_ms=1000*spent))
    return rows


if __name__ == "__main__":
    model, fixtures, output = map(Path, sys.argv[1:])
    rows = benchmark(model, fixtures)
    output.write_text(json.dumps(rows))
    print("ORT CPU", ort.__version__, rows, flush=True)
