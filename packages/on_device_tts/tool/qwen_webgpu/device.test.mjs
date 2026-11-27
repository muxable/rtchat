import assert from "node:assert/strict";
import test from "node:test";
import { requestSpeechDevice } from "../../assets/qwen/device.mjs";

test("speech requires an identifiable hardware adapter", async () => {
  let requests = 0;
  const reject = async (adapter) =>
    assert.rejects(
      requestSpeechDevice({ requestAdapter: async () => adapter }),
      /hardware WebGPU adapter/,
    );
  await reject(null);
  for (const info of [
    {},
    { vendor: "apple", isFallbackAdapter: true },
    { description: "SwiftShader" },
    { architecture: "llvmpipe" },
  ]) {
    await reject({
      info,
      requestDevice: () => {
        requests++;
      },
    });
  }
  assert.equal(requests, 0);
  const gpu = {
    requestAdapter: async () => ({
      info: { vendor: "apple" },
      features: new Set(["subgroups"]),
      requestDevice: async ({ requiredFeatures }) => requiredFeatures,
    }),
  };
  assert.deepEqual((await requestSpeechDevice(gpu)).device, ["subgroups"]);
});
