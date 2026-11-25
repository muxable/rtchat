// A missing or software adapter is an unsupported device for Qwen speech.
export async function requestSpeechDevice(gpu = navigator.gpu) {
  if (!gpu) throw new Error("Qwen speech requires a hardware WebGPU adapter");
  const adapter = await gpu.requestAdapter({powerPreference: "high-performance"});
  const info = adapter?.info;
  if (!adapter || !info || info.isFallbackAdapter || adapter.isFallbackAdapter ||
      /swiftshader|llvmpipe|lavapipe|software|warp\b|basic render/i.test(
        [info.vendor, info.architecture, info.device, info.description].join(" ")
      ) || !(info.vendor || info.architecture || info.device || info.description)) {
    throw new Error("Qwen speech requires an identifiable hardware WebGPU adapter");
  }
  return {device: await adapter.requestDevice(), info: {
    vendor: info.vendor, architecture: info.architecture, device: info.device,
    description: info.description,
  }};
}
