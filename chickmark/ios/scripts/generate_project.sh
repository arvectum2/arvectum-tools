#!/usr/bin/env bash
set -euo pipefail
IOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$IOS_DIR"
xcodegen generate
LOCK="$IOS_DIR/Package.resolved"
DEST="$IOS_DIR/HabitsByArvectumIOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
test -f "$LOCK" || { echo "Missing tracked Package.resolved" >&2; exit 1; }
mkdir -p "$(dirname "$DEST")"
cp "$LOCK" "$DEST"
python3 "$IOS_DIR/scripts/dependency_audit.py"
echo "Generated project with committed dependency lock."
