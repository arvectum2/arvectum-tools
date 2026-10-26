#!/usr/bin/env python3
"""Structure and dependency contract. Stdlib only, safe for CI and developer worktrees."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
PRODUCTS = ("chickmark", "pushkin", "photo-pdf-to-size", "what", "where")
DOMAINS = (*PRODUCTS, "core", "growth")
ALLOWED_ROOT_FILES = {".gitattributes", ".gitignore", "LICENSE", "README.md", "AGENTS.md"}
ALLOWED_ROOT_DIRS = {".git", ".github", *DOMAINS}
SOURCE_EXT = {".swift", ".kt", ".kts", ".java", ".py", ".sh", ".bash", ".gradle"}
# Explicit names only: avoid false-positive 'import Foundation' or normal library symbols.
PRIVATE_SWIFT_MODULES = {
    "chickmark": {"ChickMark", "HabitTracker", "ChickMarkIOS", "ChickMarkWatch"},
    "pushkin": {"ArvectumNotify", "ArvectumNotifyIOS", "Pushkin", "PushkinIOS"},
    "photo-pdf-to-size": {"PhotoPodRazmer", "PhotoPodRazmerIOS"},
    "what": {"WhatIOS", "WhatWatch", "WhatWatchComplication"},
    "where": {"WhereIOS"},
}
problems: list[str] = []

def fail(reason: str) -> None:
    problems.append(reason)

def tracked_files() -> list[Path]:
    p = subprocess.run(["git", "-C", str(ROOT), "ls-files", "--cached", "--others", "--exclude-standard", "-z"], capture_output=True, check=True)
    return [Path(x.decode()) for x in p.stdout.split(b"\0") if x]

for x in ROOT.iterdir():
    if x.name in ALLOWED_ROOT_FILES | ALLOWED_ROOT_DIRS:
        if x.name in DOMAINS and not x.is_dir():
            fail(f"{x.name}: domain must be a directory")
    else:
        fail(f"unexpected root entry: {x.name}")

for name in DOMAINS:
    if not (ROOT / name).is_dir():
        fail(f"missing domain: {name}")
for name in PRODUCTS:
    if not (ROOT / name / "ROADMAP.md").is_file():
        fail(f"missing product roadmap: {name}/ROADMAP.md")
for filename in ("core/ARCHITECTURE_CONTRACT.md", "core/CORE_PRINCIPLES.md", "core/ROADMAP.md", "growth/ROADMAP.md"):
    if not (ROOT / filename).is_file():
        fail(f"missing shared contract/roadmap: {filename}")

for rel in tracked_files():
    path = ROOT / rel
    if not path.exists() and not path.is_symlink():
        fail(f"tracked file missing: {rel}")
        continue
    if path.is_symlink():
        resolved = path.resolve()
        if not resolved.is_relative_to(ROOT):
            fail(f"symlink escapes repo: {rel}")
    if path.suffix.lower() not in SOURCE_EXT or not path.is_file():
        continue
    domain = rel.parts[0]
    if domain not in DOMAINS:
        continue
    try:
        content = path.read_text(errors="replace")
    except OSError:
        continue
    if domain in PRODUCTS:
        forbidden = [other for other in PRODUCTS if other != domain]
    elif domain in ("core", "growth"):
        forbidden = list(PRODUCTS)
    else:
        forbidden = []
    # Explicit source inspection / orchestration allowlist only. These utilities
    # read product source, manifests or test fixtures; they are not Core runtime
    # dependencies. Keep production Core code subject to the cross-domain rule.
    if rel.as_posix() in {
        "core/tools/sync_dependencies.py",
        "core/tools/update_dependencies.py",
        "core/tools/check_swift_lockfiles.py",
        "core/tools/check_ci_coverage.py",
        "core/tools/localization_portfolio.py",
        # ASO source and screenshot inventory tools read product assets to
        # build draft documentation, never linked into shared Core runtime.
        "core/tools/plan_appstore_screenshots.py",
        "core/tools/prepare_appstore_localizations.py",
        "core/tests/test_localization_portfolio.py",
        "core/tests/test_android_photo_picker_qa.py",
        "core/tests/test_android_photo_pipeline_qa.py",
    }:
        forbidden = []
    for other in forbidden:
        # Only literal absolute/repo-root path references and relative filesystem traversals.
        # Historical text and documentation are not source dependency edges.
        pat = rf'(?<![\w/])(?:apps/)?{re.escape(other)}/(?:ios|android|src|app|store-assets|docs)/'
        if re.search(pat, content):
            fail(f"{rel}: source reference to {other}/ (cross-domain dependency)")
    if rel.suffix.lower() == ".swift":
        forbidden_mods = set().union(*(PRIVATE_SWIFT_MODULES[x] for x in forbidden)) if forbidden else set()
        for module in re.findall(r"(?m)^\s*(?:@testable\s+)?import\s+([A-Za-z_][A-Za-z_0-9]*)", content):
            if module in forbidden_mods:
                fail(f"{rel}: forbidden import {module}")
    # Cross-project Gradle inclusion is checked by the source path rule above.

if problems:
    print("Architecture contract FAILED:")
    for problem in sorted(set(problems)):
        print(" -", problem)
    sys.exit(1)
print(f"Architecture contract OK ({len(tracked_files())} tracked and untracked source files checked)")
