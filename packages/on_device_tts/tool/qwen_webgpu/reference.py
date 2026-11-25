"""Generate independent predictor logits & greedy IDs using the unmodified ONNX graph."""

import sys
from pathlib import Path

import numpy as np
import onnxruntime as ort

def reference(source, folder):
    opts = ort.SessionOptions()
    opts.intra_op_num_threads = 2
    model = ort.InferenceSession(str(source), opts, providers=["CPUExecutionProvider"])
    rng = np.random.default_rng(314)
    for case, first in enumerate((19, 1024, 2047)):
        state = rng.normal(0, 1, (1, 1024)).astype(np.float32)
        codes = np.zeros((1, 16), np.int64)
        codes[0, 0] = first
        logits = []
        for group in range(1, 16):
            row = model.run(None, {"talker_hidden": state, "codec_ids": codes})[0][0, group-1]
            logits.append(row)
            codes[0, group] = np.argmax(row)
        state.astype("<f4").tofile(folder / f"state{case}.bin")
        codes.astype("<u4").tofile(folder / f"codes{case}.bin")
        np.asarray(logits, dtype="<f4").tofile(folder / f"logits{case}.bin")

if __name__ == "__main__":
    reference(Path(sys.argv[1]), Path(sys.argv[2]))
