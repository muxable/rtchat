// Index entries refer to TensorProto.raw_data in a checksum-verified ONNX
// file. Only constants are rearranged here. All model operators run on GPU.
export async function readTensor(part, read) {
  const [type, file, a, b, c, d] = part;
  if (type === "f32") return read(file, a, b);
  if (type === "i64") {
    const words = new BigInt64Array(await read(file, a, b));
    return Float32Array.from(words, Number).buffer;
  }
  if (type === "normalize") {
    const [table, counts] = await Promise.all([
      read(file, a, b),
      read(file, c, b / d),
    ]);
    const values = new Float32Array(table),
      scale = new Float32Array(counts);
    for (let row = 0; row < scale.length; row++) {
      for (let j = row * d; j < (row + 1) * d; j++) values[j] /= scale[row];
    }
    return values.buffer;
  }
  if (type !== "q4") throw new Error("Unknown Qwen weight layout");
  const [bits, scales, zeros] = await Promise.all([
    read(file, b, a * 16),
    read(file, c, a * 4),
    read(file, d, a / 2),
  ]);
  const words = new Uint32Array(bits),
    scale = new Uint32Array(scales),
    zero = new Uint8Array(zeros);
  const result = new Uint32Array(a * 6);
  for (let i = 0; i < a; i++) {
    const target = i * 6,
      source = i * 4;
    result[target] = words[source];
    result[target + 1] = words[source + 1];
    result[target + 2] = words[source + 2];
    result[target + 3] = words[source + 3];
    result[target + 4] = scale[i];
    result[target + 5] = (zero[i >> 1] >> ((i % 2) * 4)) & 15;
  }
  return result.buffer;
}

export function readRanges(root) {
  return async (file, offset, size) => {
    const end = offset + size - 1;
    const response = await fetch(new URL(file, root), {
      headers: { Range: `bytes=${offset}-${end}` },
    });
    if (
      response.status !== 206 ||
      !response.headers
        .get("Content-Range")
        ?.startsWith(`bytes ${offset}-${end}/`)
    )
      throw new Error("Unserved ONNX byte range in " + file);
    const result = await response.arrayBuffer();
    if (result.byteLength !== size)
      throw new Error("Truncated ONNX weight in " + file);
    return result;
  };
}

export async function uploadSource(device, index, read) {
  const weights = {};
  let batch = [],
    reservedBytes = 0;
  async function flush() {
    await Promise.all(
      batch.map(async ({ part, buffer, offset, size, name }) => {
        const data = await readTensor(part, read);
        if (data.byteLength !== size)
          throw new Error("Unexpected tensor length for " + name);
        device.queue.writeBuffer(buffer, offset, data);
      }),
    );
    batch = [];
    reservedBytes = 0;
  }
  for (const [name, parts] of Object.entries(index)) {
    const sizes = parts.map(([kind, , blocks, bytes]) =>
      kind === "q4" ? blocks * 24 : kind === "i64" ? bytes / 2 : bytes,
    );
    const size = sizes.reduce((sum, n) => sum + n, 0);
    if (size > device.limits.maxStorageBufferBindingSize)
      throw new Error("Qwen tensor exceeds the adapter's binding limit");
    const buffer = device.createBuffer({
      label: name,
      size,
      usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST,
    });
    weights[name] = buffer;
    let offset = 0;
    for (const [i, part] of parts.entries()) {
      // Amortize request overhead while bounding the host-side staging memory.
      if (
        batch.length &&
        (batch.length >= 8 || reservedBytes + sizes[i] > 32 * 1024 * 1024)
      )
        await flush();
      batch.push({ part, buffer, offset, size: sizes[i], name });
      reservedBytes += sizes[i];
      offset += sizes[i];
    }
  }
  await flush();
  return weights;
}
