#!/usr/bin/env python3
"""Repair the embedded ONNX Runtime wrapper before app signing.

SPM can wrap ONNX Runtime's static binary in a dynamic framework built for
Runner's deployment target, while copying its original Info.plist. Repair that
specific mismatch and re-sign the framework.
"""
import argparse
import os
from pathlib import Path
import plistlib
import re
import subprocess


def version(value):
    parts = tuple(int(part) for part in value.split('.'))
    return parts + (0,) * (3 - len(parts))


def minimum_os(binary):
    output = subprocess.check_output(
        ['xcrun', 'vtool', '-show-build', str(binary)], text=True
    )
    # vtool prints minos for LC_BUILD_VERSION and version for the legacy
    # LC_VERSION_MIN_IPHONEOS load command, once for each architecture.
    # LC_BUILD_VERSION also contains a tool's version; that is not an OS target.
    values = []
    command = None
    for line in output.splitlines():
        fields = line.split()
        if len(fields) != 2:
            continue
        key, value = fields
        if key == 'cmd':
            command = value
        elif ((command == 'LC_BUILD_VERSION' and key == 'minos') or
              (command == 'LC_VERSION_MIN_IPHONEOS' and key == 'version')):
            if not re.fullmatch(r'\d+(?:\.\d+){1,2}', value):
                raise ValueError(f'Invalid deployment target {value} in {binary}')
            values.append(value)
    if not values:
        raise ValueError(f'No deployment target found in {binary}')
    return max(values, key=version)


def repair(app):
    framework = Path(app) / 'Frameworks' / 'onnxruntime.framework'
    if not framework.exists():
        return
    plist = framework / 'Info.plist'
    with plist.open('rb') as source:
        info = plistlib.load(source)
    required = minimum_os(framework / info['CFBundleExecutable'])
    declared = info.get('MinimumOSVersion', '0.0')
    if version(declared) >= version(required):
        return
    info['MinimumOSVersion'] = required
    with plist.open('wb') as destination:
        plistlib.dump(info, destination, fmt=plistlib.FMT_BINARY)
    if os.environ.get('CODE_SIGNING_ALLOWED') != 'NO':
        # CI may archive unsigned and apply distribution signing during export.
        identity = os.environ.get('EXPANDED_CODE_SIGN_IDENTITY') or '-'
        subprocess.run(
            ['codesign', '--force', '--sign', identity,
             '--preserve-metadata=identifier,entitlements,flags', str(framework)],
            check=True,
        )
    print(f'Updated {framework.name}: MinimumOSVersion {declared} -> {required}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    args = parser.parse_args()
    repair(args.app)
