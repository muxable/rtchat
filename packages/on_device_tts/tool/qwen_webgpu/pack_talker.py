"""Pack the 28-layer talker, text projection and the 16 feedback embeddings."""

import json
import sys
from pathlib import Path

import numpy as np
import onnx
from onnx import numpy_helper
from pack_predictor import blocks


def pack(root, target):
    layout = {}
    blob = (target/"talker.bin").open("wb")
    def put(key, data):
        data=np.ascontiguousarray(data)
        layout[key]=[blob.tell(),data.nbytes]
        blob.write(data.tobytes())
    def load(name):
        g=onnx.load(root/(name+".onnx")).graph
        weights={i.name:numpy_helper.to_array(i) for i in g.initializer}
        linear=[n for n in g.node if n.op_type=="MatMulNBits"]
        return weights,linear
    def mat(node):
        attrs={a.name:a.i for a in node.attribute}
        if attrs["bits"]!=4 or attrs["block_size"]!=32: raise ValueError(node.name)
        return blocks(*(w[i] for i in node.input[1:4]))
    def emb(base):
        return blocks(*(w[base+k] for k in ("_Q4","_scales","_zero_point")))
    w,nodes=load("talker_cache")
    assert len(nodes)==197
    for layer in range(28):
        terms=nodes[layer*7:layer*7+7]
        for key,subset in [("qkv",terms[:3]),("o",terms[3:4]),("gateUp",terms[4:6]),("down",terms[6:])]:
            put(f"{layer}.{key}",np.concatenate([mat(n) for n in subset]))
        for name in ["input_layernorm","post_attention_layernorm","self_attn.q_norm","self_attn.k_norm"]:
            put(f"{layer}.{name}",w[f"model.layers.{layer}.{name}.weight"])
    put("norm",w["model.norm.weight"])
    put("head",mat(nodes[-1]))
    w,nodes=load("text_embed")
    table=emb("text_embedding.weight")
    for start in range(0,len(table),16384):
        put(f"textTable{start//16384}",table[start:start+16384])
    del table
    for index,n in enumerate(nodes,1):
        put("project"+str(index),mat(n))
        put("bias"+str(index),w[f"text_projection.linear_fc{index}.bias"])
    w,_=load("residual_embed")
    for i in range(16):
        put(f"codec{i}",emb("talker_codec_embedding.weight" if i==0 else f"cp_codec_embedding.{i-1}.weight"))
    blob.close()
    (target/"talker.json").write_text(json.dumps(layout))


if __name__=="__main__":
    pack(Path(sys.argv[1]),Path(sys.argv[2]))
