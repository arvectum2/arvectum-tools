#!/usr/bin/env python3
"""Select a real iPad *simulator* running iOS 27. Never fall back to iPhone."""
import json
import subprocess
import sys


def choose_ipad(simulators):
    matches = []
    for runtime, devices in simulators.get('devices', {}).items():
        if not runtime.startswith('com.apple.CoreSimulator.SimRuntime.iOS-27-'):
            continue
        for d in devices:
            name, udid = d.get('name', ''), d.get('udid')
            if ('ipad' not in name.lower() or not udid or
                    d.get('isAvailable', True) is False or
                    d.get('state') not in ('Booted', 'Shutdown')):
                continue
            priority = (0 if runtime.endswith('iOS-27-0') else 1,
                        0 if 'air' in name.lower() else 1, name.lower())
            matches.append((priority, udid, name))
    return (lambda x: (x[1], x[2]))(min(matches)) if matches else None


def main():
    p = subprocess.run(['xcrun', 'simctl', 'list', 'devices', 'available', '-j'],
                       capture_output=True, text=True, check=True)
    chosen = choose_ipad(json.loads(p.stdout))
    if chosen is None:
        print('BLOCKED: no iOS 27 iPad simulator; iPhone is not a substitute', file=sys.stderr)
        return 2
    udid, name = chosen
    print('iPad simulator: ' + name, file=sys.stderr)
    print(udid)
    return 0


if __name__ == '__main__':
    sys.exit(main())
