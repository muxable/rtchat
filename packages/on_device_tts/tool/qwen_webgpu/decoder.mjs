// The pinned codec decoder consumes 25 × 16 code IDs and returns 48,000
// mono float samples. Kernels and shapes are lowered from the ONNX graph.
export async function createDecoder(device, plan, weights) {
  const all = [];
  function allocate(bytes) {
    const b = device.createBuffer({
      size: bytes,
      usage:
        GPUBufferUsage.STORAGE |
        GPUBufferUsage.COPY_SRC |
        GPUBufferUsage.COPY_DST,
    });
    all.push(b);
    return b;
  }
  const values = new Map(Object.entries(weights));
  all.push(...values.values());
  const pipelines = await Promise.all(
    plan.shaders.map(async (code, i) =>
      device.createComputePipelineAsync({
        label: "codec " + i,
        layout: "auto",
        compute: {
          module: device.createShaderModule({ code }),
          entryPoint: "main",
        },
      }),
    ),
  );
  const codes = allocate(25 * 16 * 4);
  values.set(plan.input, codes);
  const last = new Map();
  for (const [i, op] of plan.ops.entries())
    for (const name of op[2]) last.set(name, i);
  const pool = [];
  const commands = [];
  for (const [
    i,
    [shader, dispatch, inputs, out, count],
  ] of plan.ops.entries()) {
    const bytes = count * 4;
    const reuse = pool.findIndex((b) => b.size >= bytes && b.size < 2 * bytes);
    const dst = reuse < 0 ? allocate(bytes) : pool.splice(reuse, 1)[0];
    const pipe = pipelines[shader],
      code = plan.shaders[shader];
    const entries = [];
    for (const [binding, id] of inputs.entries()) {
      if (code.includes("a" + binding + "["))
        entries.push({ binding, resource: { buffer: values.get(id) } });
    }
    entries.push({ binding: inputs.length, resource: { buffer: dst } });
    const bind = device.createBindGroup({
      layout: pipe.getBindGroupLayout(0),
      entries,
    });
    commands.push([pipe, bind, dispatch]);
    values.set(out, dst);
    for (const id of new Set(inputs)) {
      if (last.get(id) === i && id !== plan.input && !(id in plan.layout)) {
        pool.push(values.get(id));
        values.delete(id);
      }
    }
  }
  const pcm = values.get(plan.output);
  let busy = false;
  return {
    async decode(frames) {
      if (busy) throw new Error("Decoder already in use");
      if (
        frames.length < 1 ||
        frames.length > 25 ||
        frames.some((f) => f.length !== 16)
      )
        throw new Error("Expected 1–25 codec frames");
      busy = true;
      const tiled = new Float32Array(25 * 16);
      for (let i = 0; i < 25; i++) tiled.set(frames[i % frames.length], i * 16);
      const size = frames.length * 1920 * 4;
      const read = device.createBuffer({
        size,
        usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST,
      });
      try {
        device.queue.writeBuffer(codes, 0, tiled);
        const enc = device.createCommandEncoder(),
          pass = enc.beginComputePass();
        for (const [p, b, groups] of commands) {
          pass.setPipeline(p);
          pass.setBindGroup(0, b);
          pass.dispatchWorkgroups(...groups);
        }
        pass.end();
        enc.copyBufferToBuffer(pcm, 0, read, 0, size);
        device.queue.submit([enc.finish()]);
        await read.mapAsync(GPUMapMode.READ);
        return new Float32Array(read.getMappedRange().slice(0));
      } finally {
        read.destroy();
        busy = false;
      }
    },
    destroy() {
      for (const b of all) b.destroy();
    },
  };
}
