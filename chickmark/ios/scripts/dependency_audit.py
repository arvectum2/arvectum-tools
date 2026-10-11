#!/usr/bin/env python3
"""Conservative, offline SPM dependency policy and lock consistency checks."""
import json
import re
import sys
from pathlib import Path
IOS = Path(__file__).resolve().parents[1]
yaml = (IOS / "project.yml").read_text()
p = IOS / "Package.resolved"
errors = []
if "exactVersion:" in yaml or "branch:" in yaml or "revision:" in yaml:
    errors.append("Direct dependency must use a semver-compatible minimum, not an exact/branch/revision.")
m = re.search(r"YandexMobileAds:\s+url:\s+https://github.com/yandexmobile/yandex-ads-sdk-ios\s+version:\s+(\d+)\.(\d+)\.(\d+)", yaml)
if not m:
    errors.append("Missing Yandex semver floor in project.yml.")
try:
    j = json.loads(p.read_text())
    pins = j["pins"]
    by_id = {x["identity"]: x for x in pins}
    if len(by_id) != len(pins):
        errors.append("Duplicate package identities in lockfile.")
    expected = {
        "yandex-ads-sdk-ios", "appmetrica-sdk-ios", "kscrash",
        "swift-package-manager-google-user-messaging-platform", "swift-protobuf"
    }
    if set(by_id) != expected:
        errors.append("Unexpected changed package graph: " + str(sorted(set(by_id) ^ expected)))
    direct = by_id.get("yandex-ads-sdk-ios")
    if not direct:
        errors.append("Yandex dependency missing from tracked lockfile.")
    elif m:
        minimum = tuple(map(int, m.groups()))
        version = tuple(int(x) for x in direct["state"]["version"].split(".")[:3])
        if version < minimum or version[0] != minimum[0]:
            errors.append("Yandex locked version outside approved semver major range.")
    for x in pins:
        if x.get("kind") != "remoteSourceControl":
            errors.append("Non source-control dependency: " + x.get("identity", "?"))
        if not re.fullmatch(r"[a-f0-9]{40}", x.get("state", {}).get("revision", "")):
            errors.append("Unverifiable source revision for " + x.get("identity", "?"))
        if not re.fullmatch(r"\d+\.\d+\.\d+", x.get("state", {}).get("version", "")):
            errors.append("Unstable semantic version for " + x.get("identity", "?"))
except (OSError, KeyError, ValueError, TypeError) as exc:
    errors.append("Cannot parse tracked lockfile: " + str(exc))
generated = IOS / "HabitsByArvectumIOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if generated.is_file() and generated.read_bytes() != p.read_bytes():
    errors.append("Generated project lock differs from committed lock; run scripts/generate_project.sh.")
if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
print("SPM audit: compatible direct semver floor, five pinned packages, source revisions and generated lock consistent.")
