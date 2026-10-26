import express from "express";
import session, { SessionData } from "express-session";
import type * as admin from "firebase-admin";
import { createServer } from "http";
import type { AddressInfo } from "net";
import fetch from "cross-fetch";
import { expect, test, vi } from "vitest";
import { FirestoreStore } from "../src/session_store";

function storeWithWrite(write: ReturnType<typeof vi.fn>): FirestoreStore {
  return new FirestoreStore({
    dataset: {
      collection: () => ({ doc: () => ({ set: write }) }),
    } as unknown as admin.firestore.Firestore,
  });
}

const data = { cookie: {} } as SessionData;

test("forwards a rejected Firestore write to the session callback", async () => {
  const failure = new Error("Firestore unavailable");
  const write = vi.fn().mockRejectedValue(failure);
  const store = storeWithWrite(write);
  const callback = vi.fn();
  const completed = new Promise<void>((resolve) => {
    store.set("oauth-session", data, (error) => {
      callback(error);
      resolve();
    });
  });
  await completed;
  expect(callback).toHaveBeenCalledExactlyOnceWith(failure);
});

test("completes successful writes without an error", async () => {
  const write = vi.fn().mockResolvedValue({});
  const store = storeWithWrite(write);
  await new Promise<void>((resolve, reject) => {
    store.set("oauth-session", data, (error) => {
      if (error) reject(error);
      else resolve();
    });
  });
  expect(write).toHaveBeenCalledExactlyOnceWith({ data: JSON.stringify(data) });
});

test("optional callbacks still handle rejected writes", async () => {
  const store = storeWithWrite(
    vi.fn().mockRejectedValue(new Error("unavailable")),
  );
  store.set("oauth-session", data);
  // Let the rejection handler execute; Vitest would fail on an unhandled rejection.
  await new Promise<void>((resolve) => setImmediate(resolve));
});

test("Express finishes its response and receives the failed automatic session save", async () => {
  const failure = new Error("Firestore session write canceled");
  const store = storeWithWrite(vi.fn().mockRejectedValue(failure));
  const app = express();
  app.use(
    session({
      store,
      secret: "test-only-secret",
      resave: true,
      saveUninitialized: true,
      proxy: true,
      cookie: {
        secure: true,
        httpOnly: true,
      },
    }),
  );
  app.get("/auth/start", (req, res) => {
    req.session.state = "oauth-state";
    res.send("response completed");
  });
  let receiveError: (error: unknown) => void;
  const handled = new Promise<unknown>((resolve) => {
    receiveError = resolve;
  });
  app.use(
    (
      error: unknown,
      _req: express.Request,
      _res: express.Response,
      _next: express.NextFunction,
    ) => {
      receiveError(error);
    },
  );
  const server = createServer(app);
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  try {
    const response = await fetch(
      `http://127.0.0.1:${(server.address() as AddressInfo).port}/auth/start`,
    );
    expect(await response.text()).toBe("response completed");
    expect(await handled).toBe(failure);
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});
