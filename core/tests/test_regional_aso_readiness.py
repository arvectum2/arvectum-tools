"""Country/ASO/read-only Apple observation must never be conflated."""
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "core/tools"))
import regional_aso_readiness as readiness


class RegionalASOReadinessTests(unittest.TestCase):
    def test_all_64_observed_storefront_app_pairs_map_to_real_staged_cards(self):
        report = readiness.build_report()
        self.assertEqual(report["draft_cards_checked"], 64)
        self.assertEqual(report["storefronts_observed"], 16)
        self.assertEqual(report["target_interface_locales"], 50)
        self.assertEqual(report["source_interface_locales_per_app"], 14)
        self.assertEqual(len({(r["app"], r["country"]) for r in report["rows"]}), 64)
        self.assertTrue(all(r["interface_source_exists"] for r in report["rows"]))
        self.assertTrue(all(r["draft_only"] and
                            not r["apple_metadata_locale_verified_for_country"]
                            for r in report["rows"]))
        self.assertEqual(report["status"], "READ_ONLY_SNAPSHOT_NOT_LIVE_ASC")
        self.assertTrue(report["observed_utc"].startswith("2026-10-28T"))

    def test_english_and_regional_script_mapping_does_not_create_new_ui_language(self):
        self.assertEqual(readiness.source_locale("en-GB"), "en")
        self.assertEqual(readiness.source_locale("en-CA"), "en")
        self.assertEqual(readiness.source_locale("es-MX"), "es")
        self.assertEqual(readiness.source_locale("pt-PT"), "pt-PT")
        self.assertEqual(readiness.source_locale("pt-BR"), "pt-BR")
        self.assertEqual(readiness.source_locale("zh-Hant"), "zh-Hant")
        self.assertEqual(readiness.source_locale("zh-Hans"), "zh-Hans")

    def test_fails_closed_when_card_or_country_missing(self):
        with tempfile.TemporaryDirectory(prefix="regional-aso-audit-") as tmp:
            root = Path(tmp)
            base = root / "core/appstore/staged-2026-10-26"
            (base / "editorial").mkdir(parents=True)
            (root / "core/localization").mkdir(parents=True)
            source = ROOT / "core/appstore/staged-2026-10-26"
            for app in readiness.APPS:
                shutil.copyfile(source / f"{app}.json", base / f"{app}.json")
            shutil.copyfile(readiness.SNAPSHOT,
                            base / "editorial/c18-public-storefront-individual-20261028.json")
            shutil.copyfile(readiness.REGISTRY,
                            root / "core/localization/portfolio-locales.json")
            self.assertEqual(len(readiness.build_report(root)["rows"]), 64)
            card_path = base / "what.json"
            card = json.loads(card_path.read_text())
            del card["localeData"]["en-GB"]
            card_path.write_text(json.dumps(card))
            with self.assertRaisesRegex(AssertionError, "draft locale mismatch"):
                readiness.build_report(root)
            shutil.copyfile(source / "what.json", card_path)
            snapshot_path = base / "editorial/c18-public-storefront-individual-20261028.json"
            snapshot = json.loads(snapshot_path.read_text())
            snapshot["apps"]["photo"]["us"]["bundleId"] = "foreign.app"
            snapshot_path.write_text(json.dumps(snapshot))
            with self.assertRaisesRegex(AssertionError, "mixed bundle"):
                readiness.build_report(root)
