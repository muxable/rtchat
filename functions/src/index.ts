// OAuth remains on Cloud Functions until its optional managed migration is verified.
// Deploy only functions:auth; retiring live functions requires the reviewed CLI.
import * as functions from "firebase-functions";
import { app } from "./auth";
import { YOUTUBE_OAUTH_SECRETS } from "./oauth";

export const auth = functions
  .runWith({ secrets: YOUTUBE_OAUTH_SECRETS })
  .https.onRequest(app);
