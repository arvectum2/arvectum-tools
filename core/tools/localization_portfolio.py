#!/usr/bin/env python3
"""Portfolio localization: discover English SwiftUI keys, audit real translation coverage.

Usage (repository root):
    python3 core/tools/localization_portfolio.py --extract-english
    python3 core/tools/localization_portfolio.py --audit
    python3 core/tools/localization_portfolio.py --report

The 50-language target manifest is *not* a claim of supported binary localizations.
A locale is 'ready' only when every active bundle of an app has full strings.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "core/localization/portfolio-locales.json"
STRINGS_LINE = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)";\s*$', re.M)
# SwiftUI treats these static literal arguments as localized keys by default.
SWIFT_UI = re.compile(
    r'(?<![\w])(?:Text|Label|Button|Toggle|TextField|SecureField|Picker|'
    r'navigationTitle|accessibilityLabel|accessibilityHint|accessibilityValue|'
    r'confirmationDialog|alert|help|prompt)\(\s*"((?:\\.|[^"\\])*)"',
)
# Compare argument types/count; numbered arguments may legitimately change order.
PRINTF = re.compile(r'(?<!%)%(?:[1-9]\d*\$)?(?:[-+0#]*\d*(?:\.\d+)?)?(lld|ld|@|d|i|u|f|g|s|c)')
CAPTURE_BRAND = re.compile(r'CaptureBrand\.text\(\s*"((?:\\.|[^"\\])*)"\s*,\s*"((?:\\.|[^"\\])*)"')
# Pushkin currently renders these keys through its RU/EN copy catalog.
PUSHKIN_COPY_CALL = re.compile(r'(?<![\w])pc\(\s*"((?:\\.|[^"\\])*)"')

QA_DIRS = ("Tests", "UITests", "QA", "Fixtures", "Preview")
APP_SOURCE_DIRS = {
    "pushkin/ios/ArvectumNotify/Resources": ROOT / "pushkin/ios/ArvectumNotify",
    "what/ios/WhatIOS": ROOT / "what/ios/WhatIOS",
    "what/ios/WhatWatch": ROOT / "what/ios/WhatWatch",
    "what/ios/WhatPhoneWidget": ROOT / "what/ios/WhatPhoneWidget",
    "what/ios/WhatWatchComplication": ROOT / "what/ios/WhatWatchComplication",
}


def config() -> dict:
    doc = json.loads(MANIFEST.read_text(encoding="utf-8"))
    codes = [item["code"] for item in doc["targets"]]
    assert len(codes) == len(set(codes)) == 50, "Exactly 50 unique locales required"
    assert doc["fallback"] == "en" and "en" in codes
    return doc


def read_strings(path: Path, errors: list[str]) -> dict[str, str]:
    if not path.is_file():
        errors.append(f"missing {path.relative_to(ROOT)}")
        return {}
    raw = path.read_text(encoding="utf-8")
    items = STRINGS_LINE.findall(raw)
    keys = [k for k, _ in items]
    if len(keys) != len(set(keys)):
        errors.append(f"duplicate keys in {path.relative_to(ROOT)}")
    if not items:
        errors.append(f"empty/unparsable {path.relative_to(ROOT)}")
    return dict(items)


def discover_english_keys(bundle: str, src: Path) -> set[str]:
    keys: set[str] = set()
    for swift in sorted(src.rglob("*.swift")):
        if any(marker in component for component in swift.parts for marker in QA_DIRS):
            continue
        raw = swift.read_text(encoding="utf-8")
        for match in SWIFT_UI.finditer(raw):
            value = match.group(1)
            if not value or any(marker in value for marker in (r"\(", r"\u", r"\#")):
                continue
            if "\n" in value or value.startswith("system.") or len(value) > 600:
                continue
            keys.add(value)
        if bundle.startswith("pushkin/"):
            for match in PUSHKIN_COPY_CALL.finditer(raw):
                english = match.group(1)
                if english and r"\(" not in english:
                    keys.add(english)
        # CaptureBrand currently manages RU/EN strings manually.
        if bundle.startswith("what/"):
            for match in CAPTURE_BRAND.finditer(raw):
                english = match.group(2)
                if english and r"\(" not in english:
                    keys.add(english)
    return keys


# Review-only inventory: interpolation is not a completed localization.
DYNAMIC_APP_DIRS = {
    "chickmark": ROOT / "chickmark/ios",
    "pushkin": ROOT / "pushkin/ios/ArvectumNotify",
    "what": ROOT / "what/ios",
    "photo-pdf-to-size": ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer",
}
DYNAMIC_CAPTURE = re.compile(
    r'CaptureBrand\.text\(\s*"((?:\\.|[^"\\])*)"\s*,\s*"((?:\\.|[^"\\])*)"'
)


def dynamic_inventory() -> list[dict[str, str | int]]:
    findings: list[dict[str, str | int]] = []
    seen: set[tuple[str, int, str]] = set()
    for app, root in DYNAMIC_APP_DIRS.items():
        for file in sorted(root.rglob("*.swift")):
            if any(marker in component for component in file.parts for marker in QA_DIRS):
                continue
            body = file.read_text(encoding="utf-8")
            candidates: list[tuple[str, re.Match[str]]] = [
                ("swiftui-interpolation", match)
                for match in SWIFT_UI.finditer(body) if r"\(" in match.group(1)
            ]
            if app == "what":
                candidates += [
                    ("capturebrand-interpolation", match)
                    for match in DYNAMIC_CAPTURE.finditer(body)
                    if r"\(" in match.group(1) or r"\(" in match.group(2)
                ]
            for kind, match in candidates:
                line = body.count("\n", 0, match.start()) + 1
                signature = (str(file), line, kind)
                if signature in seen:
                    continue
                seen.add(signature)
                findings.append({
                    "app": app, "file": str(file.relative_to(ROOT)),
                    "line": line, "kind": kind, "source": match.group(0),
                    "status": "requires-review",
                })
    return sorted(findings, key=lambda x: (str(x["app"]), str(x["file"]), int(x["line"])))


def extract_english() -> None:
    """Extract unambiguous static SwiftUI keys, never fake target translations."""
    for bundle, src in APP_SOURCE_DIRS.items():
        dest = ROOT / bundle / "en.lproj/Localizable.strings"
        keys = discover_english_keys(bundle, src)
        if not keys:
            raise RuntimeError(f"No static UI keys discovered for {bundle}")
        dest.parent.mkdir(parents=True, exist_ok=True)
        previous = read_strings(dest, []) if dest.exists() else {}
        missing = sorted(keys - set(previous))
        if not missing:
            print(f"KEEP {dest.relative_to(ROOT)} ({len(previous)} keys)")
            continue
        header = "// Extracted English source strings; user-visible translations must be reviewed.\n" if not previous else ""
        content = header + "\n".join(f'"{key}" = "{key}";' for key in missing) + "\n"
        with dest.open("a", encoding="utf-8") as file:
            file.write(content)
        print(f"ADD  {dest.relative_to(ROOT)} ({len(missing)} new keys, total {len(previous)+len(missing)})")


def placeholders(value: str) -> Counter[str]:
    return Counter(PRINTF.findall(value.replace("%%", "")))



def android_catalog_audit(doc: dict, errors: list[str], *, report: bool = False) -> None:
    """Verify Android's real English fallback and all provided resource packs."""
    app = doc["apps"]["photo-pdf-to-size"]["android"]
    resources = ROOT / app["resources"]
    base = resources / "values/strings.xml"
    expected = None
    directories = [resources / "values"] + sorted(
        directory for directory in resources.glob("values-*")
        if (directory / "strings.xml").exists()
    )
    for directory in directories:
        path = directory / "strings.xml"
        try:
            children = ET.parse(path).getroot()
            keys = [element.attrib["name"] for element in children if element.tag == "string"]
            values = {element.attrib["name"]: element.text or "" for element in children if element.tag == "string"}
        except (OSError, ET.ParseError, KeyError) as exc:
            errors.append(f"Android locale {path}: {exc}")
            continue
        if len(keys) != len(values):
            errors.append(f"Android duplicate resource keys in {path.relative_to(ROOT)}")
        if expected is None:
            expected = values
            if values.get("app_name") != "Photo Resizer":
                errors.append("Android default values/strings.xml must be English")
            if any(re.search(r"[А-Яа-яЁё]", val) for val in values.values()):
                errors.append("Android English fallback contains Cyrillic text")
        else:
            if set(expected) != set(values):
                errors.append(f"Android {directory.name}: missing/extra resource keys")
            for key in set(expected) & set(values):
                if placeholders(expected[key]) != placeholders(values[key]):
                    errors.append(f"Android {directory.name}/{key}: format arguments differ")
            if directory.name == "values-ru" and values.get("app_name") != "Фото под размер":
                errors.append("Android Russian app label unexpectedly changed")
            if directory.name == "values-es" and values.get("app_name") != "Redimensionar fotos":
                errors.append("Android Spanish app label unexpectedly changed")
    if expected is not None:
        kotlin_root = ROOT / "photo-pdf-to-size/android/app/src/main/java"
        references: set[str] = set()
        for path in kotlin_root.rglob("*.kt"):
            body = path.read_text(encoding="utf-8")
            references.update(re.findall(r"R\.string\.([a-z][a-z0-9_]*)", body))
            if path.name in {"MainScreen.kt", "BrandComponents.kt", "PassportCropScreen.kt"}:
                if re.search(r'\"[^\"\\n]*[А-Яа-яЁё][^\"\\n]*\"', body):
                    errors.append(f"Android hardcoded UI Russian in {path.relative_to(ROOT)}")
        if references - set(expected):
            errors.append(f"Android unknown string resource IDs: {sorted(references - set(expected))}")
        if report:
            languages = [d.name.removeprefix("values-") for d in directories[1:]]
            print(f"photo-pdf-to-size Android {len(expected)} keys; English source, draft locales: {', '.join(languages)}")



