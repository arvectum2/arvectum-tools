#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
IOS_DIR="$ROOT/apps/habit-tracker/ios"
PROJECT="$IOS_DIR/HabitsByArvectumIOS.xcodeproj"
SCHEME="HabitsByArvectum"
WORK="${TMPDIR:-/tmp}/habits-archive-smoke"
ARCHIVE="$WORK/HabitsByArvectum.xcarchive"

rm -rf "$WORK"
mkdir -p "$WORK"
cd "$IOS_DIR"

python3 scripts/release_hygiene.py
xcodegen generate >/dev/null

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  CODE_SIGNING_ALLOWED=NO \
  archive >"$WORK/archive.log" 2>&1

APP="$ARCHIVE/Products/Applications/HabitsByArvectum.app"
PHONE_WIDGET="$APP/PlugIns/HabitsByArvectumWidget.appex"
WATCH_APP="$APP/Watch/HabitsByArvectumWatch.app"
WATCH_WIDGET="$WATCH_APP/PlugIns/HabitsByArvectumWatchWidget.appex"

for bundle in "$APP" "$PHONE_WIDGET" "$WATCH_APP" "$WATCH_WIDGET"; do
  if [[ ! -d "$bundle" ]]; then
    echo "Missing embedded bundle: $bundle" >&2
    exit 1
  fi
  if [[ ! -f "$bundle/PrivacyInfo.xcprivacy" ]]; then
    echo "Missing embedded privacy manifest: $bundle" >&2
    exit 1
  fi
done

version_of() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$1/Info.plist"
}

build_of() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$1/Info.plist"
}

APP_VERSION="$(version_of "$APP")"
APP_BUILD="$(build_of "$APP")"
for bundle in "$PHONE_WIDGET" "$WATCH_APP" "$WATCH_WIDGET"; do
  [[ "$(version_of "$bundle")" == "$APP_VERSION" ]] || {
    echo "Version mismatch in $bundle" >&2
    exit 1
  }
  [[ "$(build_of "$bundle")" == "$APP_BUILD" ]] || {
    echo "Build-number mismatch in $bundle" >&2
    exit 1
  }
done

python3 "$IOS_DIR/scripts/audit_archive.py" "$ARCHIVE" > "$WORK/privacy-audit.json"

grep -q "\*\* ARCHIVE SUCCEEDED \*\*" "$WORK/archive.log"
printf "Archive smoke passed: %s (%s)\n" "$APP_VERSION" "$APP_BUILD"
printf "archive: %s\n" "$ARCHIVE"
