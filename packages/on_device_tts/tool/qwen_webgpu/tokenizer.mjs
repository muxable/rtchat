// Qwen2 byte-level BPE. Insert the chat role at the embedding layer; chat
// messages cannot inject special tokens through the ordinary-text encoder.
export function makeTokenizer(vocab, merges) {
  const rank = new Map();
  for (const line of merges.split(/\r?\n/)) {
    if (line && !line.startsWith("#version:")) rank.set(line, rank.size);
  }
  const alphabet = new Array(256);
  let next = 256;
  for (let i = 0; i < 256; i++) {
    const display = (i >= 33 && i <= 126) || (i >= 161 && i <= 172) || i >= 174;
    alphabet[i] = String.fromCodePoint(display ? i : next++);
  }
  const bytes = new TextEncoder();
  const split =
    /'(?:s|t|re|ve|m|ll|d)|[^\r\n\p{L}\p{N}]?\p{L}+|\p{N}| ?[^\s\p{L}\p{N}]+[\r\n]*|\s*[\r\n]+|\s+(?!\S)|\s+/giu;
  return (text) => {
    const ids = [];
    for (const [piece] of text.normalize("NFC").matchAll(split)) {
      let symbols = Array.from(bytes.encode(piece), (b) => alphabet[b]);
      while (symbols.length > 1) {
        let best = Infinity,
          left,
          right;
        for (let j = 1; j < symbols.length; j++) {
          const priority = rank.get(symbols[j - 1] + " " + symbols[j]);
          if (priority < best) {
            best = priority;
            left = symbols[j - 1];
            right = symbols[j];
          }
        }
        if (best === Infinity) break;
        const merged = [];
        for (let i = 0; i < symbols.length; i++) {
          if (symbols[i] === left && symbols[i + 1] === right) {
            merged.push(left + right);
            i++;
          } else merged.push(symbols[i]);
        }
        symbols = merged;
      }
      for (const symbol of symbols) {
        const id = vocab[symbol];
        if (!Number.isInteger(id)) throw new Error("Unknown tokenizer symbol");
        ids.push(id);
      }
    }
    return ids;
  };
}
