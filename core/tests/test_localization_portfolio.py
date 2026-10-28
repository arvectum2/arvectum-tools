"""Pure Python localization registry/format safety checks."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "core/tools"))
import localization_portfolio as i18n


class LocalizationPortfolioTests(unittest.TestCase):
    def test_photo_european_portuguese_draft_parity(self):
        """Draft must keep keys/placeholders without implying release readiness."""
        base = ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Resources"
        for filename in ("Localizable.strings", "InfoPlist.strings"):
            br = i18n.read_strings(base / "pt-BR.lproj" / filename, [])
            pt = i18n.read_strings(base / "pt-PT.lproj" / filename, [])
            self.assertEqual(set(br), set(pt))
            for key in br:
                self.assertEqual(i18n.PRINTF.findall(br[key]), i18n.PRINTF.findall(pt[key]), key)
        pt = i18n.read_strings(base / "pt-PT.lproj/Localizable.strings", [])
        self.assertEqual(pt["Сохранить файл"], "Guardar ficheiro")
        self.assertEqual(pt["Поделиться"], "Partilhar")

    def test_pt_pt_draft_parity_all_ios_bundles(self):
        """Draft-only parity; native copy and device QA remain mandatory."""
        reg = i18n.config()
        for app in ("chickmark", "pushkin", "what", "photo-pdf-to-size"):
            for bundle in reg["apps"][app]["bundles"]:
                root = ROOT / bundle
                for br_file in (root / "pt-BR.lproj").glob("*.strings"):
                    pt_file = root / "pt-PT.lproj" / br_file.name
                    self.assertTrue(pt_file.is_file(), str(pt_file))
                    br = i18n.read_strings(br_file, [])
                    pt = i18n.read_strings(pt_file, [])
                    self.assertEqual(set(br), set(pt), str(pt_file))
                    for key in br:
                        self.assertEqual(i18n.PRINTF.findall(br[key]),
                                         i18n.PRINTF.findall(pt[key]), key)

    def test_korean_draft_ui_smoke_is_present_for_two_apps(self):
        """Verify Korean synthetic UI tests across all four apps; still not editorially approved."""
        dirs = (
            "photo-pdf-to-size/ios/PhotoPodRazmerUITests",
            "pushkin/ios/ArvectumNotifyUITests",
            "what/ios/WhatIOSUITests",
            "chickmark/ios/HabitsByArvectumUITests",
        )
        for directory in dirs:
            path = ROOT / directory / "KoreanLocalizationUITests.swift"
            text = path.read_text(encoding="utf-8")
            self.assertIn("final class KoreanLocalizationUITests", text)
            self.assertIn("func testKorean", text)
            self.assertIn("(ko)", text)
            self.assertIn("ko_KR", text)

    def test_photo_korean_draft_parity(self):
        """Korean photo-only draft; review and other apps remain outstanding."""
        root = ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Resources"
        for filename in ("Localizable.strings", "InfoPlist.strings"):
            en = i18n.read_strings(root / "en.lproj" / filename, [])
            ko = i18n.read_strings(root / "ko.lproj" / filename, [])
            self.assertEqual(set(en), set(ko), filename)
            for key in en:
                self.assertEqual(i18n.PRINTF.findall(en[key]),
                                 i18n.PRINTF.findall(ko[key]), key)
        en = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
        ko = i18n.read_strings(root / "ko.lproj/Localizable.strings", [])
        untranslated = [key for key in en if en[key] == ko[key]]
        self.assertLessEqual(len(untranslated), 10)
        self.assertEqual(ko["Сохранить файл"], "파일 저장")

    def test_pushkin_korean_draft_parity(self):
        """Pushkin Korean source catalog must preserve all English keys and tokens."""
        root = ROOT / "pushkin/ios/ArvectumNotify/Resources"
        en = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
        ko = i18n.read_strings(root / "ko.lproj/Localizable.strings", [])
        self.assertEqual(set(en), set(ko))
        for key in en:
            self.assertEqual(i18n.PRINTF.findall(en[key]),
                             i18n.PRINTF.findall(ko[key]), key)
            self.assertNotEqual(en[key], ko[key], key)
        self.assertEqual(ko["History"], "기록")

    def test_all_four_korean_catalogs_are_structurally_complete(self):
        """Korean drafts in all active bundles must have full key and format parity."""
        reg = i18n.config()
        for app in ("chickmark", "pushkin", "what", "photo-pdf-to-size"):
            for bundle in reg["apps"][app]["bundles"]:
                root = ROOT / bundle
                for english_file in sorted((root / "en.lproj").glob("*.strings")):
                    korean_file = root / "ko.lproj" / english_file.name
                    self.assertTrue(korean_file.exists(), str(korean_file))
                    english = i18n.read_strings(english_file, [])
                    korean = i18n.read_strings(korean_file, [])
                    self.assertEqual(set(english), set(korean), str(korean_file))
                    for key in english:
                        self.assertEqual(i18n.placeholders(english[key]),
                                         i18n.placeholders(korean[key]), f"{bundle}/{key}")
                        if english_file.name == "AppShortcuts.strings":
                            self.assertIn("$" + "{applicationName}", korean[key])
        self.assertEqual(
            i18n.read_strings(ROOT / "chickmark/ios/HabitsByArvectum/ko.lproj/Localizable.strings", [])["habit.create"],
            "습관 만들기")

    def test_photo_source_preview_captions_are_localized_in_12_languages(self):
        cases = {
            "ru": "Исходный файл", "en": "Source file", "de": "Quelldatei",
            "es": "Archivo original", "fr": "Fichier d’origine",
            "it": "File originale", "ja": "元のファイル", "ko": "원본 파일",
            "pt-BR": "Arquivo original", "pt-PT": "Ficheiro original",
            "zh-Hans": "原始文件", "zh-Hant": "原始檔案",
        }
        root = ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Resources"
        for locale, expected in cases.items():
            loc = i18n.read_strings(root / f"{locale}.lproj/Localizable.strings", [])
            self.assertEqual(loc["Исходный файл"], expected, locale)
            self.assertTrue(loc["Предпросмотр исходного файла"], locale)
            if locale != "ru":
                self.assertNotEqual(loc["Предпросмотр исходного файла"],
                                    "Предпросмотр исходного файла", locale)

    def test_korean_uhvat_headline_is_idiomatic(self):
        loc = i18n.read_strings(ROOT / "what/ios/WhatIOS/ko.lproj/Localizable.strings", [])
        self.assertEqual(loc["Catch that thought"], "떠오른 생각을 기록하세요")
        self.assertNotIn("그 생각을 잡아라", " ".join(loc.values()))

    def test_korean_apple_health_is_protected_brand_not_fruit(self):
        """An in-review iPad screenshot exposed the literal fruit-translation bug."""
        translations = i18n.read_strings(
            ROOT / "chickmark/ios/HabitsByArvectum/ko.lproj/Localizable.strings", [])
        self.assertEqual(translations["health.title"], "Apple Health")
        self.assertEqual(translations["health.settings"], "Apple Health")
        self.assertEqual(translations["health.disconnect"], "Apple Health 연결 해제")
        self.assertNotIn("사과 건강", " ".join(translations.values()))

    def test_korean_habit_editorial_glossary_and_weekly_ratio(self):
        values = i18n.read_strings(
            ROOT / "chickmark/ios/HabitsByArvectum/ko.lproj/Localizable.strings", [])
        self.assertEqual(values["appearance.icon"], "아이콘")
        self.assertEqual(values["health.metric.steps"], "걸음 수")
        self.assertEqual(values["health.unit.steps"], "걸음")
        self.assertEqual(values["health.metric.sleep"], "수면 시간(기상일 기준)")
        self.assertEqual(values["insights.weekly.ratio"], "%d주 달성 / 총 %d주")
        self.assertNotIn("요금", values["insights.weekly.note"])
        self.assertEqual(i18n.placeholders("%d of %d weeks"),
                         i18n.placeholders(values["insights.weekly.ratio"]))

    def test_editorial_audit_is_triage_not_signoff(self):
        import editorial_localization_audit as review
        result = review.audit()
        self.assertGreaterEqual(result["files"], 180)
        self.assertGreaterEqual(result["entries"], 9000)
        self.assertEqual(sum(f["pt_pt_brazilian_flags"] for f in result["catalogs"]), 0)
        self.assertEqual(sum(f["format_mismatch"] for f in result["catalogs"]), 0)
        self.assertEqual(sum(f["missing"] + f["extra"] for f in result["catalogs"]), 0)
        self.assertEqual(result['english_identical_triaged'], 34)
        self.assertEqual(result['english_identical_untriaged'], [])
        self.assertEqual(result['english_identical_stale_exceptions'], [])

    def test_editorial_report_order_is_stable(self):
        # Reproducible reports make real copy changes visible in code review.
        import editorial_localization_audit as review
        self.assertEqual(review.audit(), review.audit())
        # Two interpreter hash seeds must produce byte-identical issue ordering.
        import os
        import subprocess
        script = ("import json,sys; sys.path.insert(0, 'core/tools'); "
                  "import editorial_localization_audit as a; "
                  "print(json.dumps(a.audit()['findings'], ensure_ascii=False))")
        outputs = []
        for seed in ('1', '29'):
            env = dict(os.environ, PYTHONHASHSEED=seed)
            outputs.append(subprocess.check_output(
                [sys.executable, '-c', script], cwd=ROOT, env=env))
        self.assertEqual(outputs[0], outputs[1])

    def test_pt_pt_editorial_regressions(self):
        import editorial_localization_audit as review
        finding = review.audit()
        self.assertFalse([f for f in finding["findings"]
                          if f["kind"] == "pt_pt_brazilian_flags"],
                         "Portuguese (Portugal) regional terms need another pass")
        base = ROOT / "chickmark/ios/HabitsByArvectum/pt-PT.lproj/Localizable.strings"
        values = i18n.read_strings(base, [])
        self.assertEqual(values["detail.history.hint"],
                         "Toque num dia anterior para corrigir o seu registo.")
        self.assertIn("Os seus hábitos", values["manage.empty.description"])
        self.assertIn("os seus hábitos", values["backup.warning"])

    def test_registry(self):
        reg = i18n.config()
        self.assertEqual(len(reg["targets"]), 50)
        self.assertEqual(reg["targets"][0]["code"], "en")
        self.assertEqual(reg["fallback"], "en")
        delivery = reg["deliveryPriority"]
        self.assertEqual(delivery["platforms"], ["ios", "watchos", "android"])
        self.assertEqual(delivery["iosFirstWave"], ["en", "ru", "es", "fr"])
        self.assertEqual(delivery["iosNextWave"], ["de", "pt-BR", "it", "ja", "zh-Hans"])

        self.assertEqual(set(reg["apps"]), {"chickmark", "pushkin", "what", "photo-pdf-to-size", "where"})
        self.assertEqual(reg["apps"]["photo-pdf-to-size"]["android"]["sourceLocale"], "en")
        self.assertEqual(reg["apps"]["photo-pdf-to-size"]["ios"]["sourceCatalogs"],
                         ["en", "ru", "es", "fr", "de", "pt-BR", "pt-PT", "it", "ja", "zh-Hans", "zh-Hant"])
        for app in ("pushkin", "what", "chickmark"):
            self.assertEqual(reg["apps"][app]["ios"]["sourceCatalogs"],
                             ["en", "ru", "es", "fr", "de", "pt-BR", "pt-PT", "it", "ja", "zh-Hans", "zh-Hant"])

        self.assertEqual([sum(x["tier"] == t for x in reg["targets"]) for t in (1, 2, 3)], [20, 20, 10])

    def test_all_four_ios_apps_have_eleven_language_ui_smoke_coverage(self):
        """Maintain a source-level iPhone UI smoke for 44 app-locale pairs.

        Presence proves the test is authored, not that it passed or was run
        on a real device. Native XCUITest remains an independent CI gate.
        """
        roots = {
            "photo": "photo-pdf-to-size/ios/PhotoPodRazmerUITests",
            "pushkin": "pushkin/ios/ArvectumNotifyUITests",
            "what": "what/ios/WhatIOSUITests",
            "chickmark": "chickmark/ios/HabitsByArvectumUITests",
        }
        code_names = {
            "es": "Spanish", "fr": "French", "de": "German",
            "pt-BR": "BrazilianPortuguese", "pt-PT": "EuropeanPortuguese", "it": "Italian",
            "ja": "Japanese", "zh-Hans": "SimplifiedChinese", "zh-Hant": "TraditionalChinese",
        }
        registry = i18n.config()
        covered = 0
        app_registry_names = {"photo": "photo-pdf-to-size",
                              "pushkin": "pushkin", "what": "what",
                              "chickmark": "chickmark"}
        for app, relative_root in roots.items():
            # New iOS source locales must add an explicit UI smoke mapping.
            # Reject any locale without an authored XCUITest smoke mapping.
            locales = set(registry["apps"][app_registry_names[app]]["ios"]["sourceCatalogs"])
            self.assertEqual(
                locales, {"ru", "en", *code_names},
                f"{app}: new source locale must have a UI smoke test mapping")
            root = ROOT / relative_root
            baseline = (root / "CoreLanguageCoverageUITests.swift").read_text()
            self.assertIn("final class CoreLanguageCoverageUITests", baseline)
            for locale, method in (
                ("ru", "testRussianBaseline"),
                ("en", "testEnglishBaseline"),
            ):
                self.assertIn("func " + method, baseline, f"{app}/{locale}")
                covered += 1
            for locale, name in code_names.items():
                path = root / (name + "LocalizationUITests.swift")
                if path.exists():
                    text = path.read_text()
                    self.assertIn("final class " + name + "LocalizationUITests", text)
                    self.assertIn("func test", text, f"{app}/{locale}")
                else:
                    method = "test" + name
                    self.assertIn("func " + method, baseline,
                                  f"{app}/{locale}: no dedicated UI smoke")
                covered += 1
        self.assertEqual(covered, 44)

    def test_all_active_ios_bundles_have_eleven_localized_catalogs(self):
        """First eleven localization packs are present in all active iOS bundles.

        This tests source parity, not linguistic quality or App Store release.
        """
        registry = i18n.config()
        for app in ("chickmark", "pushkin", "what", "photo-pdf-to-size"):
            for name in registry["apps"][app]["bundles"]:
                bundle = ROOT / name
                baseline = i18n.read_strings(
                    bundle / "en.lproj/Localizable.strings", [])
                self.assertTrue(baseline, f"{app}/{name} missing English")
                for code in ("ru", "es", "fr", "de", "pt-BR", "pt-PT", "it", "ja", "zh-Hans", "zh-Hant"):
                    errors = []
                    translated = i18n.read_strings(
                        bundle / f"{code}.lproj/Localizable.strings", errors)
                    self.assertEqual(errors, [], f"{app}/{name}/{code}")
                    self.assertEqual(
                        set(baseline), set(translated),
                        f"{app}/{name}/{code} missing or extra keys")
                    for key in baseline:
                        self.assertEqual(
                            i18n.placeholders(baseline[key]),
                            i18n.placeholders(translated[key]),
                            f"{app}/{name}/{code}/{key}")

    def test_traditional_chinese_is_distinct_from_simplified_in_each_bundle(self):
        """zh-Hant must not be an English or Simplified copy. Native QA is separate."""
        registry = i18n.config()
        for app in ("chickmark", "pushkin", "what", "photo-pdf-to-size"):
            for name in registry["apps"][app]["bundles"]:
                folder = ROOT / name
                zh_hans = i18n.read_strings(folder / "zh-Hans.lproj/Localizable.strings", [])
                zh_hant = i18n.read_strings(folder / "zh-Hant.lproj/Localizable.strings", [])
                en = i18n.read_strings(folder / "en.lproj/Localizable.strings", [])
                self.assertEqual(set(en), set(zh_hant), name)
                self.assertTrue(any(zh_hans[key] != zh_hant[key] for key in en),
                                f"{name}: Traditional must differ from Simplified")
                self.assertTrue(any(en[key] != zh_hant[key] for key in en),
                                f"{name}: Traditional must differ from English")

    def test_traditional_chinese_system_permissions_and_shortcuts(self):
        required = {
            "photo-pdf-to-size/ios/PhotoPodRazmer/Resources": ["InfoPlist.strings"],
            "what/ios/WhatIOS": ["InfoPlist.strings"],
            "what/ios/WhatWatch": ["InfoPlist.strings"],
            "what/ios/WhatPhoneWidget": ["InfoPlist.strings"],
            "what/ios/WhatWatchComplication": ["InfoPlist.strings"],
            "chickmark/ios/HabitsByArvectum": ["InfoPlist.strings", "AppShortcuts.strings"],
            "chickmark/ios/HabitsByArvectumWatch": ["InfoPlist.strings"],
        }
        for bundle, filenames in required.items():
            for filename in filenames:
                root = ROOT / bundle
                base = i18n.read_strings(root / "en.lproj" / filename, [])
                hant = i18n.read_strings(root / "zh-Hant.lproj" / filename, [])
                self.assertTrue(base, f"{bundle}/{filename}: missing base")
                self.assertEqual(set(base), set(hant), f"{bundle}/{filename}")
                for key in base:
                    self.assertEqual(i18n.placeholders(base[key]),
                                     i18n.placeholders(hant[key]),
                                     f"{bundle}/{filename}/{key}")

    def test_simplified_chinese_info_plist_and_shortcuts(self):
        required = {
            "photo-pdf-to-size/ios/PhotoPodRazmer/Resources": ["InfoPlist.strings"],
            "what/ios/WhatIOS": ["InfoPlist.strings"],
            "what/ios/WhatWatch": ["InfoPlist.strings"],
            "what/ios/WhatPhoneWidget": ["InfoPlist.strings"],
            "what/ios/WhatWatchComplication": ["InfoPlist.strings"],
            "chickmark/ios/HabitsByArvectum": ["InfoPlist.strings", "AppShortcuts.strings"],
            "chickmark/ios/HabitsByArvectumWatch": ["InfoPlist.strings"],
        }
        for bundle, filenames in required.items():
            root = ROOT / bundle
            for filename in filenames:
                errors = []
                base = i18n.read_strings(root / "en.lproj" / filename, errors)
                translated = i18n.read_strings(root / "zh-Hans.lproj" / filename, errors)
                self.assertEqual(errors, [], f"{bundle}/{filename}")
                self.assertTrue(base)
                self.assertEqual(set(base), set(translated))
                for key in base:
                    self.assertEqual(i18n.placeholders(base[key]), i18n.placeholders(translated[key]),
                                     f"{bundle}/{filename}/{key}")
                    if filename == "AppShortcuts.strings":
                        self.assertIn("$" + "{applicationName}", translated[key])
                    if key.startswith("NS") and "UsageDescription" in key:
                        self.assertNotEqual(base[key], translated[key])

    def test_simplified_chinese_has_real_translations_not_english_copy(self):
        reg = i18n.config()
        for app in ("chickmark", "pushkin", "what", "photo-pdf-to-size"):
            for name in reg["apps"][app]["bundles"]:
                bundle = ROOT / name
                en = i18n.read_strings(bundle / "en.lproj/Localizable.strings", [])
                zh = i18n.read_strings(bundle / "zh-Hans.lproj/Localizable.strings", [])
                self.assertGreaterEqual(
                    sum(en[k] != zh[k] for k in en) / len(en), 0.60,
                    f"{name} appears to contain English placeholders")

    def test_japanese_info_plist_and_shortcuts(self):
        required = {
            "photo-pdf-to-size/ios/PhotoPodRazmer/Resources": ["InfoPlist.strings"],
            "what/ios/WhatIOS": ["InfoPlist.strings"],
            "what/ios/WhatWatch": ["InfoPlist.strings"],
            "what/ios/WhatPhoneWidget": ["InfoPlist.strings"],
            "what/ios/WhatWatchComplication": ["InfoPlist.strings"],
            "chickmark/ios/HabitsByArvectum": ["InfoPlist.strings", "AppShortcuts.strings"],
            "chickmark/ios/HabitsByArvectumWatch": ["InfoPlist.strings"],
        }
        for bundle, filenames in required.items():
            root = ROOT / bundle
            for filename in filenames:
                errors = []
                base = i18n.read_strings(root / "en.lproj" / filename, errors)
                japanese = i18n.read_strings(root / "ja.lproj" / filename, errors)
                self.assertEqual(errors, [], f"{bundle}/{filename}")
                self.assertTrue(base)
                self.assertEqual(set(base), set(japanese))
                for key in base:
                    self.assertEqual(i18n.placeholders(base[key]), i18n.placeholders(japanese[key]),
                                     f"{bundle}/{filename}/{key}")
                    if filename == "AppShortcuts.strings":
                        self.assertIn("$" + "{applicationName}", japanese[key])
                    if key.startswith("NS") and "UsageDescription" in key:
                        self.assertNotEqual(base[key], japanese[key])

    def test_japanese_catalogs_are_not_english_placeholders(self):
        reg = i18n.config()
        for app in ("chickmark", "pushkin", "what", "photo-pdf-to-size"):
            for name in reg["apps"][app]["bundles"]:
                bundle = ROOT / name
                en = i18n.read_strings(bundle / "en.lproj/Localizable.strings", [])
                ja = i18n.read_strings(bundle / "ja.lproj/Localizable.strings", [])
                changed = sum(en[key] != ja[key] for key in en)
                self.assertGreaterEqual(changed / len(en), 0.60, f"{name} looks like English")

    def test_italian_info_plist_and_shortcuts(self):
        required = {
            "photo-pdf-to-size/ios/PhotoPodRazmer/Resources": ["InfoPlist.strings"],
            "what/ios/WhatIOS": ["InfoPlist.strings"],
            "what/ios/WhatWatch": ["InfoPlist.strings"],
            "what/ios/WhatPhoneWidget": ["InfoPlist.strings"],
            "what/ios/WhatWatchComplication": ["InfoPlist.strings"],
            "chickmark/ios/HabitsByArvectum": ["InfoPlist.strings", "AppShortcuts.strings"],
            "chickmark/ios/HabitsByArvectumWatch": ["InfoPlist.strings"],
        }
        for bundle, filenames in required.items():
            root = ROOT / bundle
            for filename in filenames:
                errors = []
                base = i18n.read_strings(root / "en.lproj" / filename, errors)
                italian = i18n.read_strings(root / "it.lproj" / filename, errors)
                self.assertEqual(errors, [], f"{bundle}/{filename}")
                self.assertTrue(base)
                self.assertEqual(set(base), set(italian))
                for key in base:
                    self.assertEqual(i18n.placeholders(base[key]), i18n.placeholders(italian[key]),
                                     f"{bundle}/{filename}/{key}")
                    if filename == "AppShortcuts.strings":
                        self.assertIn("$" + "{applicationName}", italian[key])
                    if key.startswith("NS") and "UsageDescription" in key:
                        self.assertNotEqual(base[key], italian[key])

    def test_italian_catalogs_are_not_english_placeholders(self):
        reg = i18n.config()
        for app in ("chickmark", "pushkin", "what", "photo-pdf-to-size"):
            for name in reg["apps"][app]["bundles"]:
                bundle = ROOT / name
                en = i18n.read_strings(bundle / "en.lproj/Localizable.strings", [])
                it = i18n.read_strings(bundle / "it.lproj/Localizable.strings", [])
                changed = sum(en[key] != it[key] for key in en)
                self.assertGreaterEqual(changed / len(en), 0.60, f"{name} still English")

    def test_brazilian_portuguese_info_plist_and_shortcuts(self):
        required = {
            "photo-pdf-to-size/ios/PhotoPodRazmer/Resources": ["InfoPlist.strings"],
            "what/ios/WhatIOS": ["InfoPlist.strings"],
            "what/ios/WhatWatch": ["InfoPlist.strings"],
            "what/ios/WhatPhoneWidget": ["InfoPlist.strings"],
            "what/ios/WhatWatchComplication": ["InfoPlist.strings"],
            "chickmark/ios/HabitsByArvectum": [
                "InfoPlist.strings", "AppShortcuts.strings"],
            "chickmark/ios/HabitsByArvectumWatch": ["InfoPlist.strings"],
        }
        for bundle, filenames in required.items():
            root = ROOT / bundle
            for filename in filenames:
                errors = []
                base = i18n.read_strings(root / "en.lproj" / filename, errors)
                translated = i18n.read_strings(
                    root / "pt-BR.lproj" / filename, errors)
                self.assertEqual(errors, [], f"{bundle}/{filename}")
                self.assertTrue(base)
                self.assertEqual(set(base), set(translated))
                for key in base:
                    self.assertEqual(
                        i18n.placeholders(base[key]),
                        i18n.placeholders(translated[key]),
                        f"{bundle}/{filename}/{key}")
                    if filename == "AppShortcuts.strings":
                        self.assertIn("$" + "{applicationName}", translated[key])
                    if key.startswith("NS") and "UsageDescription" in key:
                        self.assertNotEqual(base[key], translated[key])

    def test_brazilian_portuguese_has_real_non_english_app_copy(self):
        reg = i18n.config()
        for app in ("chickmark", "pushkin", "what", "photo-pdf-to-size"):
            for name in reg["apps"][app]["bundles"]:
                root = ROOT / name
                en = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
                pt = i18n.read_strings(root / "pt-BR.lproj/Localizable.strings", [])
                self.assertGreaterEqual(
                    sum(en[key] != pt[key] for key in en) / len(en),
                    0.60,
                    f"{app}/{name} pt-BR looks like English placeholder")

    def test_german_info_plist_and_shortcuts_bundles(self):
        # Localizable.strings key parity cannot detect missing permission
        # descriptions or Siri phrases. Validate companion DE resources.
        required = {
            "what/ios/WhatIOS": ["InfoPlist.strings"],
            "what/ios/WhatWatch": ["InfoPlist.strings"],
            "what/ios/WhatPhoneWidget": ["InfoPlist.strings"],
            "what/ios/WhatWatchComplication": ["InfoPlist.strings"],
            "chickmark/ios/HabitsByArvectum": [
                "InfoPlist.strings", "AppShortcuts.strings"],
            "chickmark/ios/HabitsByArvectumWatch": ["InfoPlist.strings"],
        }
        for bundle, filenames in required.items():
            root = ROOT / bundle
            for filename in filenames:
                errors = []
                base = i18n.read_strings(root / "en.lproj" / filename, errors)
                german = i18n.read_strings(root / "de.lproj" / filename, errors)
                self.assertEqual(errors, [], f"{bundle}/{filename}")
                self.assertTrue(base)
                self.assertEqual(set(base), set(german))
                for key in base:
                    self.assertEqual(
                        i18n.placeholders(base[key]),
                        i18n.placeholders(german[key]),
                        f"{bundle}/{filename}/{key}")
                    if filename == "AppShortcuts.strings":
                        self.assertIn("$" + "{applicationName}", german[key])
                if filename == "InfoPlist.strings":
                    for key in base:
                        if key.startswith("NS") and "UsageDescription" in key:
                            self.assertNotEqual(base[key], german[key],
                                                f"{bundle}/{key} untranslated")

    def test_german_portfolio_copy_is_not_an_english_placeholder(self):
        # Proper nouns/units can remain identical, but entire English
        # catalogs must not be copied and counted as a translated language.
        reg = i18n.config()
        for app in ("chickmark", "pushkin", "what", "photo-pdf-to-size"):
            for name in reg["apps"][app]["bundles"]:
                root = ROOT / name
                source = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
                german = i18n.read_strings(root / "de.lproj/Localizable.strings", [])
                changed = sum(source[k] != german[k] for k in source)
                self.assertGreaterEqual(
                    changed / len(source), 0.60,
                    f"{app}/{name} German looks like English fallback")

    def test_photo_ios_german_catalog_complete_and_placeholder_safe(self):
        # German is the first new iOS locale, not a claim that all apps have DE.
        bundle = ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Resources"
        errors = []
        base = i18n.read_strings(bundle / "en.lproj/Localizable.strings", errors)
        german = i18n.read_strings(bundle / "de.lproj/Localizable.strings", errors)
        self.assertEqual(errors, [])
        self.assertEqual(len(base), 161)
        self.assertEqual(set(base), set(german))
        for key in base:
            self.assertEqual(i18n.placeholders(base[key]),
                             i18n.placeholders(german[key]), key)
        self.assertEqual(german["Сжать файл"], "Datei komprimieren")
        self.assertEqual(german["ГОТОВО"], "FERTIG")
        self.assertEqual(german["Свой"], "Eigene")
        self.assertEqual(german["Сохранить файл"], "Datei speichern")
        self.assertNotEqual(german["Реклама и конфиденциальность"],
                            base["Реклама и конфиденциальность"])

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
        # Two Watch delivery-state explanations and five manual-retry strings
        # are included in the iPhone catalog, not the Watch or widgets.
        keys = [246, 6, 6, 5]
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
        self.assertEqual(home["Request Watch transfer"], "Solicitar transferencia del Watch")
        self.assertEqual(home["A sync request is already pending."],
                         "Ya hay una solicitud de sincronización pendiente.")
        self.assertEqual(home["All notes, %@"], "Todas las notas, %@")
        self.assertEqual(home["Español"], "Español")
        self.assertEqual(home["Speech recognition language"],
                         "Idioma de reconocimiento de voz")
        self.assertEqual(home["Today"], "Hoy")
        self.assertEqual(home["Yesterday"], "Ayer")
        self.assertEqual(home["Earlier"], "Anteriores")
        self.assertEqual(home["Interface language: iOS Settings"],
                         "Idioma de la interfaz: ajustes de iOS")
        self.assertNotIn("Español (English interface)", home)

    def test_what_recovery_ui_requires_confirmation_and_synthetic_qa(self):
        repo = (ROOT / "what/ios/WhatIOS/RecordingRepository.swift").read_text()
        view = (ROOT / "what/ios/WhatIOS/RecordingLibraryView.swift").read_text()
        app = (ROOT / "what/ios/WhatIOS/WhatApp.swift").read_text()
        tests = (ROOT /
                 "what/ios/WhatIOSUITests/SpanishLocalizationUITests.swift").read_text()
        self.assertIn("func transcriptRecoveryStatus()", repo)
        self.assertIn("guard !safe.isEmpty else", repo)
        recovery = view.split("// MARK: - Explicit, fail-closed transcript recovery", 1)[1]
        self.assertIn(".alert(", recovery)
        self.assertIn("isPresented: $showConfirmation", recovery)
        self.assertIn("what.recovery.restore", view)
        self.assertIn("what.recovery.confirm", view)
        self.assertIn("--qa-transcript-recovery-synthetic", app)
        self.assertIn("testSpanishTranscriptRecoverySyntheticPreviewWithoutAnyWrite", tests)
        self.assertIn("testSpanishTranscriptRecoverySyntheticCancelAndConfirm", tests)
        for scenario in ("missing-backup", "corrupt-backup", "empty-backup", "healthy"):
            self.assertIn("--qa-transcript-recovery-" + scenario, app)
            self.assertIn("--qa-transcript-recovery-" + scenario, view)
        for case in (
            "testSpanishRecoveryWithoutBackupHasNoRestoreAction",
            "testSpanishRecoveryWithCorruptBackupHasNoRestoreAction",
            "testSpanishRecoveryWithEmptyBackupHasNoRestoreAction",
            "testSpanishHealthyStorageHasNoRestoreAction",
        ):
            self.assertIn(case, tests)
        self.assertIn("TranscriptRecoveryQAFixtureView", view)

    def test_what_transcript_and_tombstone_writes_request_device_protection(self):
        repository = (ROOT / "what/ios/WhatIOS/RecordingRepository.swift").read_text()
        tests = (ROOT /
                 "what/ios/WhatIOSTests/RecordingRepositoryTests.swift").read_text()
        self.assertIn(".completeFileProtectionUntilFirstUserAuthentication",
                      repository)
        self.assertIn("options: protectedJSONOptions", repository)
        self.assertIn("testTranscriptAndBackupUseDeviceFileProtection", tests)
        self.assertIn("testDeletionMarkerUsesSameDeviceProtection", tests)

    def test_what_write_failure_checkpoints_are_debug_only(self):
        repo = (ROOT / "what/ios/WhatIOS/RecordingRepository.swift").read_text()
        tests = (ROOT /
                 "what/ios/WhatIOSTests/RecordingRepositoryTests.swift").read_text()
        self.assertIn("enum TranscriptWriteCheckpoint", repo)
        self.assertIn("case beforeBackup, afterBackup, afterPrimary", repo)
        self.assertIn("#if DEBUG", repo)
        self.assertIn("testTranscriptWriteCheckpoint?(.beforeBackup)", repo)
        self.assertIn("testTranscriptWriteCheckpoint?(.afterBackup)", repo)
        self.assertIn("testTranscriptWriteCheckpoint?(.afterPrimary)", repo)
        for test in (
            "testInterruptedBeforeShadowCommitKeepsOldCatalogAndAudio",
            "testInterruptedAfterShadowCommitKeepsPrimaryReadableAndReconcilesNextWrite",
            "testAutoRecognitionInterruptedAfterBackupPreservesOtherTranscripts",
            "testStopAfterMainCommitIsIdempotentlyVisibleOnReopen",
            "testDeleteInterruptedAtEitherCheckpointCompletesWithoutResurrecting",
        ):
            self.assertIn(test, tests)

    def test_what_transcript_backup_and_delete_use_strict_storage_guards(self):
        repository = (ROOT / "what/ios/WhatIOS/RecordingRepository.swift").read_text()
        tests = (ROOT /
                 "what/ios/WhatIOSTests/RecordingRepositoryTests.swift").read_text()
        self.assertIn('transcripts.backup.json', repository)
        self.assertIn('private func persistTranscripts(', repository)
        self.assertIn('func restoreTranscriptCatalogFromBackup()', repository)
        self.assertIn('let existing = try loadTranscriptsForMutation()', repository)
        self.assertIn('try persistTranscripts(cleaned)', repository)
        self.assertIn('throw RepositoryError.transcriptRestoreNotNeeded', repository)
        self.assertIn('throw RepositoryError.transcriptBackupUnavailable', repository)
        self.assertIn('try cleanupDeletedArtifacts(deleted)', repository)
        self.assertIn('testCorruptPrimaryInterruptedDeleteIsRecoveredWithoutResurrection',
                      tests)
        self.assertIn('testBackupWriteFailurePreservesValidPrimaryAndRecording', tests)

    def test_what_corrupted_transcript_store_is_fail_closed_and_localized(self):
        source = (ROOT / "what/ios/WhatIOS/RecordingRepository.swift").read_text()
        qa = (ROOT / "what/ios/WhatIOSUITests/SpanishLocalizationUITests.swift").read_text()
        self.assertIn("loadTranscriptsForMutation()", source)
        self.assertIn("transcriptStoreUnreadable", source)
        self.assertIn("testSpanishTranscriptSaveFailureKeepsDraftAndShowsExplanation", qa)
        key = "Transcript storage could not be read. Your edits were not saved."
        for code in ("en", "ru", "es"):
            translations = i18n.read_strings(
                ROOT / f"what/ios/WhatIOS/{code}.lproj/Localizable.strings", []
            )
            self.assertIn(key, translations)

    def test_what_transcript_editor_ax_controls_use_synthetic_fixture(self):
        editor = (ROOT / "what/ios/WhatIOS/TranscriptEditorSheet.swift").read_text()
        app = (ROOT / "what/ios/WhatIOS/WhatApp.swift").read_text()
        ui = (ROOT /
              "what/ios/WhatIOSUITests/SpanishLocalizationUITests.swift"
              ).read_text()
        self.assertIn(".safeAreaInset(edge: .bottom, spacing: 0)", editor)
        self.assertIn(".frame(minWidth: 88, minHeight: 52)", editor)
        self.assertIn('.accessibilityIdentifier("what.transcript.cancel")', editor)
        self.assertIn('.accessibilityIdentifier("what.transcript.save")', editor)
        self.assertIn('.accessibilityIdentifier("what.transcript.editor")', editor)
        self.assertIn("#if DEBUG", editor)
        self.assertIn("--qa-transcript-editor-synthetic", app)
        self.assertIn("--qa-transcript-editor-synthetic-normal", app)
        self.assertIn("Standalone synthetic transcript QA host", editor)
        self.assertIn("testSpanishAXXXLTranscriptActionsReachableWithoutSaving", ui)
        self.assertIn("testSpanishNormalTranscriptKeepsToolbarAndSafeCancel", ui)

    def test_what_audio_ui_accessibility_fixture_is_debug_only(self):
        audio = (ROOT / "what/ios/WhatIOS/PhoneRecordingSheet.swift").read_text()
        app = (ROOT / "what/ios/WhatIOS/WhatApp.swift").read_text()
        tests = (ROOT /
                 "what/ios/WhatIOSUITests/SpanishLocalizationUITests.swift"
                ).read_text()
        self.assertIn("#if DEBUG", audio)
        self.assertIn("--qa-audio-controls-no-microphone", app)
        self.assertIn("if !recorder.isRecording && !isLayoutQA", audio)
        self.assertIn(".frame(minWidth: 88, minHeight: 52)", audio)
        self.assertIn('.accessibilityIdentifier("what.audio.close")', audio)
        self.assertIn('.accessibilityIdentifier("what.audio.start")', audio)
        self.assertIn(".disabled(recorder.requestingPermission || isLayoutQA)",
                      audio)
        self.assertIn("testSpanishAXXXLAudioControlsWithoutMicrophoneAccess",
                      tests)
        self.assertIn("testSpanishNormalSizeAudioPreservesNavigationClose", tests)

    def test_what_video_ui_accessibility_fixture_is_debug_only(self):
        video = (ROOT / "what/ios/WhatIOS/VideoRecordingSheet.swift").read_text()
        ui = (ROOT /
              "what/ios/WhatIOSUITests/SpanishLocalizationUITests.swift").read_text()
        self.assertIn('#if DEBUG', video)
        self.assertIn('--qa-video-controls-no-camera', video)
        self.assertIn('if !isLayoutQA { recorder.start() }', video)
        self.assertIn('.frame(minWidth: 88, minHeight: 52)', video)
        self.assertIn('.accessibilityIdentifier("what.video.discard")', video)
        self.assertIn('.accessibilityIdentifier("what.video.stop")', video)
        self.assertIn('testSpanishAXXXLVideoControlsWithoutCameraAccess', ui)
        self.assertIn('XCTAssertFalse(stop.isEnabled', ui)

    def test_what_large_text_note_editor_has_accessible_done_target(self):
        source = (ROOT / "what/ios/WhatIOS/TextNoteSheet.swift").read_text()
        spanish_qa = (ROOT /
                      "what/ios/WhatIOSUITests/SpanishLocalizationUITests.swift"
                      ).read_text()
        self.assertIn(".safeAreaInset(edge: .bottom, spacing: 0)", source)
        self.assertIn(".frame(minWidth: 88, minHeight: 52)", source)
        self.assertIn("if !dynamicTypeSize.isAccessibilitySize", source)
        self.assertIn('.accessibilityIdentifier("what.text.done")', source)
        self.assertIn("testSpanishAXXXLTextEditorReadableAndDismissible",
                      spanish_qa)
        self.assertIn("testSpanishAXXXLSettingsLanguageIsDiscoverable",
                      spanish_qa)
        self.assertIn('XCTAssertGreaterThanOrEqual(done.frame.height, 44)',
                      spanish_qa)

    def test_what_diagnostics_qa_no_longer_uses_legacy_shared_language(self):
        tests = (ROOT /
                 "what/ios/WhatIOSUITests/SyncDiagnosticsLocalizationUITests.swift"
                 ).read_text()
        self.assertNotIn("testSpeechLanguageAlsoSwitchesTheLiveInterface", tests)
        self.assertIn("testSpeechLanguageDoesNotSwitchInterfaceAndPersists", tests)
        self.assertIn("testSpanishDiagnosticsAndSettingsMenu", tests)
        self.assertIn('selectLocale("Английский", app: app)', tests)
        self.assertIn("Язык интерфейса — в настройках iOS", tests)
        ipad = (ROOT /
                "what/ios/WhatIOSUITests/SpanishLocalizationUITests.swift"
                ).read_text()
        self.assertIn("testSpanishMixedNotesLibraryAXXXLAccessibleNavigation",
                      ipad)
        self.assertIn(".performAccessibilityAudit(", ipad)

    def test_what_speech_and_interface_languages_are_independent(self):
        brand = (ROOT / "what/ios/Shared/CaptureBrand.swift").read_text()
        settings = (ROOT / "what/ios/WhatIOS/RecordingLibraryView.swift").read_text()
        self.assertIn("resolvedInterfaceLanguage(for: Locale.preferredLanguages)",
                      brand)
        self.assertIn("Locale(identifier: selectedInterfaceLanguage)", brand)
        self.assertNotIn("Locale(identifier: selectedTranscriptionLocale)", brand)
        self.assertIn('"Speech recognition language"', settings)
        self.assertIn("UIApplication.openSettingsURLString", settings)
        self.assertIn('CaptureBrand.text("Сегодня", "Today")', settings)
        self.assertIn('CaptureBrand.text("Вчера", "Yesterday")', settings)
        self.assertIn('CaptureBrand.text("Ранее", "Earlier")', settings)

    def test_chickmark_french_catalog_across_phone_watch_and_widgets(self):
        bundles = [
            ("HabitsByArvectum", 311),
            ("HabitsByArvectumWatch", 22),
            ("HabitsByArvectumWidget", 16),
            ("HabitsByArvectumWatchWidget", 5),
        ]
        for name, count in bundles:
            root = ROOT / "chickmark/ios" / name
            english = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
            french = i18n.read_strings(root / "fr.lproj/Localizable.strings", [])
            self.assertEqual(set(english), set(french), name)
            self.assertEqual(len(french), count, name)
            for key in english:
                self.assertEqual(
                    i18n.placeholders(english[key]),
                    i18n.placeholders(french[key]), f"{name}/{key}"
                )
        home = ROOT / "chickmark/ios/HabitsByArvectum"
        french = i18n.read_strings(home / "fr.lproj/Localizable.strings", [])
        self.assertEqual(french["today.title"], "Aujourd’hui")
        self.assertEqual(french["habit.create"], "Créer une habitude")
        self.assertEqual(french["language.system"], "Langue du système")
        self.assertEqual(french["water.export.volume"], "Millilitres par validation : %d ml")
        self.assertEqual(french["schedule.interval.description.format"],
                         "Tous les %d j après validation")
        self.assertEqual(french["insights.weekly.ratio"], "Semaines : %d/%d")
        widget = i18n.read_strings(
            ROOT / "chickmark/ios/HabitsByArvectumWidget/fr.lproj/Localizable.strings", []
        )
        self.assertEqual(widget["widget.remaining.format"], "Encore %d")
        for name in ("HabitsByArvectum", "HabitsByArvectumWatch"):
            root = ROOT / "chickmark/ios" / name
            original = i18n.read_strings(root / "en.lproj/InfoPlist.strings", [])
            translated = i18n.read_strings(root / "fr.lproj/InfoPlist.strings", [])
            self.assertEqual(set(original), set(translated))
            self.assertEqual(len(translated), 2)

    def test_pushkin_french_catalog_covers_all_real_english_copy(self):
        root = ROOT / "pushkin/ios/ArvectumNotify/Resources"
        en = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
        fr = i18n.read_strings(root / "fr.lproj/Localizable.strings", [])
        self.assertEqual(set(en), set(fr))
        self.assertEqual(len(fr), 159)
        self.assertEqual(fr["History"], "Historique")
        self.assertEqual(fr["Apps & Setup"], "Apps et configuration")
        self.assertEqual(fr["Settings"], "Réglages")
        self.assertEqual(fr["Group %d"], "Groupe %d")
        self.assertIn("Raccourcis", fr["PUSHKIN works through Apple Shortcuts"])
        self.assertTrue(all(
            i18n.placeholders(en[k]) == i18n.placeholders(fr[k]) for k in en
        ))

    def test_pushkin_spanish_catalog_covers_all_real_english_copy(self):
        root = ROOT / "pushkin/ios/ArvectumNotify/Resources"
        en = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
        es = i18n.read_strings(root / "es.lproj/Localizable.strings", [])
        self.assertEqual(set(en), set(es))
        self.assertEqual(len(es), 159)
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
        self.assertEqual(len(es), 161)
        self.assertEqual(es["Сжать PDF до выбранного размера"], "Comprimir PDF al tamaño elegido")
        consent_key = "«Фото и PDF под размер» бесплатно и поддерживается рекламой. Реклама будет показываться независимо от вашего выбора. Вы можете разрешить или не разрешить Yandex Mobile Ads обработку данных для рекламы. Если разрешите, iOS может отдельно спросить разрешение на отслеживание. При отказе реклама останется, но без доступа к рекламному идентификатору. Фото и PDF обрабатываются только на устройстве, геолокация отключена."
        self.assertIn(consent_key, es)
        self.assertIn("Разрешить обработку данных", es)
        self.assertIn("Не разрешать обработку данных", es)
        ad_code=(ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Advertising/AdService.swift").read_text()
        self.assertIn("AdConsentStore.storedConsent ?? false", ad_code)
        self.assertIn("YandexAds.setLocationTracking(false)", ad_code)
        self.assertIn("ATTrackingManager.requestTrackingAuthorization", ad_code)
        self.assertIn("YandexAds.setUserConsent(consent)", ad_code)
        self.assertNotIn("YandexAds.setAppAdAnalyticsReportingEnabled(false)", ad_code)
        info = i18n.read_strings(path / "es.lproj/InfoPlist.strings", [])
        self.assertEqual(set(info), {"CFBundleDisplayName", "NSUserTrackingUsageDescription"})
        self.assertIn("identificador publicitario", info["NSUserTrackingUsageDescription"])

    def test_android_export_filenames_localized_for_all_shipping_languages(self):
        from xml.etree import ElementTree
        resources = ROOT / "photo-pdf-to-size/android/app/src/main/res"
        expected = {
            "values": ("compressed", "resized", "passport"),
            "values-ru": ("до-размера", "по-пикселям", "на-паспорт"),
            "values-es": ("comprimida", "redimensionada", "documento"),
            "values-pt-rBR": ("compactada", "redimensionada", "documento"),
            "values-fr": ("compressee", "redimensionnee", "identite"),
            "values-de": ("komprimiert", "skaliert", "passfoto"),
            "values-it": ("compressa", "ridimensionata", "fototessera"),
            "values-nl": ("gecomprimeerd", "verkleind", "pasfoto"),
            "values-pl": ("skompresowane", "zmienione-wymiary", "dokumenty"),
        }
        keys = ("export_filename_file_size", "export_filename_pixels",
                "export_filename_passport")
        for directory, translations in expected.items():
            with self.subTest(locale=directory):
                xml = resources / directory / "export_filenames.xml"
                actual = {
                    element.attrib["name"]: element.text
                    for element in ElementTree.parse(xml).getroot()
                }
                self.assertEqual(set(actual), set(keys))
                self.assertEqual(tuple(actual[k] for k in keys), translations)
                self.assertTrue(all(value and "/" not in value and
                                    "\\\\" not in value for value in actual.values()))

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
