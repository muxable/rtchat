# Qwen3-TTS for RTChat

Open **Text to Speech → Voice packs**, download **Qwen3-TTS 0.6B CustomVoice**, then select it. The installer fetches the pinned public ONNX files directly from Hugging Face and verifies their sizes and SHA-256 digests. After installation, text, audio and inference stay on the device.

RTChat loads the talker, residual predictor and waveform decoder on a hardware WebGPU adapter in the mobile WebView. The first session synthesizes a known sample to check codec IDs, waveform error and playback speed. An unsupported adapter or failed device check prevents Qwen playback. Audio is mono at 24 kHz. RTChat plays the first decoded chunk while synthesizing the next. Stop cancels pending synthesis and scheduled playback.

The **Qwen speech on WebGPU** workflow compares deterministic speech against the model exporter's Python ONNX implementation. It records load time, first PCM, playback completion, scheduling gaps, stage timings and synthesis time divided by audio duration. The test requires a ratio below one and continuous playback. The macOS runner uses Chrome on an Apple GPU. Mobile WebViews qualify separately on the device.

The committed `weights.index` locates quantized weight blocks in the verified ONNX files. `decoder.plan` contains the fixed-shape waveform kernels. CI regenerates both files from the pinned models using `source_index.py` and `pack_decoder.py`.
