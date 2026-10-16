import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  main,
  PROJECT,
  replacements,
  validateEvidence,
  deleteArguments,
} from "./retire.mjs";
const live = Object.keys(replacements)
  .concat("auth")
  .map((name) => ({ name, environment: "GEN_1", status: "ACTIVE" }));
const evidence = {
  project: PROJECT,
  function: "send",
  replacement: "/send",
  reviewedBy: "reviewer",
  oldClientPolicy: "approved supported-version cutoff",
  rollbackRevision: "da3989b",
  verifiedAt: new Date().toISOString(),
  registeredReplacementVerified: true,
  liveSmokeTestVerified: true,
  trafficDrainedVerified: true,
};
test("default inventories and plans all 23 targets without mutations", () => {
  const commands = [];
  const output = [];
  main(
    [],
    (args) => {
      commands.push(args);
      return JSON.stringify(args[0] === "functions" ? live : []);
    },
    (value) => output.push(value)
  );
  assert.equal(commands.length, 3);
  assert.ok(
    commands.every(
      (args) =>
        args.includes(`--project=${PROJECT}`) && !args.includes("delete")
    )
  );
  assert.equal(output.filter((value) => value.startsWith("PLAN:")).length, 23);
  assert.ok(output.at(-1).startsWith("DRY RUN"));
});
test("auth and execution without evidence fail before cloud access", () => {
  const run = () => {
    throw new Error("unexpected cloud access");
  };
  assert.throws(() => main(["--function", "auth"], run), /preserved/);
  assert.throws(
    () => main(["--execute", "--function", "send"], run),
    /confirm-project/
  );
  assert.throws(
    () =>
      main(
        ["--execute", "--confirm-project", PROJECT, "--function", "send"],
        run
      ),
    /evidence/
  );
});
test("per-function deletion never accepts auth, absent functions or unexpected generation", () => {
  assert.throws(() => deleteArguments("auth", live));
  assert.throws(() => deleteArguments("send", []));
  assert.throws(() =>
    deleteArguments("send", [{ name: "send", environment: "GEN_2" }])
  );
  assert.deepEqual(deleteArguments("send", live), [
    "functions",
    "delete",
    "send",
    `--project=${PROJECT}`,
    "--region=us-central1",
    "--quiet",
  ]);
});
test("evidence rejects wrong target, missing live checks, stale dates and missing cutoff policy", () => {
  validateEvidence("send", evidence);
  for (const patch of [
    { project: "wrong" },
    { function: "ban" },
    { replacement: "/wrong" },
    { liveSmokeTestVerified: false },
    { trafficDrainedVerified: false },
    { oldClientPolicy: "" },
    { verifiedAt: "2020-01-01" },
    { rollbackRevision: "main" },
  ])
    assert.throws(() => validateEvidence("send", { ...evidence, ...patch }));
});
test("provider and scheduled deletions require their own handoff evidence", () => {
  const provider = {
    ...evidence,
    function: "alchemyWebhook",
    replacement: "/alchemy/webhook",
  };
  assert.throws(() => validateEvidence("alchemyWebhook", provider), /Provider/);
  validateEvidence("alchemyWebhook", {
    ...provider,
    providerSwitchVerified: true,
  });
  const job = {
    ...evidence,
    function: "unsubscribe",
    replacement: "job:unsubscribe",
  };
  assert.throws(() => validateEvidence("unsubscribe", job), /Schedule/);
  validateEvidence("unsubscribe", { ...job, scheduleHandoffVerified: true });
});

test("explicit execution deletes exactly one reviewed function", () => {
  const directory = mkdtempSync(join(tmpdir(), "rtchat-retirement-test-"));
  try {
    const file = join(directory, "evidence.json");
    writeFileSync(file, JSON.stringify(evidence));
    const commands = [];
    main(
      [
        "--execute",
        "--confirm-project",
        PROJECT,
        "--function",
        "send",
        "--evidence",
        file,
      ],
      (args) => {
        commands.push(args);
        return JSON.stringify(
          args[0] === "functions" && args[1] === "list" ? live : []
        );
      },
      () => {}
    );
    const deletes = commands.filter((args) => args.includes("delete"));
    assert.deepEqual(deletes, [deleteArguments("send", live)]);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
