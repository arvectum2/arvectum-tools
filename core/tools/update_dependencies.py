#!/usr/bin/env python3
"""Propose stable compatible dependency updates; never change runtime without code review."""
from __future__ import annotations
import argparse
import json
import re
import tomllib
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
UA = {"User-Agent": "ArvectumTools-DependencyAuditor/1.0"}
CATALOG = ROOT / "core/dependencies/android.versions.toml"
IOS_CATALOG = ROOT / "core/dependencies/catalog.json"
GRADLE_WRAPPER = ROOT / "photo-pdf-to-size/android/gradle/wrapper/gradle-wrapper.properties"
ANDROID = {
    "agp": ("google", "com.android.tools.build:gradle"),
    "kotlin": ("maven", "org.jetbrains.kotlin:kotlin-gradle-plugin"),
    "composeBom": ("google", "androidx.compose:compose-bom"),
    "coreKtx": ("google", "androidx.core:core-ktx"),
    "activityCompose": ("google", "androidx.activity:activity-compose"),
    "lifecycle": ("google", "androidx.lifecycle:lifecycle-runtime-ktx"),
    "exifinterface": ("google", "androidx.exifinterface:exifinterface"),
    "junit": ("maven", "junit:junit"),
}
BASE_URL = {"google": "https://dl.google.com/dl/android/maven2", "maven": "https://repo.maven.apache.org/maven2"}

def load(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=15) as resp:
        return resp.read()

def numbers(version):
    m = re.fullmatch(r"v?(\d+)\.(\d+)(?:\.(\d+))?(?:\.(\d+))?", version)
    return tuple(int(x or 0) for x in m.groups()) if m else None

def compatible(current, candidate, allow_major):
    c, n = numbers(current), numbers(candidate)
    if not c or not n or n <= c: return False
    return allow_major or n[0] == c[0]

def latest_android(src, artifact, current, allow_major):
    g, name = artifact.split(":")
    url = f"{BASE_URL[src]}/{g.replace('.', '/')}/{name}/maven-metadata.xml"
    root = ET.fromstring(load(url))
    versions = [e.text for e in root.findall("./versioning/versions/version") if e.text]
    good = [x for x in versions if compatible(current, x, allow_major)]
    return max(good, key=numbers) if good else current

def latest_swift(repo, current, allow_major):
    data = json.loads(load(f"https://api.github.com/repos/{repo}/releases/latest"))
    v = str(data.get("tag_name", "")).lstrip("v")
    return v if compatible(current, v, allow_major) else current

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true", help="Update catalog files for review-only pull request")
    ap.add_argument("--allow-major", action="store_true", help="Explicit opt-in for major upgrades")
    args = ap.parse_args()
    manifest = json.loads(IOS_CATALOG.read_text())
    raw = CATALOG.read_text()
    android = tomllib.loads(raw)
    changes, errors = [], []
    for key, (source, artifact) in ANDROID.items():
        old = android["versions"][key]
        try:
            new = latest_android(source, artifact, old, args.allow_major)
        except Exception as e:
            errors.append(f"{key}: {type(e).__name__} {e}")
            continue
        if new != old:
            changes.append(("android", key, old, new))
            if args.write:
                before = f'{key} = "{old}"'
                assert raw.count(before) == 1
                raw = raw.replace(before, f'{key} = "{new}"')
    for name, pkg in manifest["swiftPackages"].items():
        repo = pkg["url"].removeprefix("https://github.com/")
        try:
            new = latest_swift(repo, pkg["version"], args.allow_major)
        except Exception as e:
            errors.append(f"{name}: {type(e).__name__} {e}")
            continue
        if new != pkg["version"]:
            changes.append(("swift", name, pkg["version"], new))
            if args.write:
                pkg["version"] = new
    # Gradle Wrapper is a pinned build tool, not a floating dependency.
    # Propose compatible stable wrapper releases alongside AGP/Kotlin updates.
    wrapper_raw = GRADLE_WRAPPER.read_text()
    match = re.search(r"gradle-(\d+\.\d+(?:\.\d+)?)-bin\.zip", wrapper_raw)
    if not match:
        errors.append("gradle-wrapper: missing pinned distribution URL")
    else:
        old = match.group(1)
        try:
            new = latest_swift("gradle/gradle", old, args.allow_major)
        except Exception as e:
            errors.append(f"gradle-wrapper: {type(e).__name__} {e}")
        else:
            if new != old:
                changes.append(("toolchain", "gradle-wrapper", old, new))
                if args.write:
                    wrapper_raw = wrapper_raw.replace(f"gradle-{old}-bin.zip", f"gradle-{new}-bin.zip")
                    GRADLE_WRAPPER.write_text(wrapper_raw)
    for kind, key, old, new in changes:
        print(f"{kind}: {key}: {old} -> {new}")
    for error in errors:
        print("CHECK ERROR:", error)
    if args.write:
        CATALOG.write_text(raw)
        IOS_CATALOG.write_text(json.dumps(manifest, indent=2) + "\n")
        # Sync both consumers atomically in the same PR commit.
        if changes:
            import subprocess
            subprocess.run(["python3", str(ROOT / "core/tools/sync_dependencies.py")], check=True)
    print(f"Updates: {len(changes)}, metadata errors: {len(errors)}")
    if errors:
        raise SystemExit(2)

if __name__ == "__main__":
    main()
