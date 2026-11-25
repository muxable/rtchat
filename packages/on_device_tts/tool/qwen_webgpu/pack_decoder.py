"""Lower the fixed-shape 25-frame Qwen ONNX waveform decoder to WebGPU."""

import json
import math
import sys
from pathlib import Path

import numpy as np
import onnx
from onnx import numpy_helper


def coord(shape, axis, idx="i"):
    return f"(({idx}/{math.prod(shape[axis + 1 :])}u)%{shape[axis]}u)"


def address(shape, coords):
    return (
        "("
        + "+".join(f"({c})*{math.prod(shape[i + 1 :])}u" for i, c in enumerate(coords))
        + ")"
        if coords
        else "0u"
    )


def broadcast(source, target, idx="i"):
    if source == target:
        return idx
    offset = len(target) - len(source)
    return address(
        source,
        [
            "0u" if d == 1 else coord(target, j + offset, idx)
            for j, d in enumerate(source)
        ],
    )


def lower(op, shapes, out, attrs, arrays):
    """Return WGSL and dispatch geometry. Each input is one storage binding."""
    count = math.prod(out)
    fields = "".join(
        f"@group(0) @binding({j}) var<storage,read> a{j}:array<f32>;\n"
        for j in range(len(shapes))
    )
    fields += (
        f"@group(0) @binding({len(shapes)}) var<storage,read_write> y:array<f32>;\n"
    )

    def get(j):
        return f"a{j}[{broadcast(shapes[j], out)}]"

    def simple(body):
        groups = (count + 127) // 128
        stride = min(groups, 65535)
        return (
            fields
            + f"""@compute @workgroup_size(128)
fn main(@builtin(global_invocation_id) id:vec3u){{
let i=id.x+id.y*{stride * 128}u;if(i>={count}u){{return;}}
{body}
}}""",
            [stride, (groups + stride - 1) // stride, 1],
        )

    if op in (
        "Add",
        "Mul",
        "Div",
        "Pow",
        "Sqrt",
        "Reciprocal",
        "Neg",
        "Sin",
        "Sigmoid",
        "Clip",
        "Gelu",
    ):
        x = get(0)
        if op in ("Add", "Mul", "Div"):
            expr = x + {"Add": "+", "Mul": "*", "Div": "/"}[op] + get(1)
        elif op == "Pow":
            expr = (
                f"pow({x},{get(1)})"
                if arrays[1] is None or arrays[1].size != 1 or arrays[1].item() != 2
                else f"{x}*{x}"
            )
        elif op == "Sqrt":
            expr = f"sqrt({x})"
        elif op == "Reciprocal":
            expr = f"1.0/{x}"
        elif op == "Neg":
            expr = f"-{x}"
        elif op == "Sin":
            expr = f"sin({x})"
        elif op == "Sigmoid":
            expr = f"1.0/(1.0+exp(-{x}))"
        elif op == "Clip":
            expr = f"max({x},{get(1)})"
            if len(shapes) == 3:
                expr = f"min({expr},{get(2)})"
        elif op == "Gelu":
            return simple(f"""let z={x}*0.70710678118;let t=1.0/(1.0+0.3275911*abs(z));
let p=(((((1.061405429*t-1.453152027)*t)+1.421413741)*t-0.284496736)*t+0.254829592)*t;
y[i]=0.5*{x}*(1.0+sign(z)*(1.0-p*exp(-z*z)));""")
        return simple("y[i]=" + expr + ";")
    if op == "Transpose":
        perm = attrs["perm"]
        return simple(
            "y[i]=a0["
            + address(shapes[0], [coord(out, perm.index(j)) for j in range(len(out))])
            + "];"
        )
    if op == "Slice":
        src = shapes[0]
        coords = [coord(out, j) for j in range(len(out))]
        starts = arrays[1].flatten()
        ends = arrays[2].flatten()
        axes = arrays[3].flatten() if len(arrays) > 3 else range(len(starts))
        steps = arrays[4].flatten() if len(arrays) > 4 else [1] * len(starts)
        for start, end, axis, step in zip(starts, ends, axes, steps):
            lo, _, inc = slice(int(start), int(end), int(step)).indices(src[axis])
            coords[axis] = f"u32({lo}+i32({coords[axis]})*{inc})"
        return simple("y[i]=a0[" + address(src, coords) + "];")
    if op == "Gather":
        axis = attrs.get("axis", 0)
        if axis != 0:
            raise ValueError(f"Unexpected gather axis {axis}")
        width = math.prod(shapes[0][1:])
        return simple(f"y[i]=a0[u32(a1[i/{width}u])*{width}u+i%{width}u];")
    if op == "Concat":
        axis = attrs["axis"] % len(out)
        after = math.prod(out[axis + 1 :])
        start = 0
        parts = []
        for j, s in enumerate(shapes):
            end = start + s[axis]
            parts.append(
                f"if(c<{end}u){{y[i]=a{j}[(outer*{s[axis]}u+c-{start}u)*{after}u+i%{after}u];return;}}"
            )
            start = end
        return simple(
            f"let c={coord(out, axis)};let outer=i/{after * out[axis]}u;"
            + "".join(parts)
        )
    if op in ("LayerNormalization", "Softmax", "ReduceMean"):
        src = shapes[0]
        width = src[-1]
        outer = math.prod(src[:-1])
        axis = int(arrays[1].item()) if op == "ReduceMean" else attrs.get("axis", -1)
        if axis % len(src) != len(src) - 1:
            raise ValueError(f"Unexpected {op} axis")
        # One workgroup reduces a row. Keep intermediate reductions synchronized.
        fields += "var<workgroup> scratch:array<f32,64>;\n"

        def reduce(expr, combine, init):
            return f"""{{var acc:f32={init}; for(var j=lane;j<{width}u;j+=64u){{acc={expr};}}
scratch[lane]=acc;workgroupBarrier();
for(var s=32u;s>0u;s=s>>1u){{if(lane<s){{scratch[lane]={combine};}}workgroupBarrier();}}}}"""

        sumop = "scratch[lane]+scratch[lane+s]"
        if op == "Softmax":
            body = reduce(
                "max(acc,a0[base+j])",
                "max(scratch[lane],scratch[lane+s])",
                "-3.402823e38",
            )
            body += "let mx=scratch[0];workgroupBarrier();" + reduce(
                "acc+exp(a0[base+j]-mx)", sumop, "0.0"
            )
            body += f"for(var j=lane;j<{width}u;j+=64u){{y[base+j]=exp(a0[base+j]-mx)/scratch[0];}}"
        else:
            body = (
                reduce("acc+a0[base+j]", sumop, "0.0")
                + f"let mean=scratch[0]/{width}.0;"
            )
            if op == "ReduceMean":
                body += "if(lane==0u){y[g.x]=mean;}"
            else:
                body += "workgroupBarrier();" + reduce(
                    "acc+(a0[base+j]-mean)*(a0[base+j]-mean)", sumop, "0.0"
                )
                body += f"let inv=inverseSqrt(scratch[0]/{width}.0+{attrs['epsilon']});for(var j=lane;j<{width}u;j+=64u){{y[base+j]=(a0[base+j]-mean)*inv*a1[j]+a2[j];}}"
        return (
            fields
            + f"@compute @workgroup_size(64) fn main(@builtin(workgroup_id) g:vec3u,@builtin(local_invocation_index) lane:u32){{let base=g.x*{width}u;{body}}}",
            [outer, 1, 1],
        )
    if op == "MatMul":
        a, b = shapes
        m, k = a[-2:]
        n = b[-1]
        batch = math.prod(out[:-2])
        ao = broadcast(a[:-2], out[:-2], "g.z")
        bo = broadcast(b[:-2], out[:-2], "g.z")
        code = f"""
var<workgroup> aa:array<f32,256>;var<workgroup> bb:array<f32,256>;
@compute @workgroup_size(16,16) fn main(@builtin(workgroup_id) g:vec3u,@builtin(local_invocation_id) t:vec3u){{
let row=g.y*16u+t.y;let col=g.x*16u+t.x;let lane=t.y*16u+t.x;var acc=0.0;
for(var s=0u;s<{k}u;s+=16u){{
aa[lane]=0.0;bb[lane]=0.0;
if(row<{m}u && s+t.x<{k}u){{aa[lane]=a0[({ao}*{m}u+row)*{k}u+s+t.x];}}
if(col<{n}u && s+t.y<{k}u){{bb[lane]=a1[({bo}*{k}u+s+t.y)*{n}u+col];}}
workgroupBarrier();for(var j=0u;j<16u;j++){{acc+=aa[t.y*16u+j]*bb[j*16u+t.x];}}workgroupBarrier();
}}if(row<{m}u && col<{n}u){{y[(g.z*{m}u+row)*{n}u+col]=acc;}}}}"""
        return fields + code, [(n + 15) // 16, (m + 15) // 16, batch]
    if op in ("Conv", "ConvTranspose"):
        _, channels, width = shapes[0]
        _, filters, length = out
        kernel = shapes[1][2]
        groups = attrs.get("group", 1)
        stride = attrs["strides"][0]
        dilation = attrs["dilations"][0]
        pad = attrs["pads"][0]
        per = channels // groups
        pos = (
            f"i32(t*{stride}u+k*{dilation}u)-{pad}"
            if op == "Conv"
            else f"i32(t)+{pad}-i32(k*{dilation}u)"
        )
        ix = f"u32(p)" if op == "Conv" else f"u32(p)/{stride}u"
        wi = (
            f"(f*{per}u+c)*{kernel}u+k"
            if op == "Conv"
            else f"(ic*{filters // groups}u+f%{filters // groups}u)*{kernel}u+k"
        )
        extra = f" && u32(p)%{stride}u==0u" if op == "ConvTranspose" else ""
        init = "a2[f]" if len(shapes) == 3 else "0.0"
        return simple(f"""let t=i%{length}u;let f=i/{length}u;var acc={init};
for(var k=0u;k<{kernel}u;k++){{let p={pos};if(p>=0 && {ix}<{width}u{extra}){{
for(var c=0u;c<{per}u;c++){{let ic=f/{filters // groups}u*{per}u+c;acc+=a0[ic*{width}u+{ix}]*a1[{wi}];}}
}}}}y[i]=acc;""")
    raise ValueError(f"Unsupported decoder operation {op}")


def pack(source, target):
    model = onnx.load(source)
    graph = model.graph
    dims = {
        v.name: [d.dim_value for d in v.type.tensor_type.shape.dim]
        for v in [*graph.input, *graph.output, *graph.value_info]
    }
    const = {i.name: numpy_helper.to_array(i) for i in graph.initializer}
    dims.update({k: list(v.shape) for k, v in const.items()})
    layout = {}
    shaders = []
    ops = []
    aliases = {}

    def real(name):
        return aliases.get(name, name)

    with (target / "decoder.bin").open("wb") as blob:
        for node in graph.node:
            typ = node.op_type
            out = node.output[0]
            inp = [real(k) for k in node.input if k]
            if typ in ("Squeeze", "Reshape"):
                aliases[out] = inp[0]
                continue
            attrs = {a.name: onnx.helper.get_attribute_value(a) for a in node.attribute}
            shapes = [dims[k] for k in node.input if k]
            arrays = [const.get(k) for k in inp]
            # These static codebook normalizations can be resolved once at pack time.
            if typ == "Div" and all(a is not None for a in arrays):
                const[out] = arrays[0] / arrays[1]
                continue
            code, dispatch = lower(typ, shapes, dims[out], attrs, arrays)
            if code not in shaders:
                shaders.append(code)
            for name in inp:
                if name in const and name not in layout:
                    data = const[name].astype("<f4")
                    layout[name] = [blob.tell(), data.nbytes]
                    blob.write(data.tobytes())
            ops.append([shaders.index(code), dispatch, inp, out, math.prod(dims[out])])
    plan = dict(
        layout=layout,
        ops=ops,
        shaders=shaders,
        input=graph.input[0].name,
        output=real(graph.output[0].name),
    )
    (target / "decoder.json").write_text(json.dumps(plan, separators=(",", ":")))


if __name__ == "__main__":
    pack(Path(sys.argv[1]), Path(sys.argv[2]))
