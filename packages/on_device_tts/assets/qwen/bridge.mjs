import { loadSpeech } from "./speech.mjs";
import { playSpeech } from "./player.mjs";

let engine, context, active;
const send = (message) => QwenSpeech.postMessage(JSON.stringify(message));
const checkDevice = async () => {
  const response = await fetch("./qualification.json");
  if (!response.ok) throw new Error("Missing Qwen qualification sample");
  const sample = await response.json();
  const codes = [];
  let offset = 0,
    peak = 0;
  let scheduledUntil,
    maxGapMs = 0;
  const start = performance.now();
  for await (const chunk of engine.synthesize(sample.text, {
    maxFrames: 64,
    onCodes: (row) => codes.push([...row]),
  })) {
    const ready = performance.now();
    if (scheduledUntil !== undefined)
      maxGapMs = Math.max(maxGapMs, ready - scheduledUntil);
    scheduledUntil = Math.max(ready, scheduledUntil ?? 0) + chunk.length / 24;
    for (let j = 0; j < chunk.length; j++, offset++) {
      if (offset % sample.stride === 0)
        peak = Math.max(
          peak,
          maxGapMs,
          Math.abs(chunk[j] - sample.samples[offset / sample.stride]),
        );
    }
  }
  const elapsed = performance.now() - start;
  if (
    JSON.stringify(codes) !== JSON.stringify(sample.codes) ||
    offset !== sample.codes.length * 1920 ||
    !(peak < 0.003)
  )
    throw new Error("Qwen failed the on-device speech reference check");
  const metrics = {
    adapter: engine.adapter,
    elapsedMs: elapsed,
    audioMs: offset / 24,
    rtf: elapsed / (offset / 24),
    peak,
    maxGapMs,
  };
  if (maxGapMs > 0)
    throw new Error(
      "Qwen playback would underrun by " +
        maxGapMs.toFixed(0) +
        " ms on this device",
    );
  if (elapsed >= offset / 24)
    throw new Error(
      "Qwen is slower than playback on this device (" +
        metrics.rtf.toFixed(2) +
        " RTF)",
    );
  return metrics;
};
window.qwen = async ({ id, method, text, options }) => {
  let metrics;
  try {
    if (method === "load") {
      engine = await loadSpeech(new URL("./model/", location.href));
      try {
        metrics = await checkDevice();
      } catch (e) {
        engine.destroy();
        engine = undefined;
        throw e;
      }
    } else if (method === "speak") {
      if (!engine || active) throw new Error("Qwen speech unavailable");
      context ??= new AudioContext();
      const controller = new AbortController();
      active = controller;
      try {
        await playSpeech(engine, context, text, {
          ...options,
          signal: controller.signal,
        });
      } catch (e) {
        if (!controller.signal.aborted) throw e;
      } finally {
        active = undefined;
      }
    } else if (method === "stop") {
      active?.abort();
    } else {
      throw new Error("Unknown speech request");
    }
    send({ id, metrics });
  } catch (e) {
    send({ id, error: String(e) });
  }
};
send({ ready: true });
