import copy
import unittest
from apply_alerts import plan


class AlertPlanTest(unittest.TestCase):
    def policies(self):
        return [
            {"displayName": "CPU utilization", "name": "cpu", "conditions": [
                {"name": "cpu/condition", "conditionThreshold": {
                    "filter": 'metadata.system_labels.instance_group = "agent-small-us-central1"',
                    "thresholdValue": 0.8}}]},
            {"displayName": "messages", "notificationChannels": ["existing-channel"]},
        ]

    def test_scope_and_recipients_preserved_and_idempotent(self):
        policies = self.policies()
        original = copy.deepcopy(policies)
        changes = plan(policies)
        self.assertEqual(policies, original)
        self.assertEqual(len(changes), 2)
        conditions = changes[0][1]["conditions"]
        self.assertIn("agent-small-us-west1", conditions[0]["conditionThreshold"]["filter"])
        self.assertEqual(conditions[0]["conditionThreshold"]["thresholdValue"], 0.8)
        self.assertEqual(conditions[0]["name"], "cpu/condition")
        issues = changes[1][1]
        self.assertEqual(issues["notificationChannels"], ["existing-channel"])
        policies[0]["conditions"] = conditions
        issues["name"] = "issues"
        issues["conditions"][0]["name"] = "issues/condition"
        policies.append(issues)
        self.assertEqual(plan(policies), [])

    def test_existing_issue_recipients_are_preserved(self):
        policies = self.policies()
        issues = plan(policies)[1][1]
        issues.update(name="issues", notificationChannels=["custom-channel"])
        issues["conditions"][0]["name"] = "issues/condition"
        issues["enabled"] = False
        policies.append(issues)
        update = plan(policies)[1][1]
        self.assertEqual(update["notificationChannels"], ["custom-channel"])
        self.assertEqual(update["conditions"][0]["name"], "issues/condition")
        self.assertTrue(update["enabled"])
