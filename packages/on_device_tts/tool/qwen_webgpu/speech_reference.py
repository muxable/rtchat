"""Run the export author's greedy decoding loop as an independent PCM oracle."""

import importlib.util
import json
import sys
from pathlib import Path

import numpy as np
from transformers import Qwen2Tokenizer


def pipeline(root):
    spec = importlib.util.spec_from_file_location(
        "upstream_qwen_tts", root / "inference.py"
    )
    source = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(source)
    pipe = source.Pipeline(str(root), str(root))
    pipe._tok = Qwen2Tokenizer(
        vocab_file=str(root / "vocab.json"),
        merges_file=str(root / "merges.txt"),
        additional_special_tokens=["<|im_start|>", "<|im_end|>"],
    )
    # Qwen's added token ids follow the base vocabulary and end-of-text.
    role = pipe._ids("<|im_start|>assistant\n")[0].tolist()
    if role != [151644, 77091, 198]:
        raise ValueError(f"Incorrect chat-template tokenizer: {role}")
    return pipe


def reference(root, dest):
    pipe = pipeline(root)
    cases = []
    for i, text in enumerate(("Hello chat!", "Thank you!")):
        codes = pipe.generate(
            text,
            language="english",
            speaker="ryan",
            max_new_tokens=128,
            do_sample=False,
            sub_do_sample=False,
            verbose=False,
        )
        if not 0 < len(codes) < 128:
            raise ValueError(f"No EOS for {text}")
        pcm = pipe.decode_chunked(codes[None]).reshape(-1).astype("<f4")
        assert len(pcm) == len(codes) * 1920
        pcm.tofile(dest / f"pcm{i}.bin")
        cases.append(
            dict(text=text, ids=pipe._ids(text)[0].tolist(), codes=codes.tolist())
        )
        print(text, len(codes), len(pcm), flush=True)
    # Short chat strings can fail to reach EOS under greedy generation. Verify
    # the same prefix independently and exercise the production frame limit.
    capped_text = "GG everyone!"
    capped = pipe.generate(
        capped_text,
        language="english",
        speaker="ryan",
        max_new_tokens=3,
        do_sample=False,
        sub_do_sample=False,
        verbose=False,
    )
    assert len(capped) == 3
    (dest / "capped.json").write_text(
        json.dumps(dict(text=capped_text, codes=capped.tolist()))
    )
    (dest / "utterances.json").write_text(json.dumps(cases))


if __name__ == "__main__":
    reference(Path(sys.argv[1]), Path(sys.argv[2]))
