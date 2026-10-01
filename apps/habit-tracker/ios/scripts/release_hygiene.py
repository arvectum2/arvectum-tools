#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

TARGETS = [
    ROOT / "HabitsByArvectum",
    ROOT / "HabitsByArvectumWatch",
    ROOT / "HabitsByArvectumWidget",
    ROOT / "HabitsByArvectumWatchWidget",
]
APP_GROUP = "group.ru.arvectum.tools.habits"
ICLOUD_CONTAINER = "iCloud.ru.arvectum.tools.habits"

errors: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


for target in TARGETS:
    privacy = target / "PrivacyInfo.xcprivacy"
    if not privacy.exists():
        fail(f"missing privacy manifest: {privacy.relative_to(ROOT)}")
        continue
    try:
        with privacy.open("rb") as handle:
            plistlib.load(handle)
    except Exception as exc:
        fail(
            f"invalid privacy manifest {privacy.relative_to(ROOT)}: {exc}"
        )

    entitlements = list(target.glob("*.entitlements"))
    if len(entitlements) != 1:
        fail(
            f"expected one entitlements file in {target.relative_to(ROOT)}, "
            f"found {len(entitlements)}"
        )
        continue

    try:
        with entitlements[0].open("rb") as handle:
            values = plistlib.load(handle)
    except Exception as exc:
        fail(
            f"invalid entitlements {entitlements[0].relative_to(ROOT)}: {exc}"
        )
        continue

    groups = values.get("com.apple.security.application-groups", [])
    if APP_GROUP not in groups:
        fail(
            f"{entitlements[0].relative_to(ROOT)} missing App Group "
            f"{APP_GROUP}"
        )

phone_entitlements = ROOT / "HabitsByArvectum" / "HabitsByArvectum.entitlements"
with phone_entitlements.open("rb") as handle:
    phone_values = plistlib.load(handle)

containers = phone_values.get(
    "com.apple.developer.icloud-container-identifiers",
    [],
)
if ICLOUD_CONTAINER not in containers:
    fail(f"phone entitlements missing iCloud container {ICLOUD_CONTAINER}")

if "CloudKit" not in phone_values.get(
    "com.apple.developer.icloud-services",
    [],
):
    fail("phone entitlements missing CloudKit service")

string_pattern = re.compile(
    r'^\s*"((?:[^"\\]|\\.)+)"\s*=',
    re.MULTILINE,
)


def localization_keys(path: Path) -> set[str]:
    return set(string_pattern.findall(path.read_text(encoding="utf-8")))


for localization_root in [
    ROOT / "HabitsByArvectum",
    ROOT / "HabitsByArvectumWatch",
]:
    english = localization_root / "en.lproj" / "Localizable.strings"
    russian = localization_root / "ru.lproj" / "Localizable.strings"

    if not english.exists() or not russian.exists():
        fail(
            f"missing RU/EN localization in "
            f"{localization_root.relative_to(ROOT)}"
        )
        continue

    en_keys = localization_keys(english)
    ru_keys = localization_keys(russian)

    if en_keys != ru_keys:
        only_en = sorted(en_keys - ru_keys)
        only_ru = sorted(ru_keys - en_keys)
        if only_en:
            fail(
                f"{localization_root.name}: keys missing in RU: "
                + ", ".join(only_en)
            )
        if only_ru:
            fail(
                f"{localization_root.name}: keys missing in EN: "
                + ", ".join(only_ru)
            )

project_yml = (ROOT / "project.yml").read_text(encoding="utf-8")
for required in [
    "HabitsByArvectumWatch",
    "HabitsByArvectumWatchWidget",
    "HabitsByArvectumWidget",
    "HabitSyncProtocol.swift",
]:
    if required not in project_yml:
        fail(f"project.yml missing required integration: {required}")

if errors:
    print("Release hygiene failed:", file=sys.stderr)
    for error in errors:
        print(f"- {error}", file=sys.stderr)
    raise SystemExit(1)

print(
    "Release hygiene passed: privacy manifests, entitlements, "
    "RU/EN localization parity, Watch/widget integration."
)
