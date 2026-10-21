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

    def test_direct_language_branch_scanner_catches_bypass(self):
        # A historical What home-screen regression used this Swift ternary
        # without consulting CaptureBrand. Catalog-key equality missed it.
        source = 'Text(isRussian ? "Ухвати мысль" : "Catch that thought")'
        self.assertIsNotNone(i18n.DIRECT_LOCALE_TERNARY.search(source))
        source = 'Text(language == "ru" ? "Готово" : "Done")'
        self.assertIsNotNone(i18n.EXPLICIT_LOCALE_TERNARY.search(source))
        current = i18n.dynamic_inventory()
        self.assertFalse(any(
            f["kind"] in ("direct-locale-ternary", "explicit-locale-ternary")
            for f in current
        ))

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

    def test_android_dutch_catalog_complete_and_placeholder_safe(self):
        from xml.etree import ElementTree
        root = ROOT / "photo-pdf-to-size/android/app/src/main/res"
        base = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values/strings.xml").getroot()}
        dutch = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values-nl/strings.xml").getroot()}
        self.assertEqual(set(base), set(dutch))
        self.assertEqual(len(dutch), 93)
        self.assertEqual(dutch["app_name"], "Foto verkleinen")
        self.assertIn("alleen op dit apparaat", dutch["your_photo_is_processed_only_on_this_device"])
        self.assertEqual(dutch["compress_to"], "Comprimeren tot %1$s")
        self.assertEqual(dutch["size_in_mb_decimal"], "%1$.2f MB")
        self.assertTrue(all(
            i18n.placeholders(base[k]) == i18n.placeholders(dutch[k]) for k in base
        ))

    def test_android_polish_catalog_complete_and_placeholder_safe(self):
        from xml.etree import ElementTree
        root = ROOT / "photo-pdf-to-size/android/app/src/main/res"
        base = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values/strings.xml").getroot()}
        polish = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values-pl/strings.xml").getroot()}
        self.assertEqual(set(base), set(polish))
        self.assertEqual(len(polish), 93)
        self.assertEqual(polish["app_name"], "Zmiana rozmiaru zdjęć")
        self.assertIn("tylko na tym urządzeniu", polish["your_photo_is_processed_only_on_this_device"])
        self.assertEqual(polish["compress_to"], "Skompresuj do %1$s")
        self.assertIn("%2$d%%", polish["reduction_summary"])
        self.assertTrue(all(
            i18n.placeholders(base[k]) == i18n.placeholders(polish[k]) for k in base
        ))

    def test_android_italian_catalog_complete_and_placeholder_safe(self):
        from xml.etree import ElementTree
        root = ROOT / "photo-pdf-to-size/android/app/src/main/res"
        base = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values/strings.xml").getroot()}
        italian = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values-it/strings.xml").getroot()}
        self.assertEqual(set(base), set(italian))
        self.assertEqual(len(italian), 93)
        self.assertEqual(italian["app_name"], "Ridimensiona foto")
        self.assertIn("solo su questo dispositivo", italian["your_photo_is_processed_only_on_this_device"])
        self.assertEqual(italian["compress_to"], "Comprimi a %1$s")
        self.assertIn("%2$d%%", italian["reduction_summary"])
        self.assertEqual(italian["size_in_mb_decimal"], "%1$.2f MB")
        self.assertTrue(all(
            i18n.placeholders(base[k]) == i18n.placeholders(italian[k])
            for k in base
        ))

    def test_android_german_catalog_covers_all_errors_and_formats(self):
        from xml.etree import ElementTree
        root = ROOT / "photo-pdf-to-size/android/app/src/main/res"
        base = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values/strings.xml").getroot()}
        german = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values-de/strings.xml").getroot()}
        self.assertEqual(set(base), set(german))
        self.assertEqual(len(german), 93)
        self.assertEqual(german["app_name"], "Fotos verkleinern")
        self.assertIn("nur auf diesem Gerät", german["your_photo_is_processed_only_on_this_device"])
        self.assertIn("%2$d%%", german["reduction_summary"])
        self.assertEqual(german["size_in_mb_decimal"], "%1$.2f MB")
        self.assertNotEqual(german["cannot_prepare_passport"], base["cannot_prepare_passport"])
        self.assertTrue(all(
            i18n.placeholders(base[key]) == i18n.placeholders(german[key])
            for key in base
        ))

    def test_android_french_catalog_has_complete_native_copy(self):
        from xml.etree import ElementTree
        root = ROOT / "photo-pdf-to-size/android/app/src/main/res"
        base = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values/strings.xml").getroot()}
        fr = {el.attrib["name"]: el.text for el in ElementTree.parse(root / "values-fr/strings.xml").getroot()}
        self.assertEqual(set(base), set(fr))
        self.assertEqual(len(fr), 93)
        self.assertEqual(fr["app_name"], "Redimensionner les photos")
        self.assertIn("uniquement sur cet appareil", fr["your_photo_is_processed_only_on_this_device"])
        self.assertIn("%1$s", fr["compress_to"])
        self.assertNotEqual(fr["cannot_save_file"], base["cannot_save_file"])

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

    def test_what_home_cannot_reintroduce_english_only_ternaries(self):
        home = (ROOT / "what/ios/WhatIOS/QuickCaptureHomeView.swift").read_text()
        self.assertNotRegex(home, r'\bisRussian\s*\?\s*"')
        errors = []
        i18n.bilingual_catalog_sync_audit(errors)
        self.assertEqual(errors, [])

    def test_what_spanish_covers_phone_watch_widget_and_complication(self):
        roots = ["WhatIOS", "WhatWatch", "WhatPhoneWidget", "WhatWatchComplication"]
        keys = [213, 6, 6, 5]
        for bundle, expected in zip(roots, keys):
            root = ROOT / "what/ios" / bundle
            english = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
            spanish = i18n.read_strings(root / "es.lproj/Localizable.strings", [])
            russian = i18n.read_strings(root / "ru.lproj/Localizable.strings", [])
            self.assertEqual(set(english), set(spanish), bundle)
            self.assertEqual(set(english), set(russian), bundle)
            self.assertEqual(len(spanish), expected, bundle)
            for key in english:
                self.assertEqual(
                    i18n.placeholders(english[key]),
                    i18n.placeholders(spanish[key]), f"{bundle}/{key}"
                )
        root = ROOT / "what/ios/WhatIOS/es.lproj/Localizable.strings"
        home = i18n.read_strings(root, [])
        self.assertEqual(home["Catch that thought"], "Captura esa idea")
        self.assertEqual(home["All notes"], "Todas las notas")
        self.assertEqual(home["All notes, %@"], "Todas las notas, %@")
        self.assertEqual(home["Español"], "Español")
        self.assertNotIn("Español (English interface)", home)

    def test_pushkin_spanish_catalog_covers_all_real_english_copy(self):
        root = ROOT / "pushkin/ios/ArvectumNotify/Resources"
        en = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
        es = i18n.read_strings(root / "es.lproj/Localizable.strings", [])
        self.assertEqual(set(en), set(es))
        self.assertEqual(len(es), 151)
        self.assertEqual(es["History"], "Historial")
        self.assertEqual(es["Group %d"], "Grupo %d")
        self.assertEqual(es["Apps"], "Aplicaciones")
        self.assertIn("Atajos", es["PUSHKIN works through Apple Shortcuts"])
        self.assertIn("1.000", es["One base shortcut can contain 1,000 app entries. Optional groups of 25 are just a planning convenience, not an iOS limit."])
        self.assertTrue(all(i18n.placeholders(en[k]) == i18n.placeholders(es[k]) for k in en))

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
