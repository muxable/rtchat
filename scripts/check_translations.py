"""Reject missing or blank ARB messages before Flutter can fall back to English."""

import json
from pathlib import Path
import sys


ARB_DIR = Path(__file__).resolve().parents[1] / "lib" / "l10n"


def check_translations(arb_dir):
    template = json.loads((arb_dir / "app_en.arb").read_text(encoding="utf-8"))
    keys = {key for key in template if not key.startswith("@")}
    errors = []
    for path in sorted(arb_dir.glob("*.arb")):
        messages = json.loads(path.read_text(encoding="utf-8"))
        for key in sorted(keys):
            if key not in messages:
                errors.append(f"{path.name}: missing translation for {key}")
            elif not isinstance(messages[key], str) or not messages[key].strip():
                errors.append(f"{path.name}: blank or invalid translation for {key}")
    return errors


def main():
    errors = check_translations(ARB_DIR)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print("All ARB messages have nonempty translations.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
