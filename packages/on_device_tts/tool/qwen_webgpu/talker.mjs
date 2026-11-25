import * as k from "./kernels.mjs";

const read = (i, name, t = "f32") =>
  `@group(0) @binding(${i}) var<storage,read> ${name}:array<${t}>;\n`;
const write = (i, name, t = "f32") =>
  `@group(0) @binding(${i}) var<storage,read_write> ${name}:array<${t}>;\n`;
const gather = (width) =>
  read(0, "id", "u32") +
  read(1, "w", "u32") +
  write(2, "outv") +
  `
@compute @workgroup_size(64) fn main(@builtin(global_invocation_id) gid:vec3u){
 let i=gid.x;let base=(id[0]*${width / 32}u+i/32u)*6u;let bits=w[base+i%32u/8u];
 outv[i]=(f32((bits>>(4u*(i%8u)))&15u)-f32(w[base+5u]))*bitcast<f32>(w[base+4u]);
}`;
const withBias = (activate) =>
  write(0, "x") +
  read(1, "bias") +
  `@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) gid:vec3u){let i=gid.x;let v=x[i]+bias[i];x[i]=${activate ? "v/(1.0+exp(-v))" : "v"};}`;
const select =
  read(0, "scores") +
  write(1, "history", "u32") +
  write(2, "picked", "u32") +
  read(3, "step", "u32") +
  `
var<workgroup> best:array<f32,64>;var<workgroup> ids:array<u32,64>;
@compute @workgroup_size(64) fn main(@builtin(local_invocation_index) lane:u32){
 var mx=-3.402823e38;var token=0u;
 for(var i=lane;i<2048u;i+=64u){
   var v=scores[i];if(history[i]!=0u){v=select(v/1.05,v*1.05,v<0.0);}
   if(v>mx){mx=v;token=i;}
 }
 if(lane==0u && step[0]>=2u && scores[2150]>mx){mx=scores[2150];token=2150u;}
 best[lane]=mx;ids[lane]=token;workgroupBarrier();
 for(var s=32u;s>0u;s=s>>1u){
  if(lane<s && (best[lane+s]>best[lane] || (best[lane+s]==best[lane] && ids[lane+s]<ids[lane]))){
   best[lane]=best[lane+s];ids[lane]=ids[lane+s];
  }workgroupBarrier();
 }
 if(lane==0u){picked[0]=ids[0];history[ids[0]]=1u;}
}`;

