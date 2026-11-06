import json
from pathlib import Path
import tempfile
import unittest

from check_translations import check_translations


class CheckTranslationsTest(unittest.TestCase):
    def check(self, messages):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            (path / "app_en.arb").write_text(json.dumps({
                "@@locale": "en",
                "hello": "Hello",
                "@hello": {"description": "A greeting"},
            }), encoding="utf-8")
            (path / "app_fr.arb").write_text(json.dumps(messages), encoding="utf-8")
            return check_translations(path)

    def test_complete_translation_does_not_require_metadata(self):
        self.assertEqual(self.check({"hello": "Bonjour"}), [])

    def test_identical_text_is_allowed(self):
        self.assertEqual(self.check({"hello": "Hello"}), [])

    def test_missing_message_reports_locale_and_key(self):
        self.assertEqual(self.check({}), [
            "app_fr.arb: missing translation for hello",
        ])

    def test_blank_and_invalid_values_are_rejected(self):
        for value in ("", " \n\t", None, 123, {}):
            with self.subTest(value=value):
                self.assertEqual(self.check({"hello": value}), [
                    "app_fr.arb: blank or invalid translation for hello",
                ])

    def test_new_template_message_requires_translation(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            (path / "app_en.arb").write_text(
                json.dumps({"hello": "Hello", "bye": "Goodbye"}), encoding="utf-8")
            (path / "app_fr.arb").write_text(
                json.dumps({"hello": "Bonjour"}), encoding="utf-8")
            self.assertEqual(check_translations(path), [
                "app_fr.arb: missing translation for bye",
            ])


if __name__ == "__main__":
    unittest.main()
