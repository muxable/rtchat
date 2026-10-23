import express from "express";
import fetch from "cross-fetch";
import { createServer, IncomingHttpHeaders, Server } from "http";
import { AddressInfo } from "net";
import {
  afterAll,
  beforeAll,
  beforeEach,
  describe,
  expect,
  test,
  vi,
} from "vitest";
import { proxy, proxyCallable } from "../src/proxy";

// firebase-functions reads these when it loads; they let onCall accept the
// unsigned test token instead of verifying it against Firebase Auth.
vi.hoisted(() => {
  process.env.FIREBASE_DEBUG_MODE = "true";
  process.env.FIREBASE_DEBUG_FEATURES = JSON.stringify({
    skipTokenVerification: true,
  });
});

type Seen = {
  method?: string;
  url?: string;
  headers?: IncomingHttpHeaders;
  body?: string;
};

let agent: Server;
let functionsHost: Server;
let functionsUrl = "";
let seen: Seen = {};
let reply: { status: number; headers?: Record<string, string>; body: string };

function listen(server: Server) {
  return new Promise<string>((resolve) =>
    server.listen(0, "127.0.0.1", () =>
      resolve(`http://127.0.0.1:${(server.address() as AddressInfo).port}`),
    ),
  );
}

// an unsigned ID token, accepted because token verification is skipped above.
function idToken(uid: string) {
  const part = (v: object) =>
    Buffer.from(JSON.stringify(v)).toString("base64url");
  return [
    part({ alg: "none" }),
    part({ sub: uid, uid, aud: "demo", iss: "x" }),
    "",
  ].join(".");
}

beforeAll(async () => {
  agent = createServer((req, res) => {
    let body = "";
    req.on("data", (chunk) => (body += chunk));
    req.on("end", () => {
      seen = { method: req.method, url: req.url, headers: req.headers, body };
      res.writeHead(reply.status, reply.headers ?? {});
      res.end(reply.body);
    });
  });
  process.env.RTCHAT_API_ORIGIN = await listen(agent);

  // serve the functions the way Cloud Functions does: parsed body plus rawBody.
  const app = express();
  app.use(
    express.json({
      verify: (req, _res, buf) => {
        (req as any).rawBody = buf;
      },
    }),
  );
  app.all("/getBadges", proxyCallable("getBadges") as any);
  app.all("/eventsub", proxy("eventsub", "/twitch/eventsub") as any);
  app.all("/embedRedirect", proxy("embedRedirect", "/embedRedirect") as any);
  functionsHost = createServer(app);
  functionsUrl = await listen(functionsHost);
});

afterAll(() => {
  agent.close();
  functionsHost.close();
});

beforeEach(() => {
  seen = {};
  reply = { status: 200, body: "" };
});

describe("proxyCallable", () => {
  test("forwards the request and token and relays the result", async () => {
    reply = {
      status: 200,
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ result: { badges: [1, 2] } }),
    };
    const token = idToken("user-1");
    const res = await fetch(`${functionsUrl}/getBadges`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ data: { provider: "twitch", channelId: "1" } }),
    });
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ result: { badges: [1, 2] } });
    expect(seen.method).toBe("POST");
    expect(seen.url).toBe("/getBadges");
    expect(seen.headers?.authorization).toBe(`Bearer ${token}`);
    expect(seen.headers?.["x-rtchat-proxy"]).toBe("getBadges");
    expect(JSON.parse(seen.body!)).toEqual({
      data: { provider: "twitch", channelId: "1" },
    });
  });

  test("relays callable errors with their code, message and details", async () => {
    reply = {
      status: 400,
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        error: {
          status: "INVALID_ARGUMENT",
          message: "invalid channelId",
          details: { field: "channelId" },
        },
      }),
    };
    const res = await fetch(`${functionsUrl}/getBadges`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ data: {} }),
    });
    expect(res.status).toBe(400);
    expect(await res.json()).toEqual({
      error: {
        status: "INVALID_ARGUMENT",
        message: "invalid channelId",
        details: { field: "channelId" },
      },
    });
    expect(seen.headers?.authorization).toBeUndefined();
  });

  test("returns INTERNAL when the agent answers with something else", async () => {
    reply = { status: 502, body: "<html>bad gateway</html>" };
    const res = await fetch(`${functionsUrl}/getBadges`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ data: {} }),
    });
    expect(res.status).toBe(500);
    expect((await res.json()).error.status).toBe("INTERNAL");
  });
});

describe("proxy", () => {
  test("refuses a request that already came through a proxy", async () => {
    const res = await fetch(`${functionsUrl}/eventsub`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-rtchat-proxy": "eventsub",
      },
      body: "{}",
    });
    expect(res.status).toBe(508);
    expect(seen.url).toBeUndefined();
  });

  test("forwards webhook bodies and signature headers unchanged", async () => {
    reply = { status: 200, body: "challenge-value" };
    // spacing that JSON parsing would not preserve, since signatures cover the raw bytes.
    const body = '{"challenge":  "challenge-value" ,"subscription":{}}';
    const res = await fetch(`${functionsUrl}/eventsub?x=1`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "Twitch-Eventsub-Message-Id": "id-1",
        "Twitch-Eventsub-Message-Signature": "sha256=abc",
        "Twitch-Eventsub-Message-Timestamp": "2026-10-23T00:00:00Z",
        "Twitch-Eventsub-Message-Type": "webhook_callback_verification",
      },
      body,
    });
    expect(res.status).toBe(200);
    expect(await res.text()).toBe("challenge-value");
    expect(seen.url).toBe("/twitch/eventsub?x=1");
    expect(seen.body).toBe(body);
    expect(seen.headers?.["twitch-eventsub-message-signature"]).toBe(
      "sha256=abc",
    );
    expect(seen.headers?.["twitch-eventsub-message-id"]).toBe("id-1");
    expect(seen.headers?.["x-rtchat-proxy"]).toBe("eventsub");
  });

  test("relays redirects without following them", async () => {
    reply = {
      status: 302,
      headers: { location: "https://player.twitch.tv/?channel=x" },
      body: "",
    };
    const res = await fetch(
      `${functionsUrl}/embedRedirect?provider=twitch&channelId=1`,
      { redirect: "manual" },
    );
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe(
      "https://player.twitch.tv/?channel=x",
    );
    expect(seen.method).toBe("GET");
    expect(seen.url).toBe("/embedRedirect?provider=twitch&channelId=1");
  });
});
