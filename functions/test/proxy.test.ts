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
let attempts = 0;
let reply: {
  status: number;
  headers?: Record<string, string>;
  body: string;
  interrupt?: boolean;
  stall?: "headers" | "body";
  reset?: boolean;
};

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
      attempts++;
      if (reply.reset) {
        req.socket.destroy();
        return;
      }
      if (reply.stall === "headers") {
        return;
      }
      res.writeHead(reply.status, reply.headers ?? {});
      if (reply.stall === "body") {
        res.write(reply.body);
      } else if (reply.interrupt) {
        res.write(reply.body);
        setTimeout(() => res.destroy(), 10);
      } else {
        res.end(reply.body);
      }
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
  app.all("/boundedGetBadges", proxyCallable("getBadges", 100) as any);
  app.all(
    "/boundedEventsub",
    proxy("eventsub", "/twitch/eventsub", 100) as any,
  );
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
  attempts = 0;
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

  test.each([
    [502, 503, "UNAVAILABLE"],
    [503, 503, "UNAVAILABLE"],
    [504, 504, "DEADLINE_EXCEEDED"],
    [200, 500, "INTERNAL"],
  ])(
    "maps a non-JSON upstream %i to HTTP %i / %s",
    async (upstreamStatus, status, code) => {
      reply = {
        status: upstreamStatus as number,
        body: "<html>bad gateway</html>",
      };
      const res = await fetch(`${functionsUrl}/getBadges`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ data: {} }),
      });
      expect(res.status).toBe(status);
      expect((await res.json()).error.status).toBe(code);
    },
  );

  test.each(["headers", "body"] as const)(
    "bounds an upstream that stalls during %s without replaying the call",
    async (stall) => {
      reply = { status: 200, body: '{"result":', stall };
      const res = await fetch(`${functionsUrl}/boundedGetBadges`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ data: {} }),
      });
      expect(res.status).toBe(504);
      expect((await res.json()).error.status).toBe("DEADLINE_EXCEEDED");
      expect(attempts).toBe(1);
    },
  );

  test("reports an upstream socket reset as unavailable without replaying the call", async () => {
    reply = { status: 200, body: "", reset: true };
    const res = await fetch(`${functionsUrl}/getBadges`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ data: {} }),
    });
    expect(res.status).toBe(503);
    expect((await res.json()).error.status).toBe("UNAVAILABLE");
    expect(attempts).toBe(1);
  });

  test("returns a bounded deadline when the upstream body is interrupted", async () => {
    reply = {
      status: 200,
      headers: { "content-type": "application/json", "content-length": "200" },
      body: '{"result":',
      interrupt: true,
    };
    const res = await fetch(`${functionsUrl}/boundedGetBadges`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ data: {} }),
    });
    expect(res.status).toBe(504);
    expect((await res.json()).error.status).toBe("DEADLINE_EXCEEDED");
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

  test("returns a gateway error when the upstream body is interrupted", async () => {
    reply = {
      status: 200,
      headers: { "content-type": "application/json", "content-length": "200" },
      body: '{"accepted":',
      interrupt: true,
    };
    const res = await fetch(`${functionsUrl}/boundedEventsub`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: "{}",
    });
    expect(res.status).toBe(504);
    expect(await res.text()).toBe("agent timeout");
    expect(res.headers.get("content-type")).toContain("text/html");
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
