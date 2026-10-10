#!/usr/bin/env python3
"""Ensure RU, EN and ES resource parity before an iOS release."""
from pathlib import Path
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

if errors:
    print("\n".join(errors))
    sys.exit(1)
print("Localization audit passed: en / ru / es, all iOS, Watch, widget and Shortcut resources.")
