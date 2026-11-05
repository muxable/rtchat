const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { test } = require("node:test");
const vm = require("node:vm");

const script = fs.readFileSync(
  path.join(__dirname, "../../assets/twitch-tunnel.js"),
  "utf8",
);

function player() {
  const listeners = [];
  const sent = [];
  const frame = {
    contentWindow: { postMessage: (data) => sent.push(data) },
    style: {},
  };
  let frames = 0;
  const window = {
    addEventListener: (name, listener) => listeners.push(listener),
  };
  const context = vm.createContext({
    window,
    document: {
      createElement: () => frame,
      body: { appendChild: () => frames++ },
    },
  });
  vm.runInContext(script, context);
  return {
    window,
    sent,
    context,
    frames: () => frames,
    emit: (data, source = frame.contentWindow) => {
      for (const listener of listeners) listener({ data, source });
    },
  };
}

test("settings and play wait for readiness, retaining the latest volume", () => {
  const p = player();
  p.window.action(p.window.Actions.SetVolume, 0);
  p.window.action(p.window.Actions.SetVolume, 0.33);
  p.window.action(p.window.Actions.Play);
  assert.equal(p.sent.length, 0);
  p.emit({
    namespace: "twitch-embed-player-proxy",
    params: { playback: "Idle" },
  });
  assert.equal(p.sent.length, 0);
  p.emit({ namespace: "twitch-embed", eventName: "ready" }, {});
  assert.equal(p.sent.length, 0);
  p.emit({ namespace: "twitch-embed", eventName: "ready" });
  assert.deepEqual(
    p.sent.map((data) => [data.eventName, data.params]),
    [
      [11, 0.33],
      [3, undefined],
    ],
  );
  p.window.action(p.window.Actions.SetMuted, false);
  assert.equal(p.sent.at(-1).eventName, 10);
});

test("a playing state handles a ready event emitted before injection", () => {
  const p = player();
  p.window.action(p.window.Actions.SetMuted, true);
  p.emit({
    namespace: "twitch-embed-player-proxy",
    params: { playback: "Playing" },
  });
  assert.equal(p.sent.length, 1);
});

test("repeated page-finished callbacks do not replace the tunnel", () => {
  const p = player();
  const action = p.window.action;
  vm.runInContext(script, p.context);
  assert.equal(p.frames(), 1);
  assert.equal(p.window.action, action);
});
