#!/usr/bin/env python3
"""Validate embedded iOS framework deployment targets before app signing.

SPM can wrap ONNX Runtime's static binary in a dynamic framework built for
Runner's deployment target, while copying its original Info.plist. Repair that
specific mismatch and re-sign the framework. Other mismatches fail the build.
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


def validate(app, repair_onnx=False):
    app = Path(app)
    with (app / 'Info.plist').open('rb') as source:
        app_minimum = plistlib.load(source)['MinimumOSVersion']
    for framework in sorted((app / 'Frameworks').glob('*.framework')):
        plist = framework / 'Info.plist'
        with plist.open('rb') as source:
            info = plistlib.load(source)
        binary = framework / info['CFBundleExecutable']
        required = minimum_os(binary)
        if version(required) > version(app_minimum):
            raise ValueError(f'{framework.name} requires iOS {required}, but app declares {app_minimum}')
        declared = info.get('MinimumOSVersion', '0.0')
        if version(declared) >= version(required):
            continue
        if not repair_onnx or framework.name != 'onnxruntime.framework':
            raise ValueError(f'{framework.name}: binary requires iOS {required}, plist declares {declared}')
        info['MinimumOSVersion'] = required
        with plist.open('wb') as destination:
            plistlib.dump(info, destination, fmt=plistlib.FMT_BINARY)
        if os.environ.get('CODE_SIGNING_ALLOWED') != 'NO':
            identity = os.environ.get('EXPANDED_CODE_SIGN_IDENTITY')
            if not identity:
                raise ValueError('Cannot re-sign repaired ONNX Runtime without a signing identity')
            subprocess.run(
                ['codesign', '--force', '--sign', identity,
                 '--preserve-metadata=identifier,entitlements,flags', str(framework)],
                check=True,
            )
        print(f'Updated {framework.name}: MinimumOSVersion {declared} -> {required}')
    print(f'Framework deployment targets validated: {app}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('--repair-onnx', action='store_true')
    args = parser.parse_args()
    validate(args.app, args.repair_onnx)
