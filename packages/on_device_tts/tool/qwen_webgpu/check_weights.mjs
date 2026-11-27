// Compare the browser's TensorProto-range reader against independently packed
// Python data a tensor at a time, without allocating a second model in RAM.
import { open, readFile } from "node:fs/promises";
import { join } from "node:path";
import { readTensor } from "../../assets/qwen/source.mjs";

const [root, packed] = process.argv.slice(2);
const index = JSON.parse(
  await readFile(
    new URL("../../assets/qwen/weights.index", import.meta.url),
    "utf8",
  ),
);
const files = new Map();
async function bytes(file, offset, size) {
  if (!files.has(file)) files.set(file, open(join(root, file)));
  const handle = await files.get(file);
  const data = new Uint8Array(size);
  let read = 0;
  while (read < size) {
    const { bytesRead } = await handle.read(
      data,
      read,
      size - read,
      offset + read,
    );
    if (!bytesRead) throw new Error("Unexpected end of " + file);
    read += bytesRead;
  }
  return data.buffer;
}
try {
  for (const [stage, weights] of Object.entries(index)) {
    const serialized = await open(join(packed, stage + ".bin"));
    let offset = 0;
    try {
      for (const [name, parts] of Object.entries(weights)) {
        for (const part of parts) {
          const data = new Uint8Array(await readTensor(part, bytes));
          const expected = Buffer.alloc(data.length);
          const { bytesRead } = await serialized.read(
            expected,
            0,
            expected.length,
            offset,
          );
          if (bytesRead !== data.length || !expected.equals(data))
            throw new Error(
              stage + " tensor " + name + " differs from the independent pack",
            );
          offset += data.length;
        }
      }
      if (offset !== (await serialized.stat()).size)
        throw new Error("Incomplete " + stage);
      console.log(stage + ": all " + offset + " bytes matched");
    } finally {
      await serialized.close();
    }
  }
} finally {
  for (const file of files.values()) await (await file).close();
}
