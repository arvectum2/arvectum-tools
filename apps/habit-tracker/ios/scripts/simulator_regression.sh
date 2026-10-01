#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
IOS_DIR="$ROOT/apps/habit-tracker/ios"
PROJECT="$IOS_DIR/HabitsByArvectumIOS.xcodeproj"
SCHEME="HabitsByArvectum"
BUNDLE_ID="ru.arvectum.tools.habits"
WATCH_BUNDLE_ID="ru.arvectum.tools.habits.watch"
WORK="${TMPDIR:-/tmp}/habits-simulator-regression"
DERIVED="$WORK/DerivedData"

mkdir -p "$WORK"

log() {
  printf "\n==> %s\n" "$*"
}

device_udid() {
  local runtime_suffix="$1"
  local preferred_name="$2"
  xcrun simctl list devices -j | python3 -c '
import json
import sys
runtime_suffix, preferred = sys.argv[1], sys.argv[2]
data = json.load(sys.stdin)["devices"]
runtime_key = next((key for key in data if key.endswith(runtime_suffix)), None)
if runtime_key is None:
    raise SystemExit(1)
available = [d for d in data[runtime_key] if d.get("isAvailable", True)]
preferred_device = next((d for d in available if d["name"] == preferred), None)
device = preferred_device or (available[0] if available else None)
if device is None:
    raise SystemExit(1)
print(device["udid"])
' "$runtime_suffix" "$preferred_name"
}

connected_pair() {
  xcrun simctl list pairs -j | python3 -c '
import json
import sys
pairs = json.load(sys.stdin).get("pairs", {})
for pair in pairs.values():
    if "connected" in pair.get("state", ""):
        print(pair["phone"]["udid"], pair["watch"]["udid"])
        raise SystemExit(0)
raise SystemExit(1)
'
}

boot_device() {
  local udid="$1"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
}

log "Release hygiene"
cd "$IOS_DIR"
python3 scripts/release_hygiene.py

log "Generate Xcode project"
xcodegen generate >/dev/null

IOS26="$(device_udid 'iOS-26-5' 'iPhone 17 Pro')"
boot_device "$IOS26"

log "Full iOS 26.5 test suite"
rm -rf "$DERIVED"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$IOS26" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  test >"$WORK/ios26-tests.log" 2>&1
grep -E "Executed [0-9]+ tests|TEST SUCCEEDED|TEST FAILED" "$WORK/ios26-tests.log" | tail -12

IOS27="$(device_udid 'iOS-27-0' 'iPhone 18 Pro Max')"
boot_device "$IOS27"

log "iOS 27 + embedded Watch/widget build"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$IOS27" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  build >"$WORK/ios27-build.log" 2>&1
grep -E "BUILD SUCCEEDED|BUILD FAILED|warning:|error:" "$WORK/ios27-build.log" | tail -20

read -r PAIR_PHONE PAIR_WATCH < <(connected_pair)
boot_device "$PAIR_PHONE"
boot_device "$PAIR_WATCH"

APP="$DERIVED/Build/Products/Debug-iphonesimulator/HabitsByArvectum.app"
WATCH_APP="$APP/Watch/HabitsByArvectumWatch.app"

if [[ ! -d "$APP" || ! -d "$WATCH_APP" ]]; then
  log "Rebuild for paired iPhone simulator"
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "id=$PAIR_PHONE" \
    -derivedDataPath "$DERIVED" \
    CODE_SIGNING_ALLOWED=NO \
    build >"$WORK/pair-build.log" 2>&1
fi

log "Paired iPhone ↔ Watch live-sync smoke"
xcrun simctl terminate "$PAIR_PHONE" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl terminate "$PAIR_WATCH" "$WATCH_BUNDLE_ID" 2>/dev/null || true
xcrun simctl uninstall "$PAIR_PHONE" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl uninstall "$PAIR_WATCH" "$WATCH_BUNDLE_ID" 2>/dev/null || true

xcrun simctl install "$PAIR_PHONE" "$APP"
xcrun simctl install "$PAIR_WATCH" "$WATCH_APP"

xcrun simctl spawn "$PAIR_PHONE" log erase --all >/dev/null 2>&1 || true
xcrun simctl spawn "$PAIR_WATCH" log erase --all >/dev/null 2>&1 || true

xcrun simctl launch --terminate-running-process "$PAIR_PHONE" "$BUNDLE_ID" \
  --ui-testing \
  --seed-watch-sync-demo \
  --diagnose-watch-sync \
  --disable-cloud-sync >/dev/null
sleep 2

xcrun simctl launch --terminate-running-process "$PAIR_WATCH" "$WATCH_BUNDLE_ID" \
  --diagnose-watch-sync \
  --auto-toggle-first-habit >/dev/null

SYNC_OK=0
for _ in $(seq 1 15); do
  sleep 2

  xcrun simctl spawn "$PAIR_PHONE" log show \
    --style compact \
    --last 1m \
    --predicate 'process == "HabitsByArvectum" AND eventMessage CONTAINS "HABITS_"' \
    >"$WORK/phone-sync.log" 2>/dev/null || true

  xcrun simctl spawn "$PAIR_WATCH" log show \
    --style compact \
    --last 1m \
    --predicate 'process == "HabitsByArvectumWatch" AND eventMessage CONTAINS "HABITS_"' \
    >"$WORK/watch-sync.log" 2>/dev/null || true

  if grep -q "HABITS_PHONE_COMMAND .*completed=true" "$WORK/phone-sync.log" &&
     grep -q "HABITS_WATCH_SNAPSHOT .*pending=0" "$WORK/watch-sync.log"; then
    SYNC_OK=1
    break
  fi
done

if [[ "$SYNC_OK" != "1" ]]; then
  echo "Paired Watch live sync did not converge within 30 seconds" >&2
  echo "--- phone ---" >&2
  tail -80 "$WORK/phone-sync.log" >&2
  echo "--- watch ---" >&2
  tail -80 "$WORK/watch-sync.log" >&2
  exit 1
fi

tail -20 "$WORK/phone-sync.log"
tail -20 "$WORK/watch-sync.log"

log "Regression passed"
printf "iOS 26.5 tests: PASS\n"
printf "iOS 27 build: PASS\n"
printf "paired Watch live sync: PASS\n"
printf "artifacts/logs: %s\n" "$WORK"
