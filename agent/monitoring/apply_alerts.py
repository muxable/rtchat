#!/usr/bin/env python3
"""Reconcile agent alerts; defaults to a read-only plan. Use --apply to write."""
import argparse
import copy
import json
from pathlib import Path
import subprocess
import urllib.parse
import urllib.request

PROJECT = "rtchat-47692"
BASE = "https://monitoring.googleapis.com/v3/"


def plan(policies):
    by_name = {}
    for policy in policies:
        name = policy["displayName"]
        if name in by_name:
            raise ValueError(f"Ambiguous alert policy: {name}")
        by_name[name] = policy
    cpu = copy.deepcopy(by_name["CPU utilization"])
    conditions = cpu["conditions"]
    for condition in conditions:
        threshold = condition.get("conditionThreshold", {})
        threshold["filter"] = threshold.get("filter", "").replace(
            'instance_group = "agent-small-us-central1"',
            'instance_group = "agent-small-us-west1"',
        )
    changes = []
    if conditions != by_name["CPU utilization"]["conditions"]:
        changes.append((cpu["name"] + "?updateMask=conditions", {"conditions": conditions}, "PATCH"))
    issues = json.loads((Path(__file__).parent / "alerts/issues.json").read_text())
    old = by_name.get(issues["displayName"])
    issues["notificationChannels"] = (old or by_name["messages"])["notificationChannels"]
    if not issues["notificationChannels"]:
        raise ValueError("Agent issues requires existing notification destinations")
    if old:
        for condition in issues["conditions"]:
            for previous in old["conditions"]:
                if previous["displayName"] == condition["displayName"]:
                    condition["name"] = previous["name"]
        if any(old.get(key) != value for key, value in issues.items()):
            changes.append((old["name"] + "?updateMask=" + ",".join(issues), issues, "PATCH"))
    else:
        changes.append((f"projects/{PROJECT}/alertPolicies", issues, "POST"))
    return changes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    token = subprocess.check_output(["gcloud", "auth", "print-access-token"], text=True).strip()

    def request(path, body=None, method="GET"):
        req = urllib.request.Request(BASE + path, data=None if body is None else json.dumps(body).encode(),
                                     headers={"Authorization": "Bearer " + token, "Content-Type": "application/json"}, method=method)
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)

    policies = []
    page = ""
    while True:
        result = request(f"projects/{PROJECT}/alertPolicies?pageSize=100&pageToken=" + urllib.parse.quote(page))
        policies.extend(result.get("alertPolicies", []))
        page = result.get("nextPageToken")
        if not page:
            break
    for path, body, method in plan(policies):
        print(method, path, json.dumps(body, sort_keys=True))
        if args.apply:
            request(path, body, method)
    print("Alerts applied." if args.apply else "Read-only plan; pass --apply to write.")


if __name__ == "__main__":
    main()