def audit(doc: dict, *, report: bool = False) -> int:
    errors: list[str] = []
    locales = {item["code"] for item in doc["targets"]}
    for app_name, app in doc["apps"].items():
        if not app["bundles"]:
            if report:
                print(f"{app_name:20} paused | future localization via same registry")
            continue
        full = []
        counts = []
        for raw in app["bundles"]:
            root = ROOT / raw
            base = read_strings(root / "en.lproj/Localizable.strings", errors)
            counts.append(len(base))
            if raw in APP_SOURCE_DIRS:
                uncovered = discover_english_keys(raw, APP_SOURCE_DIRS[raw]) - set(base)
                if uncovered:
                    errors.append(
                        f"{raw}: {len(uncovered)} unextracted static UI keys "
                        f"(run --extract-english): {sorted(uncovered)[:5]}"
                    )
            available = {"en"} if base else set()
            for p in sorted(root.glob("*.lproj/Localizable.strings")):
                lang = p.parent.name.removesuffix(".lproj")
                if lang == "en":
                    continue
                if lang not in locales:
                    errors.append(f"Unregistered locale {lang} in {raw}")
                    continue
                entries = read_strings(p, errors)
                missing = set(base) - set(entries)
                extra = set(entries) - set(base)
                if missing or extra:
                    errors.append(f"{raw}/{lang}: {len(missing)} missing, {len(extra)} extra keys")
                mismatches = [key for key in base.keys() & entries.keys()
                              if placeholders(base[key]) != placeholders(entries[key])]
                if mismatches:
                    errors.append(f"{raw}/{lang}: placeholder mismatch: {mismatches[:8]}")
                if not missing and not extra and not mismatches:
                    available.add(lang)
            full.append(available)
        ready = sorted(set.intersection(*full)) if full else []
        if report:
            short = ", ".join(ready)
            print(f"{app_name:20} {len(ready):2} catalog-complete: {short}; key counts by bundle: {counts}")
        # The same locale needs a translated InfoPlist for all security prompts.
        # We audit keys for existing localized permissions, independently of UI readiness.
        for raw in app["bundles"]:
            root = ROOT / raw
            base_info = root / "en.lproj/InfoPlist.strings"
            if not base_info.exists():
                continue
            base = read_strings(base_info, errors)
            for p in root.glob("*.lproj/InfoPlist.strings"):
                lang = p.parent.name.removesuffix(".lproj")
                if lang == "en":
                    continue
                entries = read_strings(p, errors)
                for key in base:
                    if key not in entries:
                        errors.append(f"{raw}/{lang}: missing permission string {key}")
                for key in base.keys() & entries.keys():
                    if placeholders(base[key]) != placeholders(entries[key]):
                        errors.append(f"{raw}/{lang}/{key}: permission format mismatch")
    android_catalog_audit(doc, errors, report=report)
    if errors:
        print("\n".join(f"ERROR {e}" for e in errors))
        return 1
    if report:
        print("NOTE: structural catalog completeness only, not full UI coverage or translation quality.")
    else:
        print("Portfolio localization structure and format audit PASS")
    return 0



