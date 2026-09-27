#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IOS_DIR="$ROOT/ios"
REQUESTED_NAME="${1:-${ARVECTUM_REVIEW_DEVICE_NAME:-}}"
BUNDLE_ID="ru.arvectum.tools.tosize"
APP="$IOS_DIR/build/PhysicalReview/PhotoPodRazmer.app"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
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
if [[ "$DEV_MODE" != "enabled" ]]; then
  echo "ERROR: Developer Mode is not enabled on the iPhone." >&2
  exit 21
fi

if [[ ! -d "$APP" ]]; then
  echo "Preparing an installable copy of the submitted 0.4.2 (1) archive..."
  "$IOS_DIR/Tools/prepare_physical_app.sh"
fi

IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Info.plist")
if [[ "$IDENTIFIER" != "$BUNDLE_ID" || "$VERSION" != "0.4.2" || "$BUILD" != "1" ]]; then
  echo "ERROR: prepared app does not match submitted 0.4.2 (1)." >&2
  exit 22
fi
profile_plist=$(mktemp)
security cms -D -i "$APP/embedded.mobileprovision" > "$profile_plist"
if ! /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' "$profile_plist" | grep -q "$UDID"; then
  rm -f "$profile_plist"
  echo "ERROR: development profile does not include the connected iPhone." >&2
  exit 23
fi
GET_TASK_ALLOW=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:get-task-allow' "$profile_plist")
rm -f "$profile_plist"
[[ "$GET_TASK_ALLOW" == "true" ]] || {
  echo "ERROR: prepared app is not development-signed." >&2
  exit 24
}

codesign --verify --deep --strict "$APP"
echo "Prepared app: $VERSION ($BUILD), development-signed copy of submitted archive."

echo "Installing on physical iPhone..."
xcrun devicectl device install app --device "$DEVICE_ID" "$APP"

echo "Launching..."
xcrun devicectl device process launch   --device "$DEVICE_ID"   --terminate-existing   "$BUNDLE_ID"

echo
echo "READY: Фото под размер $VERSION ($BUILD) is installed and launched on $MODEL / iOS $OS_VERSION."
