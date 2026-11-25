# Qwen3-TTS for RTChat

This path runs the pinned 0.6B CustomVoice model on a hardware WebGPU device. The talker, residual predictor and waveform decoder execute in the mobile WebView. Tokenization and audio scheduling run on the host. A missing accelerator, a software adapter, a waveform mismatch or a device slower than playback makes the voice unavailable.

## Install a test pack

The **Qwen speech on WebGPU** workflow verifies the upstream ONNX files, packs the weights and runs a separate Python ONNX reference. A manual run with `export_pack` produces the installable pack as an Actions artifact. To reproduce the pack locally, run the download and packing commands in the workflow.

Serve the nine files in the pack from one HTTPS directory. Build RTChat with `--dart-define=QWEN_TTS_PACK_URL=https://your-host.example/qwen/`. In **Text to Speech → Voice packs**, download and select **Qwen3-TTS 0.6B CustomVoice**. The installer checks each file's size and SHA-256. Speech runs offline after installation. This build option lets testers use their own static model storage.

The first utterance loads the weights and synthesizes a known sample to check codec IDs, waveform error and playback speed on that device. PCM runs at 24 kHz. Playback starts as soon as a decoded chunk is available and the next chunk can be synthesized concurrently. Stop cancels pending synthesis and scheduled audio. A hardware test in desktop Chrome exercises the same kernels. Mobile WebViews must qualify independently.
