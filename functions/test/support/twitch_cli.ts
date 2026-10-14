import { execFile, execFileSync } from "child_process";
import * as http from "http";
import { AddressInfo } from "net";

// Drives EventSub handlers with real-shaped, signed traffic from the Twitch
// CLI (https://dev.twitch.tv/docs/cli/). Set TWITCH_CLI to the binary, or put
// `twitch` on the PATH.
export const TWITCH_CLI = process.env.TWITCH_CLI || "twitch";

// Without this the CLI asks GitHub for its latest release on every run, and
// panics when GitHub rate-limits it.
const env = { ...process.env, TWITCH_DISABLE_UPDATE_CHECKS: "true" };

/**
 * Whether the CLI can be run. In CI a missing CLI is an error rather than a
 * reason to skip, so the tests can't silently stop running.
 */
export function cliAvailable(): boolean {
  try {
    execFileSync(TWITCH_CLI, ["version"], { stdio: "ignore", env });
    return true;
  } catch (err) {
    if (process.env.CI) {
      throw new Error(`can't run twitch cli ${TWITCH_CLI}: ${err}`);
    }
    console.warn(
      `skipping twitch cli tests: can't run ${TWITCH_CLI} (${err}); set TWITCH_CLI or put twitch on the PATH`
    );
    return false;
  }
}

export interface Delivery {
  headers: http.IncomingHttpHeaders;
  body: any;
  status: number;
  contentType: string | undefined;
  response: string;
}

type Handler = (req: any, res: any) => unknown;

/** Serves `handler` like Cloud Functions does: parsed body plus rawBody. */
export async function serve(handler: Handler) {
  const deliveries: Delivery[] = [];
  const server = http.createServer((req, res) => {
    const chunks: Buffer[] = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", async () => {
      const rawBody = Buffer.concat(chunks);
      const body = rawBody.length ? JSON.parse(rawBody.toString("utf-8")) : {};
      let response = "";
      // recorded before the CLI can see the response, so a finished trigger
      // always has its delivery.
      res.on("finish", () =>
        deliveries.push({
          headers: req.headers,
          body,
          status: res.statusCode,
          contentType: res.getHeader("content-type") as string | undefined,
          response,
        })
      );
      const reply = Object.assign(res, {
        status(code: number) {
          res.statusCode = code;
          return reply;
        },
        send(data?: unknown) {
          response = data === undefined ? "" : String(data);
          res.end(response);
        },
      });
      try {
        await handler(Object.assign(req, { rawBody, body }), reply);
      } catch (err) {
        res.statusCode = 500;
        res.end(String(err));
      }
    });
  });
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address() as AddressInfo;
  return {
    url: `http://127.0.0.1:${port}/`,
    deliveries,
    close: () => new Promise<void>((resolve) => server.close(() => resolve())),
  };
}

function run(args: string[]) {
  return new Promise<string>((resolve, reject) =>
    execFile(
      TWITCH_CLI,
      args,
      { timeout: 30_000, env },
      (err, stdout, stderr) =>
        err
          ? reject(
              new Error(`${TWITCH_CLI} ${args.join(" ")}: ${stderr || err}`)
            )
          : resolve(stdout)
    )
  );
}

/** Sends one signed notification of `type` to `url`. */
export function trigger(
  url: string,
  secret: string,
  type: string,
  flags: string[] = []
) {
  return run([
    "event",
    "trigger",
    type,
    "--transport=webhook",
    "-F",
    url,
    "-s",
    secret,
    "--no-config",
    ...flags,
  ]);
}

/** Runs the CLI's webhook_callback_verification check against `url`. */
export function verifySubscription(url: string, secret: string, type: string) {
  return run([
    "event",
    "verify-subscription",
    type,
    "--transport=webhook",
    "-F",
    url,
    "-s",
    secret,
    "--no-config",
  ]);
}
