import * as bunyan from "bunyan";
import { LoggingBunyan } from "@google-cloud/logging-bunyan";

export const log = bunyan.createLogger({
  name: "agent",
  streams: [{ stream: process.stdout, level: "info" }],
});

if (process.env.NODE_ENV === "production") {
  log.addStream(new LoggingBunyan().stream("info"));
}
