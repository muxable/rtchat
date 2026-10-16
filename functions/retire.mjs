// Retire one reviewed non-OAuth function. Default behavior only inventories/plans.
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { parseArgs } from "node:util";
import { fileURLToPath } from "node:url";

export const PROJECT = "rtchat-47692";
export const REGION = "us-central1";
export const replacements = Object.freeze({
  send: "/send",
  ban: "/ban",
  unban: "/unban",
  timeout: "/timeout",
  deleteMessage: "/deleteMessage",
  clear: "/clear",
  raid: "/raid",
  cancelRaid: "/cancelRaid",
  subscribe: "/subscribe",
  setRealTimeCashAddress: "/setRealTimeCashAddress",
  search: "/search",
  getEmotes: "/getEmotes",
  getBadges: "/getBadges",
  getViewerList: "/getViewerList",
  getStatistics: "/getStatistics",
  embedRedirect: "/embedRedirect",
  metadata: "/metadata",
  eventsub: "/twitch/eventsub",
  kickWebhook: "/kick/webhook",
  alchemyWebhook: "/alchemy/webhook",
  unsubscribe: "job:unsubscribe",
  updateKickChannelMetadata: "job:updateKickChannelMetadata",
  updateFollowerAndViewerCount: "job:updateFollowerAndViewerCount",
});
const providerFunctions = new Set([
  "eventsub",
  "kickWebhook",
  "alchemyWebhook",
  "subscribe",
]);
function required(value, message) {
  if (!value) throw new Error(message);
}
export function validateEvidence(name, evidence, now = Date.now()) {
  required(
    Object.hasOwn(replacements, name),
    "Function is not a reviewed retirement target; auth must remain deployed"
  );
  required(
    evidence.project === PROJECT && evidence.function === name,
    "Evidence must name this project and function"
  );
  required(
    evidence.replacement === replacements[name],
    "Evidence must match the exact replacement"
  );
  required(
    typeof evidence.reviewedBy === "string" && evidence.reviewedBy.trim(),
    "A reviewer is required"
  );
  required(
    typeof evidence.oldClientPolicy === "string" &&
      evidence.oldClientPolicy.trim(),
    "An approved old-client compatibility/cutoff policy is required"
  );
  required(
    /^[a-f0-9]{7,40}$/.test(evidence.rollbackRevision ?? ""),
    "An immutable rollback revision is required"
  );
  const at = Date.parse(evidence.verifiedAt);
  required(
    Number.isFinite(at) && at <= now && now - at <= 7 * 86400000,
    "Verification evidence must be no more than seven days old"
  );
  required(
    evidence.registeredReplacementVerified === true &&
      evidence.liveSmokeTestVerified === true,
    "Registered replacement and live smoke-test evidence are required"
  );
  required(
    evidence.trafficDrainedVerified === true,
    "Legacy traffic must be drained before deletion"
  );
  if (providerFunctions.has(name))
    required(
      evidence.providerSwitchVerified === true,
      "Provider callback/subscription switch evidence is required"
    );
  if (replacements[name].startsWith("job:"))
    required(
      evidence.scheduleHandoffVerified === true,
      "Schedule/lease ownership handoff evidence is required"
    );
}
export function deleteArguments(name, live) {
  required(
    Object.hasOwn(replacements, name),
    "Function is not a retirement target"
  );
  const record = live.find(
    (item) =>
      item.name === name ||
      item.name === `projects/${PROJECT}/locations/${REGION}/functions/${name}`
  );
  required(record, "Function is absent from the project-scoped live inventory");
  required(
    (record.environment ?? "GEN_1") === "GEN_1",
    "Unexpected generation: review gen2 explicitly before deletion"
  );
  return [
    "functions",
    "delete",
    name,
    `--project=${PROJECT}`,
    `--region=${REGION}`,
    "--quiet",
  ];
}
export function main(
  argv,
  run = (args) =>
    execFileSync("gcloud", args, {
      encoding: "utf8",
      maxBuffer: 8 * 1024 * 1024,
    }),
  output = console.log
) {
  const { values } = parseArgs({
    args: argv,
    options: {
      function: { type: "string" },
      evidence: { type: "string" },
      execute: { type: "boolean", default: false },
      "confirm-project": { type: "string" },
    },
  });
  // Reject unsafe execution before making any cloud call.
  if (values.execute) {
    required(
      values["confirm-project"] === PROJECT,
      `Execution requires --confirm-project ${PROJECT}`
    );
    required(
      values.function && values.evidence,
      "Execution requires one --function and an --evidence JSON file"
    );
  }
  if (values.function)
    required(
      Object.hasOwn(replacements, values.function),
      "Function is not a retirement target; auth is preserved"
    );
  const live = JSON.parse(
    run(["functions", "list", `--project=${PROJECT}`, "--format=json"])
  );
  const schedules = JSON.parse(
    run([
      "scheduler",
      "jobs",
      "list",
      `--project=${PROJECT}`,
      `--location=${REGION}`,
      "--format=json",
    ])
  );
  const topics = JSON.parse(
    run(["pubsub", "topics", "list", `--project=${PROJECT}`, "--format=json"])
  );
  output(
    JSON.stringify(
      {
        project: PROJECT,
        functions: live.map((item) => ({
          name: item.name,
          environment: item.environment ?? "GEN_1",
          status: item.status ?? item.state,
        })),
        schedules: schedules.map((item) => ({
          name: item.name,
          state: item.state,
          schedule: item.schedule,
          topic: item.pubsubTarget?.topicName,
        })),
        topics: topics.map((item) => item.name),
      },
      null,
      2
    )
  );
  const names = values.function ? [values.function] : Object.keys(replacements);
  for (const name of names) {
    const args = deleteArguments(name, live);
    output(`PLAN: gcloud ${args.join(" ")} -> ${replacements[name]}`);
    if (values.evidence)
      validateEvidence(name, JSON.parse(readFileSync(values.evidence, "utf8")));
    if (values.execute) run(args);
  }
  if (!values.execute)
    output(
      "DRY RUN: no resources changed. Supply reviewed per-function evidence before explicit execution. Preserve auth, Hosting rewrites, shared secrets, rules, and unrelated Pub/Sub resources."
    );
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
