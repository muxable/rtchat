import { requestSpeechDevice } from "./device.mjs";
import { createPredictor } from "./predictor.mjs";

async function file(name) {
  const response = await fetch(
    new URL(name, new URL("./data/", import.meta.url)),
  );
  if (!response.ok) throw new Error(`Loading ${name}: ${response.status}`);
  return response;
}

export async function qualifyPredictor() {
  const { device, info } = await requestSpeechDevice();
  const errors = [];
  device.addEventListener("uncapturederror", (e) =>
    errors.push(e.error.message),
  );
  try {
    const [layout, bytes] = await Promise.all([
      file("layout.json").then((r) => r.json()),
      file("predictor.bin").then((r) => r.arrayBuffer()),
    ]);
    const predictor = await createPredictor(device, layout, bytes);
    const rows = [];
    for (let i = 0; i < 3; i++) {
      const input = new Float32Array(
        await (await file(`state${i}.bin`)).arrayBuffer(),
      );
      const codes = new Uint32Array(
        await (await file(`codes${i}.bin`)).arrayBuffer(),
      );
      const logits = new Float32Array(
        await (await file(`logits${i}.bin`)).arrayBuffer(),
      );
      const actual = await predictor.predict(input, codes[0], {
        captureLogits: true,
      });
      const peak = actual.logits.reduce(
        (m, n, j) => Math.max(m, Math.abs(n - logits[j])),
        0,
      );
      if (
        errors.length ||
        actual.codes.some((id, j) => id !== codes[j]) ||
        !(peak < 0.002)
      ) {
        throw new Error(
          JSON.stringify({
            info,
            case: i,
            peak,
            expected: [...codes],
            actual: [...actual.codes],
            errors,
          }),
        );
      }
      const start = performance.now();
      await predictor.predict(input, codes[0]);
      rows.push({ case: i, peak, ms: performance.now() - start });
    }
    predictor.destroy();
    if (errors.length) throw new Error(errors.join("\n"));
    return { adapter: info, predictor: rows, audioFrameMs: 80 };
  } finally {
    device.destroy();
  }
}
