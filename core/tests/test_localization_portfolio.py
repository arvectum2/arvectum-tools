"""Pure Python localization registry/format safety checks."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "core/tools"))
import localization_portfolio as i18n


class LocalizationPortfolioTests(unittest.TestCase):
    def test_registry(self):
        reg = i18n.config()
        self.assertEqual(len(reg["targets"]), 50)
        self.assertEqual(reg["targets"][0]["code"], "en")
        self.assertEqual(reg["fallback"], "en")
        self.assertEqual(set(reg["apps"]), {"chickmark", "pushkin", "what", "photo-pdf-to-size", "where"})
        self.assertEqual(reg["apps"]["photo-pdf-to-size"]["android"]["sourceLocale"], "en")
        self.assertEqual([sum(x["tier"] == t for x in reg["targets"]) for t in (1, 2, 3)], [20, 20, 10])

    def test_placeholders(self):
        self.assertEqual(i18n.placeholders("%d of %@"), i18n.placeholders("%2$@ from %1$d"))
        self.assertNotEqual(i18n.placeholders("%d of %@"), i18n.placeholders("%@"))
        self.assertEqual(i18n.placeholders("Print at 100% scale"), {})

    def test_dynamic_source_inventory_reports_untranslated_interpolation(self):
        findings = i18n.dynamic_inventory()
        self.assertTrue(findings)
        # What and Photo now use argument-aware complete format strings;
        # the remaining simple numeric SwiftUI values in ChickMark stay tracked.
        self.assertFalse(any(item["app"] in {"what", "photo-pdf-to-size"} for item in findings))
        self.assertTrue(any(item["app"] == "chickmark" for item in findings))
        self.assertTrue(all(item["status"] == "requires-review" for item in findings))

    def test_bilingual_copy_and_native_ru_resources_do_not_drift(self):
        errors = []
        i18n.bilingual_catalog_sync_audit(errors)
        self.assertEqual(errors, [])

    def test_bilingual_dynamic_placeholders(self):
        errors = []
        i18n.bilingual_format_audit(errors)
        self.assertEqual(errors, [])

    def test_android_brazilian_portuguese_draft(self):
        from xml.etree import ElementTree
        root = ROOT / "photo-pdf-to-size/android/app/src/main/res"
        base = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values/strings.xml").getroot()}
        pt = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values-pt-rBR/strings.xml").getroot()}
        self.assertEqual(set(base), set(pt))
        self.assertEqual(len(pt), 93)
        self.assertEqual(pt["app_name"], "Redimensionar fotos")
        self.assertIn("somente neste dispositivo", pt["your_photo_is_processed_only_on_this_device"])
        self.assertIn("%1$s", pt["compress_to"])

    def test_photo_ios_spanish_catalog_and_tracking_disclosure(self):
        path = ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Resources"
        en = i18n.read_strings(path / "en.lproj/Localizable.strings", [])
        es = i18n.read_strings(path / "es.lproj/Localizable.strings", [])
        self.assertEqual(set(en), set(es))
        self.assertEqual(len(es), 155)
        self.assertEqual(es["Сжать PDF до выбранного размера"], "Comprimir PDF al tamaño elegido")
        self.assertTrue(any("Yandex Mobile Ads" in text and "dispositivo" in text for text in es.values()))
        info = i18n.read_strings(path / "es.lproj/InfoPlist.strings", [])
        self.assertEqual(set(info), {"CFBundleDisplayName", "NSUserTrackingUsageDescription"})
        self.assertIn("identificador publicitario", info["NSUserTrackingUsageDescription"])

    def test_android_spanish_draft_has_real_ui_copy(self):
        from xml.etree import ElementTree
        spanish = ROOT / "photo-pdf-to-size/android/app/src/main/res/values-es/strings.xml"
        strings = {child.attrib["name"]: child.text for child in ElementTree.parse(spanish).getroot()}
        self.assertEqual(strings["app_name"], "Redimensionar fotos")
        self.assertIn("dispositivo", strings["your_photo_is_processed_only_on_this_device"])
        self.assertIn("%1$s", strings["compress_to"])

    def test_existing_catalogs(self):
        self.assertEqual(i18n.audit(i18n.config()), 0)

    def test_english_development_region(self):
        for name in ("chickmark/ios/HabitsByArvectumIOS", "photo-pdf-to-size/ios/PhotoPodRazmerIOS", "pushkin/ios/ArvectumNotifyIOS", "what/ios/What"):
            project = ROOT / (name + ".xcodeproj/project.pbxproj")
            with self.subTest(name=name):
                self.assertIn("developmentRegion = en;", project.read_text())


if __name__ == "__main__":
    unittest.main()
