#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IOS_DIR="$ROOT/ios"
REQUESTED_NAME="${1:-${ARVECTUM_REVIEW_DEVICE_NAME:-}}"
BUNDLE_ID="ru.arvectum.tools.tosize"
ARCHIVE="$IOS_DIR/build/PhotoPodRazmer-0.4.2-2.xcarchive"
APP="$ARCHIVE/Products/Applications/PhotoPodRazmer.app"

tmp=$(mktemp)
profile_plist=$(mktemp)
trap 'rm -f "$tmp" "$profile_plist"' EXIT

xcrun devicectl list devices --json-output "$tmp" >/dev/null
IFS=$'\t' read -r DEVICE_ID UDID OS_VERSION DEV_MODE TUNNEL DEVICE_NAME MODEL <<<"$(python3 - "$tmp" "$REQUESTED_NAME" <<'PY'
import json, sys
p=json.load(open(sys.argv[1]))
requested=sys.argv[2]
devices=[
    d for d in p.get("result",{}).get("devices",[])
    if d.get("hardwareProperties",{}).get("platform")=="iOS"
    and d.get("hardwareProperties",{}).get("reality")=="physical"
]
if requested:
    devices=[d for d in devices if d.get("deviceProperties",{}).get("name")==requested]
if not devices:
    raise SystemExit("No matching physical iPhone is paired with this Mac")
devices.sort(key=lambda d:d.get("connectionProperties",{}).get("lastConnectionDate",""),reverse=True)
d=devices[0]
print("\t".join([
    d.get("identifier",""),
    d.get("hardwareProperties",{}).get("udid",""),
    d.get("deviceProperties",{}).get("osVersionNumber",""),
    d.get("deviceProperties",{}).get("developerModeStatus",""),
    d.get("connectionProperties",{}).get("tunnelState",""),
    d.get("deviceProperties",{}).get("name","iPhone"),
    d.get("hardwareProperties",{}).get("marketingName","iPhone"),
]))
PY
)"

echo "Review device: $MODEL / iOS $OS_VERSION"
echo "Developer Mode: $DEV_MODE"
echo "Connection: $TUNNEL"

if [[ "$TUNNEL" == "unavailable" || -z "$DEVICE_ID" ]]; then
  echo "ERROR: iPhone is paired but not currently available. Connect it by USB, unlock it, and approve Trust if prompted." >&2
  exit 20
fi
[[ "$DEV_MODE" == "enabled" ]] || {
  echo "ERROR: Developer Mode is not enabled on the iPhone." >&2
  exit 21
}
[[ -d "$APP" ]] || {
  echo "ERROR: physical-review archive is missing: $ARCHIVE" >&2
  exit 22
}

IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Info.plist")
STYLE=$(/usr/libexec/PlistBuddy -c 'Print :UIUserInterfaceStyle' "$APP/Info.plist")

if [[ "$IDENTIFIER" != "$BUNDLE_ID" || "$VERSION" != "0.4.2" || "$BUILD" != "2" || "$STYLE" != "Light" ]]; then
  echo "ERROR: archive does not match review build 0.4.2 (2) / Light." >&2
  exit 23
fi

security cms -D -i "$APP/embedded.mobileprovision" > "$profile_plist"
if ! /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' "$profile_plist" | grep -q "$UDID"; then
  echo "ERROR: development profile does not include the connected iPhone." >&2
  exit 24
fi
GET_TASK_ALLOW=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:get-task-allow' "$profile_plist")
[[ "$GET_TASK_ALLOW" == "true" ]] || {
  echo "ERROR: archive copy is not development-signed." >&2
  exit 25
}

codesign --verify --deep --strict "$APP"
echo "Installing Фото под размер $VERSION ($BUILD) from the physical-review archive..."
xcrun devicectl device install app --device "$DEVICE_ID" "$APP"

echo "Launching with CoreDevice..."
xcrun devicectl device process launch --device "$DEVICE_ID" --terminate-existing "$BUNDLE_ID"

echo
echo "READY: Фото под размер $VERSION ($BUILD) is installed and launched on $MODEL / iOS $OS_VERSION."
