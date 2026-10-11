#!/usr/bin/env python3
"""Synchronize shared SwiftPM declarations from Core; --check fails on drift."""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = json.loads((ROOT / "core/dependencies/catalog.json").read_text())
SPECS = {"chickmark/ios/project.yml": "version", "photo-pdf-to-size/ios/project.yml": "exactVersion"}


def sync(text, version_policy):
    for name, package in CATALOG["swiftPackages"].items():
        anchor = rf"(?m)^(  {re.escape(name)}:\n    url: [^\n]+\n)    (?:exactVersion|version): [^\n]+"
        replace = rf"\g<1>    {version_policy}: {package['version']}"
        new, count = re.subn(anchor, replace, text)
        if count != 1:
            raise RuntimeError(f"Package {name} not found exactly once")
        text = new
    return text


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    drift = []
    for spec, policy in SPECS.items():
        p = ROOT / spec
        current = p.read_text()
        expected = sync(current, policy)
        if current != expected:
            drift.append(spec)
            if not args.check:
                p.write_text(expected)
    if args.check and drift:
        raise SystemExit("Shared dependency version drift: " + ", ".join(drift))
    print("Shared Swift dependencies OK:", ", ".join(SPECS))


if __name__ == "__main__":
    main()
