#!/usr/bin/env python3
"""Run iPad XCUITest with strict case evidence and bounded Xcode teardown.

Xcode 27 may keep the runner alive after XCTest explicitly reports every
selected case and the Selected tests suite PASS. A hung cleanup is distinct
from a failed test. Never report pass without exact XCTest evidence.
"""
import argparse
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time


def verified(log: str, expected: list[str]) -> bool:
    if not expected or '** TEST FAILED **' in log:
        return False
    if re.search(r"Test (Case|Suite) '[^']+' failed", log):
        return False
    if re.search(r'with [1-9]\d* failures', log):
        return False
    if "Test Suite 'Selected tests' passed" not in log:
        return False
    noun = 'test' if len(expected) == 1 else 'tests'
    if f'Executed {len(expected)} {noun}, with 0 failures' not in log:
        return False
    return all(f" {test}]' passed" in log for test in expected)


def halt(process: subprocess.Popen):
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=6)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait(timeout=6)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--log', required=True)
    parser.add_argument('--expected', action='append', required=True,
                        help='Exact XCTest method name. Repeat for each selected test.')
    parser.add_argument('--max-seconds', type=int, default=1350)
    parser.add_argument('--teardown-grace', type=int, default=25)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ['--'] else args.command
    if not command:
        parser.error('Expected a test runner command after --')
    path = Path(args.log)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('w') as output:
        p = subprocess.Popen(command, stdout=output, stderr=subprocess.STDOUT,
                             start_new_session=True)
        deadline = time.monotonic() + args.max_seconds
        passed_at = None
        try:
            while time.monotonic() < deadline:
                status = p.poll()
                contents = path.read_text(errors='replace')
                passed = verified(contents, args.expected)
                if status is not None:
                    print(contents[-6000:])
                    if status == 0 and passed:
                        print('XCODEBUILD TEST SUCCEEDED; exact iPad XCTest cases verified')
                        return 0
                    print(f'FAILED: xcodebuild exit {status}; exact selected XCTest evidence={passed}', file=sys.stderr)
                    return 1
                if passed:
                    if passed_at is None:
                        passed_at = time.monotonic()
                    elif time.monotonic() - passed_at >= args.teardown_grace:
                        print(contents[-6000:])
                        print('XCTEST CASES PASS, SELECTED SUITE PASS; '
                              'Xcode 27 teardown stalled after grace. '
                              'Terminating only this test process group; '
                              'no xcodebuild clean-exit claim.')
                        halt(p)
                        return 0
                time.sleep(3)
            print(path.read_text(errors='replace')[-6000:])
            print('FAILED: real XCTest evidence not complete before deadline', file=sys.stderr)
            return 1
        finally:
            halt(p)


if __name__ == '__main__':
    sys.exit(main())
