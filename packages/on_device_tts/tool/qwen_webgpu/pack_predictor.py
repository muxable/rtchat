"""Pack the pinned ONNX predictor's constants for single-token WebGPU decoding."""

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import onnx
from onnx import numpy_helper

MODEL = "onnx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice"
REVISION = "18b0bf898d211718bc33082fadc36a448e0cbc0c"


def pack(source, output):
    graph = onnx.load(source).graph
    weights = {t.name: numpy_helper.to_array(t) for t in graph.initializer}
    matrices = {n.name: n for n in graph.node if n.op_type == "MatMulNBits"}
    output.mkdir(parents=True, exist_ok=True)
    layout = {}
    with (output / "predictor.bin").open("wb") as blob:
        def write(name, data):
            data = np.ascontiguousarray(data)
            layout[name] = [blob.tell(), data.nbytes]
            blob.write(data.tobytes())

        # A block contains 32 4-bit values, one FP32 scale and its zero point.
        def blocks(q, scales, zeros):
            scales = scales.reshape(q.shape[0], -1)
            rows, count = scales.shape
            result = np.empty((rows, count, 6), dtype="<u4")
            result[:, :, :4] = q.reshape(rows, count, 16).copy().view("<u4")
            result[:, :, 4] = scales.astype("<f4").view("<u4")
            zeros = zeros.reshape(rows, -1)
            result[:, 0::2, 5] = zeros & 15
            result[:, 1::2, 5] = zeros[:, :count//2] >> 4
            return result

        def matrix(name):
            n = matrices[name]
            attrs = {a.name: a.i for a in n.attribute}
            if attrs["bits"] != 4 or attrs["block_size"] != 32:
                raise ValueError(f"Unexpected quantization for {name}: {attrs}")
            return blocks(*(weights[key] for key in n.input[1:4]))

        for layer in range(5):
            prefix = f"/model/layers.{layer}"
            def projection(name):
                return matrix(f"{prefix}/{name}/MatMul_Q4")
            for key, names in [
                ("qkv", ["self_attn/q_proj", "self_attn/k_proj", "self_attn/v_proj"]),
                ("o", ["self_attn/o_proj"]),
                ("gateUp", ["mlp/gate_proj", "mlp/up_proj"]),
                ("down", ["mlp/down_proj"]),
            ]:
                write(f"{layer}.{key}", np.concatenate([projection(n) for n in names]))
            for key in ["input_layernorm", "post_attention_layernorm",
                        "self_attn.q_norm", "self_attn.k_norm"]:
                write(f"{layer}.{key}", weights[f"cp.model.layers.{layer}.{key}.weight"])
        write("norm", weights["cp.model.norm.weight"])
        for group in range(15):
            write(f"head{group}", matrix(f"/lm_head.{group}/MatMul_Q4"))
            table = "talker_codec_embedding" if group == 0 else f"cp.model.codec_embedding.{group-1}"
            base = table + ".weight"
            write(f"embed{group}", blocks(*(weights[base+k] for k in ("_Q4","_scales","_zero_point"))))
    (output / "layout.json").write_text(json.dumps(layout))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    pack(args.source, args.output)
