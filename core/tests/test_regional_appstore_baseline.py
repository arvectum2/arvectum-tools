"""Source-only regional App Store cards; NOT proof of live ASC localization."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
STAGED = ROOT / "core/appstore/staged-2026-10-26"
EXPECTED_LOCALES = {
    "ru", "en-US", "en-GB", "en-AU", "en-CA", "es-ES", "es-MX",
    "fr-FR", "de-DE", "it", "ja", "ko", "pt-BR", "pt-PT",
    "zh-Hans", "zh-Hant",
}


class RegionalAppStoreBaselineTests(unittest.TestCase):
    def test_four_apps_have_same_sixteen_complete_staged_region_cards(self):
        for app in ("photo", "pushkin", "what", "chickmark"):
            with self.subTest(app=app):
                data = json.loads((STAGED / f"{app}.json").read_text())
                self.assertEqual(data["stage"], "DRAFT_NOT_UPLOADED")
                self.assertEqual(set(data["localeData"]), EXPECTED_LOCALES)
                for locale, card in data["localeData"].items():
                    with self.subTest(app=app, locale=locale):
                        self.assertTrue(all(card.get(field) for field in (
                            "name", "subtitle", "description", "keywords",
                            "promotionalText", "whatsNew", "privacyPolicyUrl",
                            "screenshots",
                        )))

    def test_fifty_targets_and_app_specific_ios_source_locales(self):
        data = json.loads((ROOT / "core/localization/portfolio-locales.json").read_text())
        codes = [row["code"] for row in data["targets"]]
        self.assertEqual(len(codes), 50)
        self.assertEqual(len(set(codes)), 50)
        source = {"en", "ru", "es", "fr", "de", "pt-BR", "pt-PT", "it",
                  "ja", "ko", "zh-Hans", "zh-Hant"}
        self.assertTrue(source.issubset(codes))
        for app in ("chickmark", "pushkin", "what", "photo-pdf-to-size"):
            with self.subTest(app=app):
                entry = data["apps"][app]
                expected = source | {"nl"} | ({"id"} if app == "photo-pdf-to-size" else set())
                self.assertEqual(set(entry["ios"]["sourceCatalogs"]), expected)
                for relative in entry["bundles"]:
                    folder = ROOT / relative
                    self.assertEqual(
                        {p.name.removesuffix(".lproj") for p in folder.glob("*.lproj")},
                        expected, f"{relative}: registry drift",
                    )
