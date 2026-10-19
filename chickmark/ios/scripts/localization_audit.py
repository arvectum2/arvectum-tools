#!/usr/bin/env python3
"""Ensure RU, EN and ES resource parity before an iOS release."""
from pathlib import Path
import plistlib
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
TARGETS = [
    "HabitsByArvectum", "HabitsByArvectumWatch",
    "HabitsByArvectumWidget", "HabitsByArvectumWatchWidget",
]
LOCALES = ("en", "ru", "es")
ENTRY = re.compile(r'^\s*"([^"]+)"\s*=\s*"(.*)";\s*$', re.MULTILINE)
FORMAT = re.compile(r'%(?:[1-9]\d*\$)?(?:@|d|i|u|f|s|ld|lld)')
errors = []

def load(path):
    if not path.exists():
        errors.append(f"Missing {path}")
        return {}
    content = path.read_text(encoding="utf-8")
    entries = ENTRY.findall(content)
    keys = [k for k, _ in entries]
    if len(keys) != len(set(keys)):
        errors.append(f"Duplicate keys: {path}")
    return dict(entries)

for target in TARGETS:
    root = ROOT / target
    sets = {
        lang: load(root / f"{lang}.lproj" / "Localizable.strings")
        for lang in LOCALES
    }
    reference = sets["en"]
    for lang in LOCALES[1:]:
        extra = set(sets[lang]) - set(reference)
        missing = set(reference) - set(sets[lang])
        if missing or extra:
            errors.append(f"{target}/{lang}: missing={sorted(missing)}, extra={sorted(extra)}")
        for key in reference.keys() & sets[lang].keys():
            if FORMAT.findall(reference[key]) != FORMAT.findall(sets[lang][key]):
                errors.append(f"{target}/{lang}/{key}: printf argument mismatch")

shortcut = ROOT / "HabitsByArvectum"
shortcuts = {
    lang: load(shortcut / f"{lang}.lproj" / "AppShortcuts.strings")
    for lang in LOCALES
}
for lang in LOCALES[1:]:
    if shortcuts[lang].keys() != shortcuts["en"].keys():
        errors.append(f"AppShortcuts/{lang}: missing or extra keys")

# Apple validates *both* HealthKit usage descriptions on every HealthKit
# capable bundle, including an independent watchOS app, even for read-only
# access. ITMS-90683 blocks upload otherwise.
project = (ROOT / "project.yml").read_text(encoding="utf-8")
for target in ("HabitsByArvectum", "HabitsByArvectumWatch"):
    info = plistlib.loads((ROOT / target / "Info.plist").read_bytes())
    for key in ("NSHealthShareUsageDescription", "NSHealthUpdateUsageDescription"):
        if not str(info.get(key, "")).strip():
            errors.append(f"{target} Info.plist missing {key}")
        if project.count(key) < 2:
            errors.append(f"XcodeGen project.yml missing {key} on both app targets")
        for lang in LOCALES:
            localized = load(ROOT / target / f"{lang}.lproj" / "InfoPlist.strings")
            if not localized.get(key, "").strip():
                errors.append(f"{target} {lang} missing {key}")

# A permission prompt must describe the ACTUAL write behavior. These values
# override the base Info.plist and are visible to users when granting HealthKit.
# Watch remains read-only; this check applies only to the phone bundle.
water_consent = {
    "en": ("water", "add"),
    "ru": ("вод", "запис"),
    "es": ("agua", "añad"),
}
for lang, keywords in water_consent.items():
    text = load(ROOT / "HabitsByArvectum" / f"{lang}.lproj" / "InfoPlist.strings").get(
        "NSHealthUpdateUsageDescription", ""
    ).lower()
    if not all(part in text for part in keywords):
        errors.append(
            f"HabitsByArvectum/{lang}: NSHealthUpdateUsageDescription must disclose "
            "adding water to Apple Health"
        )
    if any(phrase in text for phrase in (
        "does not add", "does not change", "не добавляет", "не изменяет",
        "no añade", "no modifica",
    )):
        errors.append(f"HabitsByArvectum/{lang}: false write-permission assurance")

if errors:
    print("\n".join(errors))
    sys.exit(1)
print("Localization audit passed: en / ru / es, all iOS, Watch, widget and Shortcut resources.")
