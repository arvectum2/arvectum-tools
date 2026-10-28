"""Read-only ASO coverage: checked storefronts vs staged locale cards.

This never calls Apple, infers permitted metadata locales, or edits Store cards.
Existing Apple Lookup observations are dated snapshots, NOT live ASC state.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STAGED = ROOT / "core/appstore/staged-2026-10-26"
SNAPSHOT = STAGED / "editorial/c18-public-storefront-individual-20261028.json"
REGISTRY = ROOT / "core/localization/portfolio-locales.json"
APPS = {"photo": "photo-pdf-to-size", "pushkin": "pushkin",
        "what": "what", "chickmark": "chickmark"}

# The 16 countries observed by C18, each explicitly matched to one *draft*
# copy variant. This is NOT a claim that Apple accepts these metadata IDs in
# each storefront, nor that a separate card is displayed in each country.
COUNTRY_TO_DRAFT_LOCALE = {
    "ru": "ru", "us": "en-US", "gb": "en-GB", "ca": "en-CA",
    "au": "en-AU", "es": "es-ES", "mx": "es-MX", "fr": "fr-FR",
    "de": "de-DE", "it": "it", "pt": "pt-PT", "br": "pt-BR",
    "jp": "ja", "kr": "ko", "cn": "zh-Hans", "tw": "zh-Hant",
}


def source_locale(metadata_draft: str) -> str:
    if metadata_draft.startswith("en-"):
        return "en"
    if metadata_draft.startswith("es-"):
        return "es"
    if metadata_draft.startswith("fr-"):
        return "fr"
    if metadata_draft.startswith("de-"):
        return "de"
    return metadata_draft


def build_report(root: Path = ROOT) -> dict:
    base = root / "core/appstore/staged-2026-10-26"
    snapshot = json.loads((base / "editorial/c18-public-storefront-individual-20261028.json").read_text())
    registry = json.loads((root / "core/localization/portfolio-locales.json").read_text())
    assert set(snapshot["apps"]) == set(APPS), "Missing/unexpected app in Apple observation"
    rows = []
    for app, internal in APPS.items():
        draft = json.loads((base / f"{app}.json").read_text())
        assert draft["stage"] == "DRAFT_NOT_UPLOADED", f"{app}: untrusted draft stage"
        assert set(draft["localeData"]) == set(COUNTRY_TO_DRAFT_LOCALE.values()), f"{app}: draft locale mismatch"
        assert set(snapshot["apps"][app]) == set(COUNTRY_TO_DRAFT_LOCALE), f"{app}: missing country observation"
        assert draft["bundleId"] == next(iter(snapshot["apps"][app].values()))["bundleId"], f"{app}: bundle mismatch"
        available = set(registry["apps"][internal]["ios"]["sourceCatalogs"])
        for country, locale in COUNTRY_TO_DRAFT_LOCALE.items():
            observation = snapshot["apps"][app][country]
            card = draft["localeData"][locale]
            assert observation["bundleId"] == draft["bundleId"], f"{app}/{country}: mixed bundle"
            assert all(card.get(key) for key in ("name", "subtitle", "keywords", "description",
                    "promotionalText", "whatsNew", "screenshots", "privacyPolicyUrl")), f"{app}/{locale}: incomplete staged card"
            ui_locale = source_locale(locale)
            rows.append({
                "app": app,
                "country": country.upper(),
                "marketing_copy_draft": locale,
                "interface_source_locale": ui_locale,
                "interface_source_exists": ui_locale in available,
                "draft_only": True,
                "apple_metadata_locale_verified_for_country": False,
                "public_version_observed": observation["version"],
                "public_screenshot_count_observed": observation.get("screenshotCount"),
                "public_ipad_screenshot_count_observed": observation.get("ipadScreenshotCount"),
                "minimum_os_observed": observation.get("minOS"),
                "bundle_id": observation["bundleId"],
            })
    return {
        "status": "READ_ONLY_SNAPSHOT_NOT_LIVE_ASC",
        "observed_utc": snapshot["observedUTC"],
        "storefronts_observed": len(COUNTRY_TO_DRAFT_LOCALE),
        "draft_cards_checked": len(rows),
        "target_interface_locales": len(registry["targets"]),
        "source_interface_locales_per_app": len(registry["apps"]["chickmark"]["ios"]["sourceCatalogs"]),
        "apple_metadata_locale_validation": "REQUIRED_IN_ASC_BEFORE_REGION_LAUNCH",
        "rows": rows,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--format", choices=("json", "table"), default="table")
    args = parser.parse_args()
    report = build_report()
    if args.format == "json":
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return
    print("Apple public Lookup snapshot:", report["observed_utc"])
    print("Staged, NOT live ASC: 4 apps × 16 observed storefronts =", report["draft_cards_checked"])
    print("New storefronts and Apple-supported metadata locale IDs require ASC verification.")
    print("APP       COUNTRY  DRAFT      UI SOURCE  VERSION  IPHONE  IPAD")
    for row in report["rows"]:
        print(f"{row['app']:<9} {row['country']:<8} {row['marketing_copy_draft']:<10} "
              f"{row['interface_source_locale']:<10} {row['public_version_observed']:<8} "
              f"{row['public_screenshot_count_observed']!s:<7} "
              f"{row['public_ipad_screenshot_count_observed']!s}")


if __name__ == "__main__":
    main()
