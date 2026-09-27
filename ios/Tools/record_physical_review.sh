#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEVICE_NAME="${1:-iPhone Nikita}"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="${2:-$ROOT/ios/review-video/photo-pod-razmer-0.4.2-physical-$STAMP.mov}"

mkdir -p "$(dirname "$OUT")"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

echo "Checking that the paired physical iPhone is available..."
xcrun devicectl list devices --json-output "$tmp" >/dev/null
python3 - "$tmp" "$DEVICE_NAME" <<'PY'
import json, sys
p=json.load(open(sys.argv[1]))
name=sys.argv[2]
m=[d for d in p.get("result",{}).get("devices",[]) if d.get("deviceProperties",{}).get("name")==name]
if not m:
    raise SystemExit("ERROR: paired iPhone not found")
d=m[0]
if d.get("connectionProperties",{}).get("tunnelState")=="unavailable":
    raise SystemExit("ERROR: iPhone is not connected/available")
print("Device:", d["deviceProperties"].get("name"))
print("iOS:", d["deviceProperties"].get("osVersionNumber"))
PY

echo "Discovering the iPhone capture source..."
open -gja "QuickTime Player" || true
sleep 2
LIST=$(ffmpeg -hide_banner -f avfoundation -list_devices true -i "" 2>&1 || true)
print -r -- "$LIST" | sed -n '/AVFoundation video devices:/,/AVFoundation audio devices:/p'

VIDEO_INDEX=$(print -r -- "$LIST" | python3 -c '
import re,sys
text=sys.stdin.read()
candidates=[]
for line in text.splitlines():
    m=re.search(r"\[(\d+)\]\s+(.+)$", line)
    if m:
        candidates.append((m.group(1),m.group(2).strip()))
for idx,name in candidates:
    if "iphone" in name.lower():
        print(idx)
        break
')

if [[ -z "$VIDEO_INDEX" ]]; then
  echo "ERROR: the connected iPhone did not appear as an AVFoundation video source." >&2
  echo "Open QuickTime Player > File > New Movie Recording once, select the iPhone as camera, then rerun this script." >&2
  exit 30
fi

echo
echo "Capture source index: $VIDEO_INDEX"
echo "Output: $OUT"
echo "Start from the iPhone Home Screen, then launch Фото под размер."
echo "Press Ctrl-C after the complete App Review flow is finished."
echo

ffmpeg -hide_banner -y   -f avfoundation   -framerate 30   -i "$VIDEO_INDEX:none"   -an   -c:v h264_videotoolbox   -b:v 8M   -maxrate 10M   -bufsize 16M   -pix_fmt yuv420p   -movflags +faststart   "$OUT"

echo
echo "Recorded: $OUT"
ffprobe -v error   -show_entries format=duration,size   -show_entries stream=codec_name,width,height,r_frame_rate   -of default=noprint_wrappers=1   "$OUT"
