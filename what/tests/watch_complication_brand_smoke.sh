#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$REPO/what/ios"
APP_ICON="$SRC/WhatWatch/Assets.xcassets/AppIcon.appiconset/WhatWatchIcon.png"
WIDGET_ICON="$SRC/WhatWatchComplication/Assets.xcassets/WhatComplicationIcon.imageset/WhatComplicationIcon.png"
VIEW="$SRC/WhatWatchComplication/WhatComplication.swift"
VECTOR="$SRC/WhatWatchComplication/WhatComplicationMark.swift"
GENERATOR="$SRC/tools/generate_brand.swift"
cmp "$APP_ICON" "$WIDGET_ICON"
grep -q 'Image("WhatComplicationIcon")' "$VIEW"
grep -q 'renderingMode == .fullColor' "$VIEW"
grep -q 'WhatComplicationMark()' "$VIEW"
grep -q '.accessoryCorner' "$VIEW"
grep -q 'widgetURL(captureURL)' "$VIEW"
grep -q 'struct WhatComplicationMark: Shape' "$VECTOR"
grep -q 'WhatComplicationIcon.imageset/WhatComplicationIcon.png' "$GENERATOR"
if grep -Eq 'systemName: *"mic"|Image\(systemName: *"mic' "$VIEW"; then
  echo 'WATCH BRAND REGRESSION: system microphone used instead of UhWhat icon' >&2
  exit 1
fi
python3 - "$GENERATOR" "$VECTOR" <<'PYBRAND'
import sys,re
from pathlib import Path
brand=Path(sys.argv[1]).read_text()
source=Path(sys.argv[2]).read_text()
contours=re.findall(r'"(M[0-9, ]+Z)"',brand)
actual=[]
for block in source.split('// Official UhWhat app icon contour ')[1:]:
    block=block.split('        p.closeSubpath()',1)[0]
    actual.append([(int(x),int(y)) for x,y in re.findall(r'CGPoint\(x: (\d+), y: (\d+)\)',block)])
expected=[[(int(p.split(',')[0]),int(p.split(',')[1])) for p in c[1:-1].split(' ')] for c in contours]
assert actual==expected, 'Official app glyph contours drifted from the Watch widget vector'
print('PASS: full vector contours match the official app-icon generator')
PYBRAND
echo 'PASS: exact Watch icon bytes, system tint-safe brand shape, full-color icon and one-tap deep link'
