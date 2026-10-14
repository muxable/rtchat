# Spike results, 2026-10-14

**These are not phone numbers.** No physical phones were available.

- `desktop_*.jsonl`, `streaming_*.jsonl`, `intelligibility_*.jsonl`: AMD
  Ryzen 9 7950X3D (Zen 4, Linux), sherpa-onnx 1.13.8 Python wheel; each run
  pinned with `taskset` to N cores with N ONNX Runtime threads.
- `emulator_x86_64_sherpa.jsonl`: the Flutter app (`sherpa_onnx` 1.13.8,
  release build) on an Android 16 x86_64 emulator (4 vCPUs, 2.5 GB RAM, KVM
  on the same Ryzen host). The emulator runs x86_64 code natively, so these
  numbers are close to desktop speed and say nothing about ARM phone CPUs.
  They show that the package loads and synthesizes on Android, and give
  memory, load-time and streaming behaviour.
- `emulator_x86_64_ort_providers.jsonl`: `ort_native/ort_tts_bench` with the
  official onnxruntime-android 1.28.0 on the same emulator. The emulator has
  no NPU or GPU driver for NNAPI, so NNAPI there means Android's CPU
  reference implementation.
- `SHA256SUMS`: the model archives from the sherpa-onnx `tts-models` release.
