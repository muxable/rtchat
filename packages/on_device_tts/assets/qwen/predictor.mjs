import * as k from "./kernels.mjs";

// Cached causal decoding of the five-layer Qwen3-TTS 0.6B residual predictor.
// A complete codec frame uses one command buffer and one final readback.
export async function createPredictor(device, w) {
  const allocated = [];
  function buffer(bytes, data) {
    const out = device.createBuffer({
      size: bytes,
      usage:
        GPUBufferUsage.STORAGE |
        GPUBufferUsage.COPY_SRC |
        GPUBufferUsage.COPY_DST,
    });
    allocated.push(out);
    if (data) device.queue.writeBuffer(out, 0, data);
    return out;
  }
  const pipelines = {};
  const shaders = {
    ...k,
    attend: k.attention(16),
    product1024: k.q4Product(1024),
    product2048: k.q4Product(2048),
    product3072: k.q4Product(3072),
  };
  delete shaders.q4Product;
  delete shaders.attention;
  for (const [name, code] of Object.entries(shaders)) {
    const module = device.createShaderModule({ label: name, code });
    pipelines[name] = await device.createComputePipelineAsync({
      label: name,
      layout: "auto",
      compute: { module, entryPoint: "main" },
    });
  }

  allocated.push(...Object.values(w));
  const vectors = (lengths) => lengths.map((n) => buffer(n * 4));
  const [x, y, qkv, q, context, gateUp, act, tmp, logits, codes, hidden] =
    vectors([1024, 1024, 4096, 2048, 2048, 6144, 3072, 1024, 2048, 16, 1024]);
  const caches = Array.from({ length: 5 }, () =>
    vectors([16 * 1024, 16 * 1024]),
  );
  const commands = [];
  function add(name, n, ...buffers) {
    const pipeline = pipelines[name];
    const bind = device.createBindGroup({
      layout: pipeline.getBindGroupLayout(0),
      entries: buffers.map((b, binding) => ({
        binding,
        resource: { buffer: b },
      })),
    });
    commands.push([pipeline, bind, n]);
  }
  // Stash every head's logits for parity checks without synchronizing the CPU
  // between codebooks. The regular path only transfers the 16 output IDs.
  const boundaries = [];
  for (let pos = 0; pos < 16; pos++) {
    const step = buffer(4, new Uint32Array([pos]));
    if (pos) add("embed", 16, codes, step, w["embed" + (pos - 1)], x);
    for (let l = 0; l < 5; l++) {
      const weight = (name) => w[l + "." + name];
      add("norm", 1, x, weight("input_layernorm"), y);
      add("product1024", 4096, y, weight("qkv"), qkv);
      add(
        "cache",
        24,
        qkv,
        weight("self_attn.q_norm"),
        weight("self_attn.k_norm"),
        step,
        q,
        ...caches[l],
      );
      add("attend", 16, q, ...caches[l], step, context);
      add("product2048", 1024, context, weight("o"), tmp);
      add("add", 16, x, tmp);
      add("norm", 1, x, weight("post_attention_layernorm"), y);
      add("product1024", 6144, y, weight("gateUp"), gateUp);
      add("silu", 48, gateUp, act);
      add("product3072", 1024, act, weight("down"), tmp);
      add("add", 16, x, tmp);
    }
    if (pos) {
      add("norm", 1, x, w.norm, y);
      add("product1024", 2048, y, w["head" + (pos - 1)], logits);
      add("argmax", 1, logits, codes, step);
    }
    boundaries.push(commands.length);
  }
  let busy = false;
  return {
    async predict(state, firstCode, { captureLogits = false } = {}) {
      if (busy) throw new Error("Predictor already in use");
      if (
        (state instanceof Float32Array
          ? state.length !== 1024
          : state.size !== 4096) ||
        !Number.isInteger(firstCode) ||
        firstCode < 0 ||
        firstCode >= 2048
      )
        throw new Error("Invalid talker result");
      busy = true;
      const size = 64 + (captureLogits ? 15 * 2048 * 4 : 0);
      const read = device.createBuffer({
        size,
        usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST,
      });
      try {
        if (state instanceof Float32Array)
          device.queue.writeBuffer(hidden, 0, state);
        device.queue.writeBuffer(codes, 0, new Uint32Array([firstCode]));
        const enc = device.createCommandEncoder();
        enc.copyBufferToBuffer(
          state instanceof Float32Array ? hidden : state,
          0,
          x,
          0,
          4096,
        );
        let cursor = 0;
        for (let pos = 0; pos < 16; pos++) {
          const pass = enc.beginComputePass();
          while (cursor < boundaries[pos]) {
            const [p, b, n] = commands[cursor++];
            pass.setPipeline(p);
            pass.setBindGroup(0, b);
            pass.dispatchWorkgroups(n);
          }
          pass.end();
          if (pos && captureLogits)
            enc.copyBufferToBuffer(
              logits,
              0,
              read,
              64 + (pos - 1) * 8192,
              8192,
            );
        }
        enc.copyBufferToBuffer(codes, 0, read, 0, 64);
        device.queue.submit([enc.finish()]);
        await read.mapAsync(GPUMapMode.READ);
        const bytes = read.getMappedRange().slice(0);
        return {
          codes: new Uint32Array(bytes, 0, 16),
          logits: new Float32Array(bytes, 64),
        };
      } finally {
        read.destroy();
        busy = false;
      }
    },
    destroy() {
      for (const b of allocated) b.destroy();
    },
  };
}
