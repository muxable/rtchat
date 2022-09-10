import { LoggingBunyan } from "@google-cloud/logging-bunyan";
import * as bunyan from "bunyan";

export const log = bunyan.createLogger({
  name: "auxiliary",
  streams: [{ stream: process.stdout, level: "info" }],
});

if (process.env.NODE_ENV === "production") {
  log.addStream(new LoggingBunyan().stream("info"));
}