export async function createTalker(device, w, capacity = 512) {
  const allocated = [],
    bindings = new Map(),
    bufferIds = new Map();
  let nextId = 0;
  function buf(n) {
    const b = device.createBuffer({
      size: n * 4,
      usage:
        GPUBufferUsage.STORAGE |
        GPUBufferUsage.COPY_SRC |
        GPUBufferUsage.COPY_DST,
    });
    allocated.push(b);
    return b;
  }
  const shaders = {
    norm: k.norm,
    qkv: k.q4Product(1024),
    out: k.q4Product(2048),
    down: k.q4Product(3072),
    cache: k.cache,
    add: k.add,
    silu: k.silu,
    select,
    lookup: gather(1024),
    lookupText: gather(2048),
    bias: withBias(false),
    biasSilu: withBias(true),
    attend: k.attention(capacity),
  };
  const pipes = {};
  for (const [name, code] of Object.entries(shaders)) {
    pipes[name] = await device.createComputePipelineAsync({
      layout: "auto",
      label: "talker " + name,
      compute: {
        entryPoint: "main",
        module: device.createShaderModule({ code }),
      },
    });
  }
  function dispatch(pass, op, n, ...args) {
    const key =
      op +
      ":" +
      args
        .map((b) => {
          if (!bufferIds.has(b)) bufferIds.set(b, nextId++);
          return bufferIds.get(b);
        })
        .join(",");
    let group = bindings.get(key);
    if (!group) {
      group = device.createBindGroup({
        layout: pipes[op].getBindGroupLayout(0),
        entries: args.map((b, binding) => ({
          binding,
          resource: { buffer: b },
        })),
      });
      bindings.set(key, group);
    }
    pass.setPipeline(pipes[op]);
    pass.setBindGroup(0, group);
    pass.dispatchWorkgroups(n);
  }
  const [
    x,
    y,
    qkv,
    q,
    context,
    pair,
    act,
    tmp,
    logits,
    hidden,
    position,
    frame,
    token,
    picked,
    history,
    textRaw,
    textMid,
    textOut,
    pad,
    eos,
    bos,
    codec,
    lookup,
  ] = [
    1024, 1024, 4096, 2048, 2048, 6144, 3072, 1024, 3072, 1024, 1, 1, 1, 1,
    3072, 2048, 2048, 1024, 1024, 1024, 1024, 1024, 1024,
  ].map(buf);
  const caches = Array.from({ length: 28 }, () => [
    buf(capacity * 1024),
    buf(capacity * 1024),
  ]);
  const staging = device.createBuffer({
    size: 4,
    usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ,
  });
  allocated.push(staging);
  const params = new Uint32Array(1);
  const set = (target, value) => {
    params[0] = value;
    device.queue.writeBuffer(target, 0, params);
  };
  let pos = 0,
    generated = 0;
  function pass(fn) {
    const enc = device.createCommandEncoder(),
      p = enc.beginComputePass();
    fn((op, n, ...args) => dispatch(p, op, n, ...args));
    p.end();
    device.queue.submit([enc.finish()]);
  }
  function run(src, final = false) {
    if (pos >= capacity) throw new Error("Qwen talker context limit exceeded");
    set(position, pos++);
    const enc = device.createCommandEncoder();
    enc.copyBufferToBuffer(src, 0, x, 0, 4096);
    const p = enc.beginComputePass();
    const d = (...args) => dispatch(p, ...args);
    for (let l = 0; l < 28; l++) {
      const a = (name) => w[l + "." + name];
      d("norm", 1, x, a("input_layernorm"), y);
      d("qkv", 4096, y, a("qkv"), qkv);
      d(
        "cache",
        24,
        qkv,
        a("self_attn.q_norm"),
        a("self_attn.k_norm"),
        position,
        q,
        ...caches[l],
      );
      d("attend", 16, q, ...caches[l], position, context);
      d("out", 1024, context, a("o"), tmp);
      d("add", 16, x, tmp);
      d("norm", 1, x, a("post_attention_layernorm"), y);
      d("qkv", 6144, y, a("gateUp"), pair);
      d("silu", 48, pair, act);
      d("down", 1024, act, a("down"), tmp);
      d("add", 16, x, tmp);
    }
    if (final) {
      d("norm", 1, x, w.norm, hidden);
      d("qkv", 3072, hidden, w.head, logits);
      d("select", 1, logits, history, picked, frame);
    }
    p.end();
    if (final) enc.copyBufferToBuffer(picked, 0, staging, 0, 4);
    device.queue.submit([enc.finish()]);
  }
  function text(id, dst) {
    set(token, id % 16384);
    pass((d) => {
      d(
        "lookupText",
        32,
        token,
        w["textTable" + Math.floor(id / 16384)],
        textRaw,
      );
      d("out", 2048, textRaw, w.project1, textMid);
      d("biasSilu", 32, textMid, w.bias1);
      d("out", 1024, textMid, w.project2, dst);
      d("bias", 16, dst, w.bias2);
    });
  }
  function code(id, index, dst) {
    set(token, id);
    pass((d) => d("lookup", 16, token, w["codec" + index], dst));
  }
  const sum = (dst, src) => pass((d) => d("add", 16, dst, src));
  async function result() {
    await staging.mapAsync(GPUMapMode.READ);
    try {
      return { code: new Uint32Array(staging.getMappedRange())[0], hidden };
    } finally {
      staging.unmap();
    }
  }
  return {
    async prefill(ids, role, tc, speaker, lang, specials) {
      pos = generated = 0;
      set(frame, 0);
      const enc = device.createCommandEncoder();
      enc.clearBuffer(history);
      device.queue.submit([enc.finish()]);
      text(specials[0], bos);
      text(specials[1], eos);
      text(specials[2], pad);
      for (const id of role) {
        text(id, textOut);
        run(textOut);
      }
      const tags =
        lang == null
          ? [tc.codec_nothink_id, tc.codec_think_bos_id, tc.codec_think_eos_id]
          : [
              tc.codec_think_id,
              tc.codec_think_bos_id,
              lang,
              tc.codec_think_eos_id,
            ];
      for (const id of [...tags, speaker]) {
        code(id, 0, codec);
        sum(codec, pad);
        run(codec);
      }
      code(tc.codec_pad_id, 0, codec);
      sum(codec, bos);
      run(codec);
      code(tc.codec_pad_id, 0, codec);
      for (const id of ids) {
        text(id, textOut);
        sum(textOut, codec);
        run(textOut);
      }
      sum(codec, eos);
      run(codec);
      code(tc.codec_bos_id, 0, codec);
      sum(codec, pad);
      run(codec, true);
      return result();
    },
    async advance(codes) {
      set(frame, ++generated);
      code(codes[0], 0, codec);
      for (let j = 1; j < 16; j++) {
        code(codes[j], j, lookup);
        sum(codec, lookup);
      }
      sum(codec, pad);
      run(codec, true);
      return result();
    },
    destroy() {
      for (const b of allocated) b.destroy();
      for (const b of Object.values(w)) b.destroy();
    },
  };
}
