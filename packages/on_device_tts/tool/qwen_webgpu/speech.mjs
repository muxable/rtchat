import { requestSpeechDevice } from "./device.mjs";
import { createTalker } from "./talker.mjs";
import { createPredictor } from "./predictor.mjs";
import { createDecoder } from "./decoder.mjs";
import { makeTokenizer } from "./tokenizer.mjs";
import { uploadWeights } from "./buffers.mjs";

// All neural operations dispatch WebGPU kernels. The host handles tokenization,
// submits work and forwards completed mono Float32 PCM chunks to the audio sink.
export async function loadSpeech(root) {
  const { device, info } = await requestSpeechDevice();
  const failed = [];
  device.addEventListener("uncapturederror", (e) =>
    failed.push(e.error.message),
  );
  device.lost.then((e) => failed.push(e.message || "WebGPU device lost"));
  const get = async (name) => {
    const r = await fetch(new URL(name, root));
    if (!r.ok) throw new Error("Missing model asset " + name);
    return r;
  };
  const json = async (name) => (await get(name)).json();
  try {
    const cfg = await json("config.json"),
      tc = cfg.talker_config;
    const encode = makeTokenizer(
      await json("vocab.json"),
      await (await get("merges.txt")).text(),
    );
    const talker = await createTalker(
      device,
      await uploadWeights(
        device,
        await json("talker.json"),
        await get("talker.bin"),
      ),
    );
    const predictor = await createPredictor(
      device,
      await uploadWeights(
        device,
        await json("layout.json"),
        await get("predictor.bin"),
      ),
    );
    const plan = await json("decoder.json");
    const decoder = await createDecoder(
      device,
      plan,
      await uploadWeights(device, plan.layout, await get("decoder.bin")),
    );
    const special = [
      cfg.tts_bos_token_id,
      cfg.tts_eos_token_id,
      cfg.tts_pad_token_id,
    ];
    let busy = false;
    return {
      adapter: info,
      sampleRate: 24000,
      async *synthesize(
        text,
        {
          speaker = "ryan",
          language = "english",
          maxFrames = 256,
          signal,
          onCodes,
        } = {},
      ) {
        if (busy) throw new Error("A Qwen utterance is already in progress");
        const ids = encode(text.trim());
        if (!ids.length) return;
        const voice = tc.spk_id[speaker],
          lang = language === "auto" ? null : tc.codec_language_id[language];
        if (
          !Number.isInteger(voice) ||
          (language !== "auto" && !Number.isInteger(lang))
        )
          throw new Error("Unknown Qwen voice or language");
        if (
          !Number.isInteger(maxFrames) ||
          maxFrames < 1 ||
          ids.length + maxFrames + 16 > 512
        )
          throw new Error("Utterance exceeds Qwen context");
        busy = true;
        try {
          signal?.throwIfAborted();
          let frame = await talker.prefill(
              ids,
              [151644, ...encode("assistant\n")],
              tc,
              voice,
              lang,
              special,
            ),
            pending = [];
          for (let i = 0; i < maxFrames; i++) {
            if (failed.length) throw new Error(failed.join("\n"));
            signal?.throwIfAborted();
            if (frame.code === tc.codec_eos_token_id) break;
            const { codes } = await predictor.predict(frame.hidden, frame.code);
            pending.push(codes);
            onCodes?.(codes);
            if (pending.length === 25) {
              const chunk = await decoder.decode(pending);
              signal?.throwIfAborted();
              if (failed.length) throw new Error(failed.join("\n"));
              yield chunk;
              pending = [];
            }
            if (i + 1 === maxFrames)
              throw new Error("Qwen did not finish within the frame limit");
            frame = await talker.advance(codes);
          }
          if (pending.length) {
            const chunk = await decoder.decode(pending);
            signal?.throwIfAborted();
            if (failed.length) throw new Error(failed.join("\n"));
            yield chunk;
          }
        } finally {
          busy = false;
        }
      },
      destroy() {
        talker.destroy();
        predictor.destroy();
        decoder.destroy();
        device.destroy();
      },
    };
  } catch (error) {
    device.destroy();
    throw error;
  }
}
