#!/usr/bin/env bash
set -eo pipefail

# Repeatable real image processing on the emulator, using synthetic pixels only.
# A DUMP-protected QA receiver exists only in debug, never in release.
THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$THIS_DIR/.." && pwd)"
SDK="$ANDROID_HOME"
if [ -z "$SDK" ]; then SDK="$HOME/Library/Android/sdk"; fi
ADB="$SDK/platform-tools/adb"
EMU="$SDK/emulator/emulator"
AVD="$ARVECTUM_QA_AVD"
if [ -z "$AVD" ]; then AVD=small_phone; fi
OUTPUT="$ARVECTUM_QA_OUTPUT_DIR"
if [ -z "$OUTPUT" ]; then OUTPUT=/Volumes/ArvectumSSD/Arvectum/tmp/photo-android-qa; fi
if [ ! -d /Volumes/ArvectumSSD ]; then
    echo "ArvectumSSD is not mounted; refusing QA output on system disk" >&2
    exit 2
fi
mkdir -p "$OUTPUT"
if [ ! -x "$ADB" ] || [ ! -x "$EMU" ]; then
    echo "Android SDK tools unavailable" >&2; exit 2
fi
SERIAL=emulator-5554
if "$ADB" devices | grep -q "^$SERIAL[[:space:]]"; then
    echo "Existing $SERIAL: refusing to interfere with a running emulator" >&2
    exit 3
fi
if [ "$ARVECTUM_QA_SKIP_BUILD" != 1 ]; then
    if [ -d /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ]; then
        export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
        export PATH="$JAVA_HOME/bin:$PATH"
    fi
    export ANDROID_HOME="$SDK"
    (cd "$APP_DIR" && ./gradlew :app:assembleDebug :app:testDebugUnitTest --offline --no-daemon >"$OUTPUT/gradle.log" 2>&1)
fi
APK="$APP_DIR/app/build/outputs/apk/debug/app-debug.apk"
test -f "$APK" || { echo "Debug APK missing" >&2; exit 3; }
"$EMU" -avd "$AVD" -no-window -no-audio -no-snapshot -no-boot-anim \
    -gpu swiftshader_indirect -memory 2048 >"$OUTPUT/emulator.log" 2>&1 &
emulator_pid=$!
cleanup() {
    "$ADB" -s "$SERIAL" emu kill >/dev/null 2>&1 || true
    kill "$emulator_pid" 2>/dev/null || true
}
trap cleanup EXIT
booted=0
for (( i=0; i<100; i++ )); do
    if [ "$("$ADB" -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; then
        booted=1; break
    fi
    sleep 1
done
if [ "$booted" != 1 ]; then echo "Emulator boot timeout" >&2; exit 4; fi
"$ADB" -s "$SERIAL" install -r "$APK" >"$OUTPUT/install.log"
"$ADB" -s "$SERIAL" shell am broadcast \
    -n ru.arvectum.tools.tosize/.qa.ImagePipelineQaReceiver \
    -a ru.arvectum.tools.tosize.QA_IMAGE_PIPELINE >"$OUTPUT/broadcast.log"
REPORT="$OUTPUT/android-image-pipeline.json"
rm -f "$REPORT"
for (( i=0; i<30; i++ )); do
    if "$ADB" -s "$SERIAL" shell run-as ru.arvectum.tools.tosize \
        cat files/qa-image-pipeline.json >"$REPORT" 2>/dev/null; then
        if [ -s "$REPORT" ]; then break; fi
    fi
    sleep 1
done
test -s "$REPORT" || { echo "QA result missing" >&2; exit 5; }
python3 - "$REPORT" <<'PY'
import json, sys
d=json.load(open(sys.argv[1]))
assert d["status"]=="passed", d
assert (d["sourceWidth"], d["sourceHeight"])==(900,700), d
assert 0 < d["compressedBytes"] <= d["maximumBytes"] == 500_000, d
assert (d["resizedWidth"], d["resizedHeight"])==(400,311), d
assert (d["passportWidth"], d["passportHeight"])==(620,797), d
assert abs(d["passportDpi"]-450)<0.5, d
assert d["savedOutputs"]==3, d
print("PASS: 3 image transformations and saved JPEGs on real Android emulator")
print(json.dumps(d,indent=2))
PY
