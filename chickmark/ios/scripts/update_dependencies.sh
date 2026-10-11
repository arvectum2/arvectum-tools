#!/usr/bin/env bash
# Explicit semver floor update, intended ONLY for an isolated review branch.
set -euo pipefail
IOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$IOS_DIR"
if [[ "$#" != 2 || "$1" != "--review" || ! "$2" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: scripts/update_dependencies.sh --review 8.6.0" >&2
  echo "Run in a disposable upgrade branch/worktree. No production lock is changed automatically." >&2
  exit 2
fi
CANDIDATE="$2"
python3 - "$CANDIDATE" <<'PY'
import re, sys
from pathlib import Path
p=Path("project.yml")
text=p.read_text()
new, count=re.subn(
    r"(YandexMobileAds:\s+url:\s+https://github.com/yandexmobile/yandex-ads-sdk-ios\s+version:\s+)\d+\.\d+\.\d+",
    lambda m: m.group(1)+sys.argv[1], text, count=1
)
if count != 1: raise SystemExit("Cannot find unique Yandex SDK semver floor")
p.write_text(new)
PY
xcodegen generate
GENERATED="HabitsByArvectumIOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
rm -f "$GENERATED"
xcodebuild -resolvePackageDependencies -project HabitsByArvectumIOS.xcodeproj -scheme HabitsByArvectum
test -s "$GENERATED"
cp "$GENERATED" Package.resolved
echo "=== Candidate dependency graph ==="
python3 - <<'PY'
import json
from pathlib import Path
j=json.loads(Path("Package.resolved").read_text())
for item in sorted(j["pins"], key=lambda x: x["identity"]):
 print(item["identity"], item["state"]["version"])
PY
echo "=== Approval gate ==="
if ! python3 scripts/dependency_audit.py; then
  echo "BLOCKED: dependency graph or policy changed. Review package privacy and update allowlist ONLY after approval." >&2
  exit 1
fi
echo "Resolved candidate only. Review git diff, SDK privacy manifests, tests, Watch, archive and physical device BEFORE merging."
