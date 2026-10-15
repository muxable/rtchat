#!/usr/bin/env python3
"""Checks the frameworks embedded in a built iOS app before App Store upload.

App Store Connect rejects a build (ITMS-90208, "does not support the minimum
OS Version specified in the Info.plist") when an embedded framework's binary
needs a newer iOS (its LC_BUILD_VERSION minos) than its Info.plist's
MinimumOSVersion. That happened with onnxruntime.framework when Xcode wrapped
the static ONNX Runtime xcframework from Swift Package Manager in a dynamic
framework (minos 15.5, plist 15.1). ONNX Runtime has to be linked statically.

  check_embedded_frameworks.py path/to/Runner.app [--require-string TEXT]...

Fails if any framework's binary minos > its MinimumOSVersion, if
onnxruntime.framework is embedded, or if a --require-string (e.g. an ONNX
Runtime RTTI name, which survives stripping, unlike its symbols) is in neither
the app binary nor any embedded framework's binary. Pure Python (no Xcode
tools), so it also runs on Linux against an unzipped IPA.
"""

import argparse
import plistlib
import struct
import sys
from pathlib import Path

FAT_MAGIC, FAT_MAGIC_64 = 0xCAFEBABE, 0xCAFEBABF
MH_MAGIC, MH_MAGIC_64 = 0xFEEDFACE, 0xFEEDFACF
LC_VERSION_MIN_IPHONEOS = 0x25
LC_BUILD_VERSION = 0x32
PLATFORM_IOS = 2

FORBIDDEN = {"onnxruntime.framework"}


def slices(data):
    """Yields the offset of each thin Mach-O in a (possibly fat) binary."""
    (magic,) = struct.unpack_from(">I", data, 0)
    if magic in (FAT_MAGIC, FAT_MAGIC_64):
        (count,) = struct.unpack_from(">I", data, 4)
        for i in range(count):
            if magic == FAT_MAGIC:
                offset = struct.unpack_from(">5I", data, 8 + i * 20)[2]
            else:
                offset = struct.unpack_from(">2iQQII", data, 8 + i * 32)[2]
            yield offset
    else:
        yield 0


def load_commands(data, base):
    (magic,) = struct.unpack_from("<I", data, base)
    if magic not in (MH_MAGIC, MH_MAGIC_64):
        raise ValueError("not a little-endian Mach-O")
    ncmds = struct.unpack_from("<I", data, base + 16)[0]
    offset = base + (32 if magic == MH_MAGIC_64 else 28)
    for _ in range(ncmds):
        cmd, size = struct.unpack_from("<II", data, offset)
        yield cmd, offset
        offset += size


def version(packed):
    return (packed >> 16, (packed >> 8) & 0xFF, packed & 0xFF)


def min_os(data):
    """The highest iOS minos over the binary's slices, or None."""
    found = []
    for base in slices(data):
        for cmd, offset in load_commands(data, base):
            if cmd == LC_BUILD_VERSION:
                platform, minos = struct.unpack_from("<II", data, offset + 8)
                if platform == PLATFORM_IOS:
                    found.append(version(minos))
            elif cmd == LC_VERSION_MIN_IPHONEOS:
                found.append(version(struct.unpack_from("<I", data, offset + 8)[0]))
    return max(found) if found else None


def parse_version(text):
    parts = [int(p) for p in str(text).split(".")]
    return tuple((parts + [0, 0, 0])[:3])


def fmt(v):
    return ".".join(map(str, v))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("app", type=Path, help="the .app bundle")
    parser.add_argument("--require-string", action="append", default=[])
    args = parser.parse_args()

    app = args.app
    frameworks = sorted((app / "Frameworks").glob("*.framework"))
    errors = []
    binaries = []
    for framework in frameworks:
        info = plistlib.loads((framework / "Info.plist").read_bytes())
        binary = framework / info.get("CFBundleExecutable", framework.stem)
        data = binary.read_bytes()
        binaries.append((framework.name, data))
        minos = min_os(data)
        plist = info.get("MinimumOSVersion")
        problems = []
        if framework.name in FORBIDDEN:
            problems.append("must not be embedded (link ONNX Runtime statically)")
        if plist is None or minos is None:
            problems.append(f"no {'MinimumOSVersion' if plist is None else 'minos'}")
        elif minos > parse_version(plist):
            problems.append("binary minos > Info.plist MinimumOSVersion (ITMS-90208)")
        status = "FAIL: " + "; ".join(problems) if problems else "ok"
        if problems:
            errors.append(f"{framework.name}: {status}")
        print(
            f"{framework.name:45} minos {fmt(minos) if minos else '?':8} "
            f"plist {plist or '?':8} {status}"
        )

    if args.require_string:
        info = plistlib.loads((app / "Info.plist").read_bytes())
        main_binary = app / info["CFBundleExecutable"]
        binaries.insert(0, (main_binary.name, main_binary.read_bytes()))
        for text in args.require_string:
            where = [name for name, data in binaries if text.encode() in data]
            print(f"{text}: {', '.join(where) if where else 'NOT FOUND'}")
            if not where:
                errors.append(f"{text} is in neither the app binary nor a framework")

    if not frameworks:
        errors.append(f"no frameworks in {app / 'Frameworks'}")
    for error in errors:
        print(f"::error::{error}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
