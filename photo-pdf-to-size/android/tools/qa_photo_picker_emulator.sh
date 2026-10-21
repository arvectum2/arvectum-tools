#!/usr/bin/env bash
set -eo pipefail
# Isolated Android GUI E2E on disposable AVD; synthetic image only.
here="$(cd "$(dirname "$0")" && pwd)"
sdk="$HOME/Library/Android/sdk"
if [ -n "$ANDROID_HOME" ]; then sdk="$ANDROID_HOME"; fi
export ANDROID_HOME="$sdk" ANDROID_SDK_ROOT="$sdk"
adb="$sdk/platform-tools/adb"
emu="$sdk/emulator/emulator"
avd=small_phone
if [ -n "$ARVECTUM_QA_AVD" ]; then avd="$ARVECTUM_QA_AVD"; fi
out=/Volumes/ArvectumSSD/Arvectum/tmp/photo-picker-qa
if [ -n "$ARVECTUM_QA_OUTPUT_DIR" ]; then out="$ARVECTUM_QA_OUTPUT_DIR"; fi
case "$out" in /Volumes/ArvectumSSD/*) ;; *)
  echo "QA output must be on ArvectumSSD" >&2;exit 2 ;; esac
test -d /Volumes/ArvectumSSD || { echo "ArvectumSSD missing" >&2;exit 2; }
mkdir -p "$out"
if "$adb" devices | grep -q '^emulator-5554[[:space:]]'; then
  echo "Won't replace existing emulator" >&2;exit 2
fi
if [ "$ARVECTUM_QA_SKIP_BUILD" != 1 ]; then
  if [ -d /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ]; then
    export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
    export PATH="$JAVA_HOME/bin:$PATH"
  fi
  (cd "$here/.." && ./gradlew :app:assembleDebug --offline --no-daemon >"$out/gradle.log" 2>&1)
fi
"$emu" -avd "$avd" -no-window -no-audio -no-snapshot -no-boot-anim -gpu swiftshader_indirect -memory 2048 >"$out/emulator.log" 2>&1 &
pid=$!
cleanup() {
  "$adb" -s emulator-5554 emu kill >/dev/null 2>&1 || true
  kill "$pid" >/dev/null 2>&1 || true
}
trap cleanup EXIT
booted=0
for ((i=0;i<100;i++)); do
  if [ "$("$adb" -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; then
    booted=1;break
  fi
  sleep 1
done
[ "$booted" = 1 ] || { echo "Emulator boot timeout" >&2;exit 3; }
echo "Android emulator booted"
export ARVECTUM_QA_OUTPUT_DIR="$out"
python3 -u "$here/qa_photo_picker_e2e.py" >"$out/flow.log" 2>&1
cat "$out/qa-photo-picker-report.json"
