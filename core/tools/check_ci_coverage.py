#!/usr/bin/env python3
"""Protect CI scope when Core source, package manifests or SDK pins change.

This checks the repository's deliberately simple GitHub Actions 'on.paths'
declarations. It does not interpret arbitrary YAML or replace GitHub Actions.
"""
from __future__ import annotations

from pathlib import Path
import re

REPO_ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = REPO_ROOT / ".github" / "workflows"

# Paths are exact patterns; a broad catch-all silently makes Core CI expensive.
REQUIRED = {
    "core-ci.yml": {
        "core/packages/**",
        "core/Package.swift",
        "core/tests/**",
        "core/dependencies/catalog.json",
        "core/dependencies/android.versions.toml",
        "core/tools/sync_dependencies.py",
        "core/tools/check_swift_lockfiles.py",
    },
    "habits-ios-ci.yml": {
        "chickmark/ios/**",
        "core/packages/**",
        "core/Package.swift",
        "core/dependencies/catalog.json",
    },
    "pushkin-ios-ci.yml": {
        "pushkin/ios/**",
        "core/packages/**",
        "core/Package.swift",
    },
    "what-ios-ci.yml": {
        "what/ios/**",
        "core/packages/**",
        "core/Package.swift",
    },
    "photo-size-ios-ci.yml": {
        "photo-pdf-to-size/ios/**",
        "core/packages/**",
        "core/Package.swift",
        "core/dependencies/catalog.json",
    },
    "photo-size-android-ci.yml": {
        "photo-pdf-to-size/android/**",
        "core/dependencies/android.versions.toml",
    },
    "dependency-audit.yml": {
        "core/dependencies/**",
        "core/tools/sync_dependencies.py",
        "core/tools/check_swift_lockfiles.py",
    },
}

EVENT_HEADER = re.compile(r"(?m)^  (push|pull_request|workflow_dispatch):[ \t]*$")
PATH_ITEM = re.compile(r"^\s{6}-\s*['\"]([^'\"]+)['\"]\s*$")


def event_paths(contents: str, event: str) -> set[str] | None:
    """Read top-level event path patterns; None means event has no filters."""
    headers = list(EVENT_HEADER.finditer(contents))
    selected = next((i for i, m in enumerate(headers) if m.group(1) == event), None)
    if selected is None:
        raise ValueError(f"Missing event: {event}")
    start = headers[selected].end()
    end = headers[selected + 1].start() if selected + 1 < len(headers) else len(contents)
    section = contents[start:end]
    # Stop before workflow-level permissions, jobs, etc.
    section = re.split(r"(?m)^\S[^\n]*:\s*$", section, maxsplit=1)[0]
    match = re.search(r"(?m)^    paths:[ \t]*(.*)$", section)
    if not match:
        return None
    if match.group(1).strip():
        return set(re.findall(r"['\"]([^'\"]+)['\"]", match.group(1)))
    after = section[match.end():]
    paths = []
    for line in after.splitlines():
        if not line.strip():
            continue
        item = PATH_ITEM.match(line)
        if not item:
            break
        paths.append(item.group(1))
    return set(paths)


def check_coverage(root: Path = WORKFLOWS) -> list[str]:
    errors = []
    for name, needed in REQUIRED.items():
        path = root / name
        if not path.is_file():
            errors.append(f"{name}: missing workflow")
            continue
        content = path.read_text(encoding="utf-8")
        for event in ("push", "pull_request"):
            try:
                actual = event_paths(content, event)
            except ValueError as exc:
                errors.append(f"{name}: {exc}")
                continue
            # dependency-audit has a deliberately unfiltered pull_request event.
            if actual is None:
                if name != "dependency-audit.yml" or event != "pull_request":
                    errors.append(f"{name}:{event}: no explicit paths filter")
                continue
            missing = needed - actual
            if missing:
                errors.append(f"{name}:{event}: missing {', '.join(sorted(missing))}")
    return errors


if __name__ == "__main__":
    failures = check_coverage()
    if failures:
        for failure in failures:
            print("CI impact contract FAILED:", failure)
        raise SystemExit(1)
    print(f"Core CI impact contract OK ({len(REQUIRED)} workflows, push + PR)")
