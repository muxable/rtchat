import { uploadWeights } from "./buffers.mjs";
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
    const layout = await (await file("layout.json")).json();
    const predictor = await createPredictor(
      device,
      await uploadWeights(device, layout, await file("predictor.bin")),
    );
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

export async function qualifySpeech() {
  const { loadSpeech } = await import("./speech.mjs");
  const root = new URL("./data/", import.meta.url);
  const cases = await (await file("utterances.json")).json();
  const started = performance.now();
  const engine = await loadSpeech(root);
  const loadMs = performance.now() - started;
  const rows = [];
  try {
    const capped = await (await file("capped.json")).json();
    const prefix = [];
    let stoppedAtLimit = false;
    try {
      for await (const _ of engine.synthesize(capped.text, {
        maxFrames: capped.codes.length,
        onCodes: (row) => prefix.push([...row]),
      }))
        throw new Error("Unexpected audio from a capped three-frame input");
    } catch (e) {
      if (!e.message.includes("did not finish within the frame limit")) throw e;
      stoppedAtLimit = true;
    }
    if (
      !stoppedAtLimit ||
      JSON.stringify(prefix) !== JSON.stringify(capped.codes)
    )
      throw new Error(
        "Capped prefix mismatch " +
          JSON.stringify({ prefix, expected: capped.codes }),
      );
    for (const [i, { text, codes }] of cases.entries()) {
      const expected = new Float32Array(
        await (await file("pcm" + i + ".bin")).arrayBuffer(),
      );
      const generated = [];
      const chunks = [];
      let firstMs, stages;
      const start = performance.now();
      for await (const pcm of engine.synthesize(text, {
        maxFrames: 128,
        onProfile: (report) => {
          stages = report;
        },
        onCodes: (frame) => generated.push([...frame]),
      })) {
        firstMs ??= performance.now() - start;
        chunks.push(pcm);
      }
      const elapsed = performance.now() - start;
      if (JSON.stringify(generated) !== JSON.stringify(codes)) {
        const mismatch = generated.findIndex(
          (frame, j) => JSON.stringify(frame) !== JSON.stringify(codes[j]),
        );
        throw new Error(
          JSON.stringify({
            text,
            mismatch,
            actual: generated[mismatch],
            expected: codes[mismatch],
            frames: generated.length,
            expectedFrames: codes.length,
          }),
        );
      }
      let offset = 0,
        peak = 0;
      for (const pcm of chunks) {
        for (const sample of pcm)
          peak = Math.max(peak, Math.abs(sample - expected[offset++]));
      }
      if (offset !== expected.length || !(peak < 0.003))
        throw new Error(
          JSON.stringify({ text, peak, offset, expected: expected.length }),
        );
      const audioMs = offset / 24;
      const row = {
        text,
        firstMs,
        elapsed,
        stages,
        audioMs,
        rtf: elapsed / audioMs,
        frames: generated.length,
        peak,
      };
      rows.push(row);
      console.log("Qwen PCM " + JSON.stringify(row));
    }
    return { adapter: engine.adapter, loadMs, rows };
  } finally {
    engine.destroy();
  }
}
