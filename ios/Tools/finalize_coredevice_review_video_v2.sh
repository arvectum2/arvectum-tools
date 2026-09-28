#!/bin/zsh
set -euo pipefail

ROOT="/Users/master/arvectum-tools/ios/review-video/final"
RAW="$ROOT/photo-pod-razmer-0.4.2-2-AppReview.hevc"
FPS_FILE="$ROOT/capture-fps.txt"
MOV="$ROOT/photo-pod-razmer-0.4.2-2-AppReview.mov"
TIMELINE="$ROOT/timeline"
SHEET="$ROOT/timeline-contact.jpg"

[[ -s "$RAW" ]] || { echo "Missing raw CoreDevice HEVC: $RAW" >&2; exit 20; }
for p in 01-weight-result.png 02-pixels-result.png 03-passport-settings.png 04-passport-crop.png 05-passport-result.png; do
  [[ -s "$ROOT/$p" ]] || { echo "Missing control screenshot: $p" >&2; exit 21; }
done

FPS=$(python3 - "$FPS_FILE" <<'PY'
import sys
try:
    v=float(open(sys.argv[1]).read().strip())
except Exception:
    v=30.0
if not (1 <= v <= 120):
    v=30.0
print(f"{v:g}")
PY
)
echo "Capture FPS: $FPS"

rm -f "$MOV" "$SHEET"
rm -rf "$TIMELINE"
mkdir -p "$TIMELINE"

ffmpeg -y -v warning   -r "$FPS" -f hevc -i "$RAW"   -c:v h264_videotoolbox -b:v 8M -maxrate 10M -bufsize 16M   -pix_fmt yuv420p -movflags +faststart   "$MOV"

ffprobe -v error -select_streams v:0   -show_entries stream=codec_name,width,height,r_frame_rate   -show_entries format=duration,size -of default=nw=1 "$MOV"

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$MOV")
python3 - "$DUR" "$TIMELINE" "$MOV" <<'PY'
import subprocess,sys
dur=float(sys.argv[1]); out=sys.argv[2]; mov=sys.argv[3]
# 12 frames spanning the entire recording, avoiding exact EOF.
n=12
times=[max(.1,(dur-.2)*i/(n-1)) for i in range(n)]
for i,t in enumerate(times):
    p=f"{out}/{i:02d}-{t:.2f}.jpg"
    subprocess.run([
        "ffmpeg","-y","-v","error","-ss",f"{t:.3f}","-i",mov,
        "-frames:v","1","-vf","scale=246:-2",p
    ],check=True)
print("TIMES"," ".join(f"{t:.2f}" for t in times))
PY

ffmpeg -y -v error -pattern_type glob -i "$TIMELINE/*.jpg"   -vf 'tile=4x3:padding=4:margin=4' -frames:v 1 "$SHEET"

echo "FINAL_MOV=$MOV"
echo "CONTACT_SHEET=$SHEET"
echo "SHA256=$(shasum -a 256 "$MOV" | awk '{print $1}')"
