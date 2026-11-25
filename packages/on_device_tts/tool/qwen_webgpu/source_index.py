"""Index byte ranges in the pinned ONNX exports for on-device weight upload."""

import json
import mmap
import sys
from pathlib import Path

import onnx


def varint(data, pos):
    value = shift = 0
    while True:
        byte = data[pos]
        pos += 1
        value |= (byte & 127) << shift
        if byte < 128:
            return value, pos
        shift += 7


def fields(data, start, end):
    pos = start
    while pos < end:
        tag, pos = varint(data, pos)
        wire = tag & 7
        if wire == 2:
            size, pos = varint(data, pos)
            yield tag >> 3, pos, size
            pos += size
        elif wire == 0:
            _, pos = varint(data, pos)
        elif wire in (1, 5):
            pos += 8 if wire == 1 else 4
        else:
            raise ValueError(f"Unknown wire type {wire}")


class Source:
    def __init__(self, root, name):
        self.name = name + ".onnx"
        file = root / self.name
        self.spans = {}
        with (
            file.open("rb") as fp,
            mmap.mmap(fp.fileno(), 0, access=mmap.ACCESS_READ) as data,
        ):
            graph, size = next(
                (p, s) for t, p, s in fields(data, 0, len(data)) if t == 7
            )
            for tag, pos, size in fields(data, graph, graph + size):
                if tag == 5:
                    entry = {t: (p, s) for t, p, s in fields(data, pos, pos + size)}
                    start, n = entry[8]
                    self.spans[data[start : start + n].decode()] = entry[9]
        graph = onnx.load(file).graph
        self.shapes = {v.name: list(v.dims) for v in graph.initializer}
        self.types = {v.name: v.data_type for v in graph.initializer}
        self.nodes = list(graph.node)
        self.linear = [n for n in self.nodes if n.op_type == "MatMulNBits"]

    def raw(self, key):
        offset, size = self.spans[key]
        assert self.types[key] in (1, 7)
        return ["f32" if self.types[key] == 1 else "i64", self.name, offset, size]

    def q4(self, names, start=0, stop=None):
        q, s, z = names
        rows = self.shapes[q][0]
        count = self.spans[s][1] // (4 * rows)
        stop = rows if stop is None else min(stop, rows)
        assert count % 2 == 0 and self.spans[q][1] == rows * count * 16
        assert self.spans[z][1] == rows * count // 2
        return [
            "q4",
            self.name,
            (stop - start) * count,
            self.spans[q][0] + start * count * 16,
            self.spans[s][0] + start * count * 4,
            self.spans[z][0] + start * count // 2,
        ]

    def embedding(self, base, *bounds):
        return self.q4(
            [base + suffix for suffix in ("_Q4", "_scales", "_zero_point")], *bounds
        )


def index(root, plan, dest):
    stages = {}
    for target, filename, layers, prefix in [
        ("talker", "talker_cache", 28, "model"),
        ("predictor", "code_predictor", 5, "cp.model"),
    ]:
        src = Source(root, filename)
        weights = stages[target] = {}
        for i in range(layers):
            proj = src.linear[i * 7 : i * 7 + 7]
            for label, nodes in [
                ("qkv", proj[:3]),
                ("o", proj[3:4]),
                ("gateUp", proj[4:6]),
                ("down", proj[6:]),
            ]:
                weights[f"{i}.{label}"] = [src.q4(n.input[1:4]) for n in nodes]
            for suffix in (
                "input_layernorm",
                "post_attention_layernorm",
                "self_attn.q_norm",
                "self_attn.k_norm",
            ):
                weights[f"{i}.{suffix}"] = [
                    src.raw(f"{prefix}.layers.{i}.{suffix}.weight")
                ]
        weights["norm"] = [src.raw(prefix + ".norm.weight")]
        if target == "talker":
            weights["head"] = [src.q4(src.linear[-1].input[1:4])]
        else:
            byname = {n.name: n for n in src.linear}
            for j in range(15):
                weights[f"head{j}"] = [
                    src.q4(byname[f"/lm_head.{j}/MatMul_Q4"].input[1:4])
                ]
                base = (
                    "talker_codec_embedding"
                    if j == 0
                    else f"cp.model.codec_embedding.{j - 1}"
                )
                weights[f"embed{j}"] = [src.embedding(base + ".weight")]
    src = Source(root, "text_embed")
    talker = stages["talker"]
    base = "text_embedding.weight"
    for start in range(0, src.shapes[base + "_Q4"][0], 16384):
        talker[f"textTable{start // 16384}"] = [
            src.embedding(base, start, start + 16384)
        ]
    for i, n in enumerate(src.linear, 1):
        talker[f"project{i}"] = [src.q4(n.input[1:4])]
        talker[f"bias{i}"] = [src.raw(f"text_projection.linear_fc{i}.bias")]
    src = Source(root, "residual_embed")
    talker["codecTables"] = [src.embedding("talker_codec_embedding.weight")] + [
        src.embedding(f"cp_codec_embedding.{i}.weight") for i in range(15)
    ]
    src = Source(root, "tok_decoder")
    nodes = {n.output[0]: n for n in src.nodes}
    decoder = stages["decoder"] = {}
    for key in plan["layout"]:
        if key in src.spans:
            decoder[key] = [src.raw(key)]
        else:
            op = nodes[key]
            assert op.op_type == "Div"
            a, b = op.input
            assert src.shapes[a] == [2048, 256] and src.shapes[b] == [2048, 1]
            decoder[key] = [
                [
                    "normalize",
                    src.name,
                    src.spans[a][0],
                    src.spans[a][1],
                    src.spans[b][0],
                    256,
                ]
            ]
    dest.write_text(json.dumps(stages, separators=(",", ":")) + "\n")


if __name__ == "__main__":
    index(
        Path(sys.argv[1]), json.loads(Path(sys.argv[2]).read_text()), Path(sys.argv[3])
    )
