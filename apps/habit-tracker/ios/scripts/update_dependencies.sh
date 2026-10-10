#!/usr/bin/env bash
set -euo pipefail
IOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$IOS_DIR"
if [[ "${1:-}" != "--review" ]]; then
  echo "Usage: scripts/update_dependencies.sh --review" >&2
  exit 2
fi
scripts/generate_project.sh
generated="HabitsByArvectumIOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
cp Package.resolved /tmp/chickmark-dependency-lock-backup.json
rm "$generated"
xcodebuild -resolvePackageDependencies -project HabitsByArvectumIOS.xcodeproj -scheme HabitsByArvectum
test -s "$generated"
cp "$generated" Package.resolved
python3 scripts/dependency_audit.py
echo "Candidate dependencies resolved. Review lockfile diff, SDK privacy manifests and full tests before commit."