def export_sources(doc: dict, destination: Path) -> None:
    """Export canonical English inputs for translation; never enable new locales."""
    destination.mkdir(parents=True, exist_ok=True)
    for app_name, app in doc["apps"].items():
        if not app["bundles"]:
            continue
        errors: list[str] = []
        bundles = {}
        for raw in app["bundles"]:
            root = ROOT / raw / "en.lproj"
            resources = {}
            for file in sorted(root.glob("*.strings")):
                resources[file.name] = read_strings(file, errors)
            bundles[raw] = resources
        if errors:
            raise ValueError("\n".join(errors))
        result = {
            "app": app_name,
            "sourceLocale": "en",
            "status": "source-only-unreviewed",
            "note": "Do not publish translated catalogs without complete QA of runtime UI, legal text and companion bundles.",
            "bundles": bundles,
        }
        path = destination / f"{app_name}.en.source.json"
        path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"EXPORTED {path} ({sum(len(r) for b in bundles.values() for r in b.values())} strings)")

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--extract-english", action="store_true")
    parser.add_argument("--inventory-dynamic", action="store_true")
    parser.add_argument("--audit", action="store_true")
    parser.add_argument("--report", action="store_true")
    parser.add_argument("--export-sources", metavar="DIRECTORY", type=Path)
    args = parser.parse_args()
    if not any((args.extract_english, args.audit, args.report, args.export_sources, args.inventory_dynamic)):
        parser.error("Specify --extract-english, --audit, --inventory-dynamic or --report")
    doc = config()
    if args.inventory_dynamic:
        print(json.dumps({
            "status": "source-risk-inventory-not-translations",
            "findings": dynamic_inventory(),
        }, ensure_ascii=False, indent=2))
        if not any((args.audit, args.report, args.export_sources, args.extract_english)):
            return 0
    if args.extract_english:
        extract_english()
    if args.export_sources:
        if audit(doc) != 0:
            return 1
        export_sources(doc, args.export_sources)
    return audit(doc, report=args.report) if (args.audit or args.report) else 0


if __name__ == "__main__":
    sys.exit(main())
