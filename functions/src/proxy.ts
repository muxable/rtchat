import fetch from "cross-fetch";
import * as functions from "firebase-functions/v1";

type Request = functions.https.Request;
type Response = Awaited<ReturnType<typeof fetch>>;
type UpstreamResponse = {
  status: number;
  headers: Response["headers"];
  body: Buffer;
};

// Leave time for the 60-second function to encode and send a canonical error.
const UPSTREAM_TIMEOUT_MS = 55_000;

const TRANSPORT_CODES = new Set([
  "ECONNRESET",
  "ECONNREFUSED",
  "ECONNABORTED",
  "ENOTFOUND",
  "EAI_AGAIN",
  "ETIMEDOUT",
  "EHOSTUNREACH",
  "ENETUNREACH",
  "EPIPE",
  "ERR_STREAM_PREMATURE_CLOSE",
  "ABORT_ERR",
  "CERT_HAS_EXPIRED",
  "DEPTH_ZERO_SELF_SIGNED_CERT",
  "UNABLE_TO_VERIFY_LEAF_SIGNATURE",
  "ERR_TLS_CERT_ALTNAME_INVALID",
]);
const TRANSPORT_NAMES = new Set([
  "FetchError",
  "AbortError",
  "TypeError",
  "Error",
]);

class UpstreamError extends Error {
  readonly transportName?: string;
  readonly code?: string;

  constructor(
    readonly timedOut: boolean,
    error: unknown,
    readonly status?: number,
  ) {
    super(timedOut ? "agent timeout" : "agent transport failure");
    // FetchError messages contain the complete URL, including legacy auth
    // query parameters. Keep only known transport diagnostics, never the cause.
    const cause = error as { name?: unknown; code?: unknown } | null;
    if (typeof cause?.name === "string" && TRANSPORT_NAMES.has(cause.name)) {
      this.transportName = cause.name;
    }
    if (typeof cause?.code === "string" && TRANSPORT_CODES.has(cause.code)) {
      this.code = cause.code;
    }
  }
}

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

async function forward(
  req: Request,
  name: string,
  path: string,
  timeoutMillis: number,
): Promise<UpstreamResponse> {
  const query = req.originalUrl.indexOf("?");
  const url =
    apiOrigin() + path + (query >= 0 ? req.originalUrl.slice(query) : "");
  const hasBody = req.method !== "GET" && req.method !== "HEAD";
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMillis);
  let status: number | undefined;
  try {
    const response = await fetch(url, {
      method: req.method,
      headers: forwardedHeaders(req, name),
      body: hasBody ? new Uint8Array(req.rawBody).buffer : undefined,
      redirect: "manual",
      signal: controller.signal,
    });
    status = response.status;
    // The deadline covers the body too. A reset after headers must not leave the
    // function waiting until its hard timeout, or commit partial response headers.
    const body = Buffer.from(await response.arrayBuffer());
    return { status: response.status, headers: response.headers, body };
  } catch (error) {
    throw new UpstreamError(controller.signal.aborted, error, status);
  } finally {
    clearTimeout(timeout);
  }
}

function transportError(
  name: string,
  error: unknown,
): functions.https.HttpsError {
  const timedOut = error instanceof UpstreamError && error.timedOut;
  const message = timedOut ? "agent timeout" : "agent unreachable";
  functions.logger.error(message, {
    name,
    timedOut,
    ...(error instanceof UpstreamError
      ? {
          errorName: error.transportName,
          errorCode: error.code,
          status: error.status,
        }
      : {}),
  });
  return new functions.https.HttpsError(
    timedOut ? "deadline-exceeded" : "unavailable",
    message,
  );
}

// proxy forwards a plain HTTP function, such as a webhook, byte for byte so
// provider signatures still verify.
export function proxy(
  name: string,
  path: string,
  timeoutMillis = UPSTREAM_TIMEOUT_MS,
) {
  return functions.runWith(opts).https.onRequest(async (req, res) => {
    if (looped(req, name)) {
      res.status(508).send("proxy loop");
      return;
    }
    let upstream: UpstreamResponse;
    try {
      upstream = await forward(req, name, path, timeoutMillis);
    } catch (err) {
      const failure = transportError(name, err);
      res
        .status(failure.code === "deadline-exceeded" ? 504 : 502)
        .send(failure.message);
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
    res.send(upstream.body);
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
export async function relayCallable(name: string, upstream: UpstreamResponse) {
  let body: any;
  try {
    body = JSON.parse(upstream.body.toString("utf8"));
  } catch (err) {
    functions.logger.error("agent returned invalid JSON", {
      name,
      status: upstream.status,
    });
    if (upstream.status === 504) {
      throw new functions.https.HttpsError(
        "deadline-exceeded",
        "agent deadline exceeded",
      );
    }
    if (upstream.status === 502 || upstream.status === 503) {
      throw new functions.https.HttpsError("unavailable", "agent unavailable");
    }
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
export function proxyCallable(
  name: string,
  timeoutMillis = UPSTREAM_TIMEOUT_MS,
) {
  return functions.runWith(opts).https.onCall(async (_data, context) => {
    if (looped(context.rawRequest, name)) {
      throw new functions.https.HttpsError("internal", "proxy loop");
    }
    let upstream: UpstreamResponse;
    try {
      upstream = await forward(
        context.rawRequest,
        name,
        `/${name}`,
        timeoutMillis,
      );
    } catch (err) {
      throw transportError(name, err);
    }
    return relayCallable(name, upstream);
  });
}
