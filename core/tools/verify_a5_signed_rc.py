#!/usr/bin/env python3
"""Read-only local A5 pre-upload guard. Does not contact App Store Connect."""
from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

DEFAULT_MANIFEST = Path(__file__).resolve().parents[1] / "A5_SIGNED_RELEASE_ATTESTATION_20261015.json"
DEFAULT_ARTIFACT_ROOT = Path("/Volumes/ArvectumSSD/Arvectum/releases/a5-20261015")


def fail(message: str) -> None:
    raise ValueError(message)


def verify_one(candidate: dict, root: Path) -> None:
    name = candidate["product"]
    relative = candidate["selected_ipa_relative_path"]
    ipa = root / relative
    if not ipa.is_file():
        fail(f"{name}: missing IPA at {ipa}")
    sha = hashlib.sha256(ipa.read_bytes()).hexdigest()
    if sha != candidate["ipa_sha256"]:
        fail(f"{name}: IPA SHA256 mismatch; this is NOT the designated A5 RC")
    with zipfile.ZipFile(ipa) as archive:
        files = archive.namelist()
        if any("RuWordNet" in name or "RussianConceptGraph" in name for name in files):
            fail(f"{name}: unlicensed/private model asset detected")
        infos = []
        for filename in files:
            if filename.startswith("Payload/") and (
                filename.endswith(".app/Info.plist") or filename.endswith(".appex/Info.plist")
            ):
                fields = plistlib.loads(archive.read(filename))
                infos.append((filename, fields))
        if len(infos) != len(candidate["nested_targets"]):
            fail(f"{name}: expected {len(candidate['nested_targets'])} app/extension bundles, got {len(infos)}")
        if not any(fields.get("CFBundleIdentifier") == candidate["bundle_id"] for _, fields in infos):
            fail(f"{name}: wrong bundle ID")
        for filename, fields in infos:
            if fields.get("CFBundleShortVersionString") != candidate["version"]:
                fail(f"{name}: wrong marketing version in {filename}")
            if str(fields.get("CFBundleVersion")) != str(candidate["build"]):
                fail(f"{name}: wrong build number in {filename}")
    if not shutil.which("codesign") or not shutil.which("ditto"):
        fail("requires macOS codesign and ditto; signing verification cannot be skipped")
    tmp = Path(tempfile.mkdtemp(prefix="arvectum-a5-verify-"))
    try:
        subprocess.run(["ditto", "-x", "-k", str(ipa), str(tmp)], check=True, capture_output=True)
        apps = list((tmp / "Payload").glob("*.app"))
        if len(apps) != 1:
            fail(f"{name}: expected exactly one top-level app")
        components = [apps[0]] + list(apps[0].rglob("*.app")) + list(apps[0].rglob("*.appex"))
        if len(components) != len(infos):
            fail(f"{name}: exported nested code-signature count mismatch")
        for component in components:
            res = subprocess.run(
                ["codesign", "--verify", "--strict", str(component)], capture_output=True, text=True
            )
            if res.returncode:
                fail(f"{name}: invalid code signature on {component.name}: {res.stderr[-150:]}")
            ent = subprocess.run(
                ["codesign", "-d", "--entitlements", ":-", str(component)], capture_output=True
            )
            attributes = plistlib.loads(ent.stdout)
            if attributes.get("get-task-allow") is not False:
                fail(f"{name}: development-signed component {component.name}")
            ident = subprocess.run(
                ["codesign", "-dv", "--verbose=2", str(component)], capture_output=True, text=True
            )
            if "TeamIdentifier=VML75VY94V" not in ident.stderr:
                fail(f"{name}: unexpected distribution team for {component.name}")
        print(f"PASS {name} {candidate['version']} ({candidate['build']}) "
              f"sha256={sha} signed_components={len(components)}")
    finally:
        shutil.rmtree(tmp)


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify exact signed A5 RC IPA before manual upload.")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--root", type=Path, default=DEFAULT_ARTIFACT_ROOT)
    parser.add_argument("--product", help="Verify one product as named in attestation; default is all four.")
    args = parser.parse_args()
    data = json.loads(args.manifest.read_text())
    items = [x for x in data["candidates"] if not args.product or x["product"] == args.product]
    if not items:
        print("Unknown product; nothing verified", file=sys.stderr)
        return 2
    try:
        for item in items:
            verify_one(item, args.root)
    except (ValueError, OSError, subprocess.CalledProcessError, zipfile.BadZipFile) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1
    print(f"Verified {len(items)} designated A5 RC IPA(s). This does not upload or submit anything.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
