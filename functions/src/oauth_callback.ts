import type { Request, Response, RequestHandler } from "express";
import * as functions from "firebase-functions/v1";
import { isValidState } from "./oauth";

type SignInError = "access_denied" | "sign_in_failed" | "no_youtube_channel";

export function signInError(req: Request, res: Response, message: SignInError) {
  if (req.session.companion) {
    res.status(400).type("text/plain").send(message);
  } else {
    res.redirect(
      "com.rtirl.chat://error?message=" + encodeURIComponent(message),
    );
  }
}

// Only provider callbacks with a valid session and an actual code reach token
// exchange. Consume state before exchanging so failed/duplicate callbacks cannot
// reuse an authorization code. Never serialize OAuth errors: they can hold secrets.
export function oauthCallback(
  provider: string,
  complete: (req: Request, res: Response) => Promise<void>,
): RequestHandler {
  return async (req, res) => {
    if (!isValidState(req.session?.state, req.query.state)) {
      res.redirect(`/auth/${provider}/redirect`);
      return;
    }
    req.session.state = undefined;
    if (
      req.query.error ||
      typeof req.query.code !== "string" ||
      !req.query.code
    ) {
      req.session.codeVerifier = undefined;
      signInError(
        req,
        res,
        req.query.error === "access_denied" || !req.query.error
          ? "access_denied"
          : "sign_in_failed",
      );
      return;
    }
    try {
      await complete(req, res);
    } catch (error) {
      const failure = new Error(`OAuth ${provider} sign-in failed`);
      // Preserve useful source frames without copying error messages or the
      // nested HTTP request/configuration attached by OAuth clients.
      if (error instanceof Error && error.stack) {
        failure.stack =
          `${failure.name}: ${failure.message}\n` +
          error.stack
            .split("\n")
            .filter((line) => /^\s+at /.test(line))
            .join("\n");
      }
      const upstream = error as {
        output?: { statusCode?: unknown };
        data?: { payload?: { error?: unknown } };
      } | null;
      const status = upstream?.output?.statusCode;
      const code = upstream?.data?.payload?.error;
      functions.logger.error(failure, {
        provider,
        ...(typeof status === "number" && status >= 100 && status <= 599
          ? { status }
          : {}),
        ...(typeof code === "string" &&
        [
          "invalid_grant",
          "invalid_client",
          "access_denied",
          "temporarily_unavailable",
          "server_error",
        ].includes(code)
          ? { code }
          : {}),
      });
      signInError(req, res, "sign_in_failed");
    }
  };
}
