#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IOS_DIR="$ROOT/ios"
DEVICE_NAME="${1:-${ARVECTUM_REVIEW_DEVICE_NAME:-iPhone Nikita}}"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

xcrun devicectl list devices --json-output "$tmp" >/dev/null
python3 - "$tmp" "$DEVICE_NAME" <<'PY'
import json,sys
p=json.load(open(sys.argv[1])); name=sys.argv[2]
m=[d for d in p.get("result",{}).get("devices",[]) if d.get("deviceProperties",{}).get("name")==name]
if not m:
    raise SystemExit(f"ERROR: paired physical iPhone not found: {name}")
d=m[0]
if d.get("connectionProperties",{}).get("tunnelState")=="unavailable":
    raise SystemExit("ERROR: iPhone is not currently available over CoreDevice. Connect USB and unlock it.")
print("Device:",d.get("deviceProperties",{}).get("name"))
print("iOS:",d.get("deviceProperties",{}).get("osVersionNumber"))
PY

echo "Using iOS Physical Device Review Capture workflow:"
echo "  CoreDevice userspace tunnel -> DisplayService raw HEVC"
echo "  -> UniversalHIDService control -> ScreenCaptureService checkpoints"
echo "  -> h264_videotoolbox H.264 MOV"
echo "No QuickTime, camera, AVFoundation camera source, or iPhone Mirroring is used."

"$IOS_DIR/Tools/run_coredevice_review_flow_v2.py"
"$IOS_DIR/Tools/finalize_coredevice_review_video_v2.sh"
