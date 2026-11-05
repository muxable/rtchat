import express from "express";
import fetch from "cross-fetch";
import { createServer, Server } from "http";
import type { AddressInfo } from "net";
import { afterAll, beforeAll, beforeEach, expect, test, vi } from "vitest";

vi.mock("firebase-functions/v1", async (original) => {
  const actual = await original<typeof import("firebase-functions/v1")>();
  return { ...actual, logger: { ...actual.logger, error: vi.fn() } };
});
import * as functions from "firebase-functions/v1";
import { oauthCallback } from "../src/oauth_callback";

let server: Server;
let url: string;
let session: any;
const exchange = vi.fn();
beforeAll(async () => {
  const app = express();
  app.use((req, _res, next) => {
    req.session = session;
    next();
  });
  app.get("/callback", oauthCallback("twitch", exchange));
  server = createServer(app);
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  url = `http://127.0.0.1:${(server.address() as AddressInfo).port}/callback`;
});
afterAll(() => new Promise<void>((resolve) => server.close(() => resolve())));
beforeEach(() => {
  session = { state: "valid", codeVerifier: "pkce" };
  exchange.mockReset().mockImplementation(async (_req, res) => {
    res.send("signed in");
  });
  vi.mocked(functions.logger.error).mockClear();
});

for (const query of [
  "error=access_denied",
  "",
  "code=",
  "code[x]=bad",
  "code=a&code=b",
]) {
  test(`does not exchange missing, denied, or malformed code: ${query}`, async () => {
    const response = await fetch(`${url}?state=valid&${query}`, {
      redirect: "manual",
    });
    expect(response.status).toBe(302);
    expect(response.headers.get("location")).toBe(
      "com.rtirl.chat://error?message=access_denied",
    );
    expect(exchange).not.toHaveBeenCalled();
    expect(session.state).toBeUndefined();
    expect(session.codeVerifier).toBeUndefined();
    expect(functions.logger.error).not.toHaveBeenCalled();
  });
}

test("checks state before handling provider errors", async () => {
  const response = await fetch(`${url}?state=wrong&error=access_denied`, {
    redirect: "manual",
  });
  expect(new URL(response.headers.get("location")!).pathname).toBe(
    "/auth/twitch/redirect",
  );
  expect(exchange).not.toHaveBeenCalled();
  expect(session.state).toBe("valid");
});

test("consumes state once while preserving PKCE for the exchange", async () => {
  exchange.mockImplementationOnce(async (req, res) => {
    expect(req.session.codeVerifier).toBe("pkce");
    expect(req.session.state).toBeUndefined();
    res.send("signed in");
  });
  const response = await fetch(`${url}?state=valid&code=real`);
  expect(await response.text()).toBe("signed in");
  const duplicate = await fetch(`${url}?state=valid&code=real`, {
    redirect: "manual",
  });
  expect(new URL(duplicate.headers.get("location")!).pathname).toBe(
    "/auth/twitch/redirect",
  );
  expect(exchange).toHaveBeenCalledTimes(1);
});

test("returns a sign-in failure and reports unexpected errors without credentials", async () => {
  const failure = Object.assign(new Error("provider echoed secret-value"), {
    output: { statusCode: 400 },
    data: {
      payload: { error: "invalid_grant" },
      request: { client_secret: "client-secret", code: "authorization-code" },
    },
  });
  exchange.mockRejectedValueOnce(failure);
  const response = await fetch(`${url}?state=valid&code=real`, {
    redirect: "manual",
  });
  expect(response.headers.get("location")).toBe(
    "com.rtirl.chat://error?message=sign_in_failed",
  );
  const reported = vi.mocked(functions.logger.error).mock.calls[0][0] as Error;
  expect(reported.stack).toContain("oauth_callback.test.ts");
  expect(reported.message).toBe("OAuth twitch sign-in failed");
  expect(vi.mocked(functions.logger.error).mock.calls[0][1]).toEqual({
    provider: "twitch",
    status: 400,
    code: "invalid_grant",
  });
  expect(reported.stack).not.toContain("secret-value");
  expect(JSON.stringify(reported)).not.toContain("client-secret");
  expect(JSON.stringify(reported)).not.toContain("authorization-code");
});

test("returns a plain response to companion sign-in failures", async () => {
  session.companion = "companion-id";
  exchange.mockRejectedValueOnce(new Error("database unavailable"));
  const response = await fetch(`${url}?state=valid&code=real`);
  expect(response.status).toBe(400);
  expect(await response.text()).toBe("sign_in_failed");
});
