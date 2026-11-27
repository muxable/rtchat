// Exclude model loading and fixture reads from both warm measurements.
import { loadSpeech } from "./speech.mjs";
import { createPredictor } from "./predictor.mjs";
import { uploadWeights } from "./buffers.mjs";
import { requestSpeechDevice } from "./device.mjs";

const root = new URL("./data/", import.meta.url);
async function bytes(path) {
  const response = await fetch(new URL(path, root));
  if (!response.ok) throw Error("Fixture " + path + ": " + response.status);
  return response;
}

async function measured(run) {
  const before = await globalThis.browserCpu();
  const start = performance.now();
  const output = await run();
  const wall_ms = performance.now() - start;
  const after = await globalThis.browserCpu();
  if (Object.keys(before).some((pid) => !(pid in after))) {
    throw Error("A measured browser subprocess exited");
  }
  const cpu_ms =
    1000 *
    Object.entries(after).reduce(
      (sum, [pid, seconds]) => sum + seconds - (before[pid] ?? 0),
      0,
    );
  return { output, wall_ms, cpu_ms };
}

export async function measureSpeech() {
  const cases = await (await bytes("utterances.json")).json();
  const engine = await loadSpeech(root);
  const rows = [];
  try {
    for (let round = 0; round < 4; round++) {
      for (const [i, sample] of cases.entries()) {
        const reference = new Float32Array(
          await (await bytes("pcm" + i + ".bin")).arrayBuffer(),
        );
        const { output, wall_ms, cpu_ms } = await measured(async () => {
          const codes = [],
            pcm = [];
          for await (const chunk of engine.synthesize(sample.text, {
            maxFrames: 128,
            onCodes: (row) => codes.push([...row]),
          }))
            pcm.push(chunk);
          return { codes, pcm };
        });
        if (JSON.stringify(output.codes) !== JSON.stringify(sample.codes))
          throw Error("Codec IDs differ");
        let n = 0;
        for (const chunk of output.pcm)
          for (const value of chunk) {
            if (!(Math.abs(value - reference[n++]) < 0.003))
              throw Error("PCM differs");
          }
        if (n !== reference.length) throw Error("PCM length differs");
        if (round) rows.push({ text: sample.text, wall_ms, cpu_ms });
      }
    }
    return { adapter: engine.adapter, rows };
  } finally {
    engine.destroy();
  }
}

export async function comparePredictors() {
  const ort = await import("./ort/ort.webgpu.min.mjs");
  ort.env.wasm.numThreads = 1;
  ort.env.wasm.wasmPaths = new URL("./ort/", import.meta.url).href;
  const { device, info } = await requestSpeechDevice();
  const predictor = await createPredictor(
    device,
    await uploadWeights(
      device,
      await (await bytes("layout.json")).json(),
      await bytes("predictor.bin"),
    ),
  );
  const samples = [];
  for (let i = 0; i < 3; i++)
    samples.push({
      state: new Float32Array(
        await (await bytes("state" + i + ".bin")).arrayBuffer(),
      ),
      codes: new Uint32Array(
        await (await bytes("codes" + i + ".bin")).arrayBuffer(),
      ),
    });
  let session;
  let provider = "WebGPU only",
    qualification;
  try {
    // All model nodes must be accepted by the WebGPU EP for a same-GPU comparison.
    try {
      session = await ort.InferenceSession.create(
        "/original/code_predictor.onnx",
        {
          executionProviders: ["webgpu"],
          extra: { session: { disable_cpu_ep_fallback: "1" } },
        },
      );
    } catch (e) {
      const reason = String(e);
      if (
        !/not assigned|CPU EP fallback|not supported|could not find an implementation|not implemented/i.test(
          reason,
        )
      )
        throw e;
      qualification = reason;
      provider = "WebGPU with default CPU fallback";
      session = await ort.InferenceSession.create(
        "/original/code_predictor.onnx",
        { executionProviders: ["webgpu"] },
      );
    }
    const rows = [];
    for (let round = 0; round < 4; round++) {
      for (const [i, { state, codes }] of samples.entries()) {
        for (const name of round % 2
          ? ["onnxruntime", "rtchat"]
          : ["rtchat", "onnxruntime"]) {
          const { output, wall_ms, cpu_ms } = await measured(async () => {
            if (name === "rtchat")
              return (await predictor.predict(state, codes[0])).codes;
            const input = new ort.Tensor("float32", state, [1, 1024]);
            const ids = new BigInt64Array(16);
            ids[0] = BigInt(codes[0]);
            for (let group = 1; group < 16; group++) {
              const args = new ort.Tensor("int64", ids, [1, 16]);
              const { group_logits: logits } = await session.run({
                talker_hidden: input,
                codec_ids: args,
              });
              const v = logits.data,
                start = (group - 1) * 2048;
              let best = 0;
              for (let k = 1; k < 2048; k++)
                if (v[start + k] > v[start + best]) best = k;
              ids[group] = BigInt(best);
              logits.dispose();
              args.dispose();
            }
            input.dispose();
            return Uint32Array.from(ids, Number);
          });
          if (output.length !== 16 || output.some((v, j) => v !== codes[j]))
            throw Error(name + " predictor mismatch");
          if (round) rows.push({ engine: name, case: i, wall_ms, cpu_ms });
        }
      }
    }
    return { adapter: info, provider, qualification, rows };
  } finally {
    if (session) await session.release();
    predictor.destroy();
    device.destroy();
  }
}
