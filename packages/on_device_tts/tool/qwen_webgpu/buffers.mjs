// Upload each tensor as HTTP chunks arrive. The 0.6B export is larger than
// WebGPU's baseline binding limit; each individual binding fits that limit.
export async function uploadWeights(device, layout, response) {
  if (!response.ok)
    throw new Error("Could not load model weights: " + response.status);
  const reader = response.body.getReader();
  let chunk = new Uint8Array(),
    cursor = 0;
  const buffers = {};
  let consumed = 0;
  try {
    for (const [name, [offset, size]] of Object.entries(layout)) {
      if (
        offset !== consumed ||
        size <= 0 ||
        size % 4 ||
        size > device.limits.maxStorageBufferBindingSize
      )
        throw new Error("Invalid tensor size/offset: " + name);
      // Network chunk boundaries need not be aligned for writeBuffer.
      const data = new Uint8Array(size);
      let written = 0;
      while (written < size) {
        if (cursor === chunk.length) {
          const { value, done } = await reader.read();
          if (done) throw new Error("Truncated tensor: " + name);
          chunk = value;
          cursor = 0;
        }
        const n = Math.min(chunk.length - cursor, size - written);
        data.set(chunk.subarray(cursor, cursor + n), written);
        cursor += n;
        written += n;
      }
      const b = device.createBuffer({
        label: name,
        size,
        usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST,
      });
      buffers[name] = b;
      device.queue.writeBuffer(b, 0, data);
      consumed += size;
    }
    if (cursor !== chunk.length || !(await reader.read()).done)
      throw new Error("Unexpected trailing model data");
    return buffers;
  } catch (e) {
    for (const b of Object.values(buffers)) b.destroy();
    throw e;
  } finally {
    await reader.cancel();
    reader.releaseLock();
  }
}
