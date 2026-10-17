#!/usr/bin/env bash
set -euo pipefail

# Test the real production policy source with a minimal state type.
# WatchKit itself is exercised by the watchOS Xcode build + simulator.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUTPUT_DIR="${1:-${TMPDIR:-/tmp}}"
mkdir -p "$OUTPUT_DIR"
tmp="$(mktemp -d "$OUTPUT_DIR/what-launch-check.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/main.swift" <<'SWIFT'
import Foundation

final class WatchCaptureController {
    enum CaptureState {
        case idle, preparing, recording(Date), saved, error(String)
    }
}
precondition(WatchCaptureLaunchPolicy.shouldAutoStart(.idle))
precondition(WatchCaptureLaunchPolicy.shouldAutoStart(.saved))
precondition(!WatchCaptureLaunchPolicy.shouldAutoStart(.preparing))
precondition(!WatchCaptureLaunchPolicy.shouldAutoStart(.recording(Date())))
precondition(!WatchCaptureLaunchPolicy.shouldAutoStart(.error("denied")))
print("PASS: fresh start, return after save, no duplicate or error restart (5 states)")
SWIFT
swiftc "$ROOT/what/ios/WhatWatch/WatchCaptureLaunchPolicy.swift" "$tmp/main.swift" -o "$tmp/check"
"$tmp/check"
