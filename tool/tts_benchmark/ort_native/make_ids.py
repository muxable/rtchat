#!/usr/bin/env python3
"""Maps corpus messages to character-level token ids for ort_tts_bench.

There is no phonemizer here on purpose: the ids only need realistic
sequence lengths so the raw-model benchmark costs about what a real message
costs. Run with `python3 -I`; tokens.txt is untrusted data.

Usage: make_ids.py <kind: kitten|kokoro|vits> <tokens.txt> <corpus.txt> > ids.txt
"""

import sys


def main():
    kind, tokens_path, corpus_path = sys.argv[1:4]
    tokens = {}
    with open(tokens_path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            i = line.rfind(" ")
            if i < 0:
                continue
            sym = line[:i] if i > 0 else " "
            tokens[sym] = int(line[i + 1:])
    space = tokens.get(" ", 0)
    with open(corpus_path, encoding="utf-8") as f:
        for text in (l.strip() for l in f):
            if not text:
                continue
            body = [tokens.get(c, space) for c in text.lower()]
            if kind == "vits":
                pad = tokens.get("_", 0)
                ids = [tokens.get("^", 1), pad]
                for t in body:
                    ids += [t, pad]
                ids.append(tokens.get("$", 2))
            else:
                ids = [0] + body + [0]
            print(" ".join(map(str, ids)))


if __name__ == "__main__":
    main()
