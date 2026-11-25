// Schedule each decoded buffer as it arrives so generation overlaps playback.
export async function playSpeech(engine, context, text, options) {
  const { signal, onFirstAudio, ...voice } = options;
  const sources = new Set();
  let until = 0,
    drained = Promise.resolve(),
    first = true;
  const interrupt = () => {
    for (const node of sources) node.stop();
  };
  signal.throwIfAborted();
  signal.addEventListener("abort", interrupt, { once: true });
  try {
    await context.resume();
    for await (const chunk of engine.synthesize(text, { ...voice, signal })) {
      signal.throwIfAborted();
      const buffer = context.createBuffer(1, chunk.length, engine.sampleRate);
      buffer.copyToChannel(chunk, 0);
      const node = context.createBufferSource();
      node.buffer = buffer;
      node.connect(context.destination);
      sources.add(node);
      drained = new Promise((resolve) => {
        node.onended = () => {
          sources.delete(node);
          node.disconnect();
          resolve();
        };
      });
      const start = Math.max(context.currentTime, until);
      node.start(start);
      if (first) {
        first = false;
        onFirstAudio?.(start - context.currentTime);
      }
      until = start + buffer.duration;
    }
    await drained;
  } finally {
    signal.removeEventListener("abort", interrupt);
    interrupt();
  }
}
