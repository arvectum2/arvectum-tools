#!/usr/bin/env python3
"""Check source membership in the committed vs XcodeGen-generated Xcode project.

PBX object IDs, file ordering, or project formatter changes between XcodeGen
versions need not be identical. Swift sources assigned to build phases MUST
match. Run with two PBX project files, committed first and generated second.
"""
from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path


def swift_build_sources(path: Path) -> Counter[str]:
    content = path.read_text(encoding="utf-8")
    begin = "/* Begin PBXBuildFile section */"
    end = "/* End PBXBuildFile section */"
    if begin not in content or end not in content:
        raise ValueError(f"Missing PBXBuildFile section in {path}")
    section = content.split(begin, 1)[1].split(end, 1)[0]
    names = re.findall(r"/\* ([^*\n]+\.swift) in Sources \*/", section)
    if not names:
        raise ValueError(f"No Swift build sources in {path}")
    return Counter(names)


def compare(committed: Path, generated: Path) -> bool:
    old = swift_build_sources(committed)
    new = swift_build_sources(generated)
    missing = new - old
    stale = old - new
    if missing or stale:
        print("XcodeGen Swift build-source membership differs from committed project.")
        for file, count in sorted(missing.items()):
            print(f"  MISSING in committed: {file} ({count})")
        for file, count in sorted(stale.items()):
            print(f"  STALE in committed: {file} ({count})")
        return False
    print(f"XcodeGen source membership OK: {sum(new.values())} Swift target entries.")
    return True


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage: check_project_source_membership.py COMMITTED.pbxproj GENERATED.pbxproj")
    try:
        sys.exit(0 if compare(Path(sys.argv[1]), Path(sys.argv[2])) else 1)
    except (OSError, ValueError) as error:
        sys.exit(f"Project source check could not run: {error}")
