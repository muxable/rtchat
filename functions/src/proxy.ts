import fetch from "cross-fetch";
import * as functions from "firebase-functions";

type Request = functions.https.Request;
type Response = Awaited<ReturnType<typeof fetch>>;

// Every API except OAuth now runs on the managed agent (#1551). Released apps
// before 2.11.0 and provider dashboards still call these Cloud Functions, so
// each one forwards the original request to the agent and relays its answer.
export const API_ORIGIN = "https://rtchat-api.rtirl.com";

// tests point the proxies at a local server.
const apiOrigin = () => process.env.RTCHAT_API_ORIGIN || API_ORIGIN;

// The agent logs this as "via" to tell forwarded traffic from direct traffic.
export const PROXY_HEADER = "x-rtchat-proxy";

// Hop-by-hop headers and ones the next hop sets itself. accept-encoding is
// dropped because fetch decompresses the response before it is relayed.
const DROPPED_REQUEST_HEADERS = new Set([
  "accept-encoding",
  "connection",
  "content-length",
  "forwarded",
  "function-execution-id",
  "host",
  "keep-alive",
  "proxy-authorization",
  "te",
  "trailer",
  "transfer-encoding",
  "upgrade",
]);

const DROPPED_RESPONSE_HEADERS = new Set([
  "connection",
  "content-encoding",
  "content-length",
  "keep-alive",
  "transfer-encoding",
  "via",
]);

const opts = { memory: "128MB" as const, timeoutSeconds: 60 };

export function forwardedHeaders(req: Request, name: string) {
  const headers: Record<string, string> = {};
  for (const [key, value] of Object.entries(req.headers)) {
    const lower = key.toLowerCase();
    if (
      value === undefined ||
      DROPPED_REQUEST_HEADERS.has(lower) ||
      lower.startsWith("x-forwarded-")
    ) {
      continue;
    }
    headers[lower] = Array.isArray(value) ? value.join(", ") : value;
  }
  headers[PROXY_HEADER] = name;
  return headers;
}

// A request that already passed through a proxy means the load balancer sent
// this path back to Cloud Functions; forwarding it again would loop.
function looped(req: Request, name: string) {
  if (req.headers[PROXY_HEADER] === undefined) {
    return false;
  }
  functions.logger.error("proxy loop", {
    name,
    via: req.headers[PROXY_HEADER],
  });
  return true;
}

function forward(req: Request, name: string, path: string) {
  const query = req.originalUrl.indexOf("?");
  const url =
    apiOrigin() + path + (query >= 0 ? req.originalUrl.slice(query) : "");
  const hasBody = req.method !== "GET" && req.method !== "HEAD";
  return fetch(url, {
    method: req.method,
    headers: forwardedHeaders(req, name),
    body: hasBody ? req.rawBody : undefined,
    redirect: "manual",
  });
}

// proxy forwards a plain HTTP function, such as a webhook, byte for byte so
// provider signatures still verify.
export function proxy(name: string, path: string) {
  return functions.runWith(opts).https.onRequest(async (req, res) => {
    if (looped(req, name)) {
      res.status(508).send("proxy loop");
      return;
    }
    let upstream: Response;
    try {
      upstream = await forward(req, name, path);
    } catch (err) {
      functions.logger.error("agent unreachable", { name, error: `${err}` });
      res.status(502).send("agent unreachable");
      return;
    }
    if (upstream.status >= 500) {
      functions.logger.warn("agent error", { name, status: upstream.status });
    }
    res.status(upstream.status);
    upstream.headers.forEach((value, key) => {
      if (!DROPPED_RESPONSE_HEADERS.has(key.toLowerCase())) {
        res.setHeader(key, value);
      }
    });
    res.send(Buffer.from(await upstream.arrayBuffer()));
  });
}

const ERROR_CODES = new Set<string>([
  "cancelled",
  "unknown",
  "invalid-argument",
  "deadline-exceeded",
  "not-found",
  "already-exists",
  "permission-denied",
  "resource-exhausted",
  "failed-precondition",
  "aborted",
  "out-of-range",
  "unimplemented",
  "internal",
  "unavailable",
  "data-loss",
  "unauthenticated",
]);

// relayCallable turns the agent's callable protocol response back into a
// result or an HttpsError for the onCall wrapper to encode.
export async function relayCallable(name: string, upstream: Response) {
  let body: any;
  try {
    body = await upstream.json();
  } catch (err) {
    functions.logger.error("agent returned invalid JSON", {
      name,
      status: upstream.status,
    });
    throw new functions.https.HttpsError("internal", "INTERNAL");
  }
  if (body && typeof body === "object" && "result" in body) {
    return body.result;
  }
  const error = body?.error;
  const code = String(error?.status ?? "")
    .toLowerCase()
    .replace(/_/g, "-");
  if (upstream.status >= 500) {
    functions.logger.warn("agent error", { name, status: upstream.status });
  }
  throw new functions.https.HttpsError(
    (ERROR_CODES.has(code)
      ? code
      : "internal") as functions.https.FunctionsErrorCode,
    typeof error?.message === "string" ? error.message : "INTERNAL",
    error?.details,
  );
}

// proxyCallable keeps the callable trigger, since Firebase cannot change a
// deployed callable into an HTTP function in place. It forwards the original
// request, including the caller's ID token, so the agent authenticates it.
export function proxyCallable(name: string) {
  return functions.runWith(opts).https.onCall(async (_data, context) => {
    if (looped(context.rawRequest, name)) {
      throw new functions.https.HttpsError("internal", "proxy loop");
    }
    let upstream: Response;
    try {
      upstream = await forward(context.rawRequest, name, `/${name}`);
    } catch (err) {
      functions.logger.error("agent unreachable", { name, error: `${err}` });
      throw new functions.https.HttpsError("unavailable", "agent unreachable");
    }
    return relayCallable(name, upstream);
  });
}
