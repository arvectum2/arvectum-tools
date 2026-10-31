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

    def test_photo_source_preview_captions_are_localized_in_13_languages(self):
        cases = {
            "ru": "Исходный файл", "en": "Source file", "de": "Quelldatei",
            "es": "Archivo original", "fr": "Fichier d’origine",
            "it": "File originale", "ja": "元のファイル", "ko": "원본 파일",
            "pt-BR": "Arquivo original", "pt-PT": "Ficheiro original",
            "zh-Hans": "原始文件", "zh-Hant": "原始檔案", "nl": "Bronbestand",
        }
        root = ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Resources"
        for locale, expected in cases.items():
            loc = i18n.read_strings(root / f"{locale}.lproj/Localizable.strings", [])
            self.assertEqual(loc["Исходный файл"], expected, locale)
            self.assertTrue(loc["Предпросмотр исходного файла"], locale)
            if locale != "ru":
                self.assertNotEqual(loc["Предпросмотр исходного файла"],
                                    "Предпросмотр исходного файла", locale)

    def test_photo_dutch_safety_and_permissions_are_not_english_fallback(self):
        root = ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Resources"
        en = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
        nl = i18n.read_strings(root / "nl.lproj/Localizable.strings", [])
        self.assertEqual(set(en), set(nl))
        self.assertEqual(len(nl), 161)
        for key in en:
            self.assertEqual(i18n.placeholders(en[key]), i18n.placeholders(nl[key]), key)
        self.assertEqual(nl["Сжать файл"], "Bestand comprimeren")
        self.assertEqual(nl["Обработать PDF"], "Werken met PDF")
        self.assertEqual(nl["Отказаться"], "Weigeren")
        disclaimer_key = next(k for k in nl if "страницы PDF растрируются" in k)
        self.assertIn("omgezet in afbeeldingen", nl[disclaimer_key])
        self.assertIn("niet beschikbaar", nl[disclaimer_key])
        privacy_key = next(k for k in nl if "Yandex Mobile Ads" in k and "App Tracking" in k)
        self.assertIn("toestemming", nl[privacy_key])
        self.assertNotEqual(nl[privacy_key], en[privacy_key])
        plist = i18n.read_strings(root / "nl.lproj/InfoPlist.strings", [])
        self.assertIn("advertentie-ID", plist["NSUserTrackingUsageDescription"])
        self.assertEqual(plist["CFBundleDisplayName"], "Foto en PDF verkleinen")
        ui = (ROOT / "photo-pdf-to-size/ios/PhotoPodRazmerUITests/DutchLocalizationUITests.swift").read_text()
        self.assertIn("func testDutchPhotoWorkflow", ui)
        self.assertIn("func testDutchPDFWorkflow", ui)
        self.assertIn("func testDutchLargeTextModeGridAndPrivacyConsent", ui)

    def test_pushkin_dutch_source_preserves_shortcuts_and_history_safety_copy(self):
        root = ROOT / "pushkin/ios/ArvectumNotify/Resources"
        en = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
        nl = i18n.read_strings(root / "nl.lproj/Localizable.strings", [])
        self.assertEqual(set(nl), set(en))
        self.assertEqual(len(nl), len(en))
        for key, translated in nl.items():
            self.assertEqual(i18n.placeholders(en[key]), i18n.placeholders(translated), key)
        self.assertEqual(nl["History"], "Geschiedenis")
        self.assertEqual(nl["Settings"], "Instellingen")
        self.assertEqual(nl["Apps & Setup"], "Apps en configuratie")
        self.assertEqual(nl["Group %d"], "Groep %d")
        self.assertIn("uitgeschakeld", nl["Newly imported automations are disabled. Turn each one on in Shortcuts; PUSHKIN cannot read its enabled state. A notification from one app does not verify every app."])
        self.assertIn("niet verwijderd", nl["Clearing this local checklist does not remove any automation or notification history."])
        self.assertIn("niet alle meldingen", nl["iOS does not allow PUSHKIN to read every app's notifications or turn on automations itself. You control which apps are included."])
        self.assertIn('"nl"', (ROOT / "pushkin/ios/ArvectumNotify/BrandStyle.swift").read_text())

    def test_uhvat_dutch_full_bundle_and_data_safety_translation(self):
        for bundle in ("WhatIOS", "WhatWatch", "WhatPhoneWidget", "WhatWatchComplication"):
            root = ROOT / "what/ios" / bundle
            english = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
            translated = i18n.read_strings(root / "nl.lproj/Localizable.strings", [])
            self.assertEqual(set(english), set(translated), bundle)
            for key in english:
                self.assertEqual(i18n.placeholders(english[key]),
                                 i18n.placeholders(translated[key]), (bundle, key))
            self.assertEqual(set(i18n.read_strings(root / "en.lproj/InfoPlist.strings", [])),
                             set(i18n.read_strings(root / "nl.lproj/InfoPlist.strings", [])), bundle)
        nl = i18n.read_strings(ROOT / "what/ios/WhatIOS/nl.lproj/Localizable.strings", [])
        self.assertEqual(nl["Catch that thought"], "Leg die gedachte vast")
        self.assertEqual(nl["New text note"], "Nieuwe tekstnotitie")
        self.assertIn("blijft bewaard", nl["A new transcription will replace your current text, including any manual corrections. The original audio will be kept."])
        self.assertIn("blijft", nl["Your Watch last reported recordings waiting for iPhone confirmation. Audio stays on Watch until iPhone confirms saving; background delivery can be delayed."])
        self.assertIn("500 MB", nl["Audio exceeds 500 MB. Your original is safe."])
        self.assertIn("maximaal 10", nl["Select up to 10 audio files at a time."])
        self.assertEqual(nl["%d indexed"], "%d geïndexeerd")
        self.assertIn('"nl"', (ROOT / "what/ios/Shared/CaptureBrand.swift").read_text())

    def test_chickmark_dutch_all_bundles_and_sensitive_permissions(self):
        root = ROOT / "chickmark/ios"
        for bundle, expected_size in (
            ("HabitsByArvectum", 315),
            ("HabitsByArvectumWatch", 22),
            ("HabitsByArvectumWidget", 16),
            ("HabitsByArvectumWatchWidget", 5),
        ):
            original = i18n.read_strings(root / bundle / "en.lproj/Localizable.strings", [])
            translated = i18n.read_strings(root / bundle / "nl.lproj/Localizable.strings", [])
            self.assertEqual(len(translated), expected_size)
            self.assertEqual(set(translated), set(original), bundle)
            for key in original:
                self.assertEqual(i18n.placeholders(translated[key]),
                                 i18n.placeholders(original[key]), (bundle, key))
        ios = i18n.read_strings(root / "HabitsByArvectum/nl.lproj/Localizable.strings", [])
        self.assertEqual(ios["habit.create"], "Gewoonte aanmaken")
        self.assertIn("niet naar CloudKit", ios["health.privacy"])
        self.assertIn("verwijderd", ios["backup.warning"])
        self.assertIn("niet geïmporteerd", ios["water.export.explanation"])
        self.assertIn("toe te staan", ios["review.paste.instructions"])
        self.assertIn("transcriptie niet", ios["review.privacy.explanation"])
        self.assertIn("niet als gemiste", ios["weekly.gapNote"])
        for bundle in ("HabitsByArvectum", "HabitsByArvectumWatch"):
            path = root / bundle
            source_plist = i18n.read_strings(path / "en.lproj/InfoPlist.strings", [])
            translated_plist = i18n.read_strings(path / "nl.lproj/InfoPlist.strings", [])
            self.assertEqual(set(source_plist), set(translated_plist))
            self.assertIn("Gezondheid", translated_plist["NSHealthShareUsageDescription"])
            self.assertIn("Gezondheid", translated_plist["NSHealthUpdateUsageDescription"])
        self.assertIn("DutchLocalizationUITests", (root / "HabitsByArvectumUITests/DutchLocalizationUITests.swift").read_text())

    def test_indonesian_photo_permissions_and_pdf_disclaimer_are_real_source_strings(self):
        root = ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Resources"
        en = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
        translated = i18n.read_strings(root / "id.lproj/Localizable.strings", [])
        self.assertEqual(set(translated), set(en))
        self.assertEqual(len(translated), 161)
        for key in en:
            self.assertEqual(i18n.placeholders(translated[key]), i18n.placeholders(en[key]), key)
        self.assertEqual(translated["Сжать файл"], "Kompres berkas")
        self.assertEqual(translated["Обработать PDF"], "Olah PDF")
        self.assertEqual(translated["Отказаться"], "Tolak")
        disclaimer = next(key for key in en if 'страницы PDF растрируются' in key)
        self.assertIn("diubah menjadi gambar", translated[disclaimer])
        self.assertIn("mungkin tidak tersedia", translated[disclaimer])
        consent = next(key for key in en if 'Yandex Mobile Ads' in key and 'App Tracking' in key)
        self.assertIn('izin pelacakan', translated[consent])
        long_consent = next(key for key, english in en.items() if 'Ads are shown regardless' in english)
        self.assertIn('tetap muncul', translated[long_consent])
        plist = i18n.read_strings(root / "id.lproj/InfoPlist.strings", [])
        self.assertIn('pengenal iklan', plist['NSUserTrackingUsageDescription'])
        self.assertEqual(plist['CFBundleDisplayName'], 'Ubah Ukuran Foto & PDF')
        ui = (ROOT / 'photo-pdf-to-size/ios/PhotoPodRazmerUITests/IndonesianLocalizationUITests.swift').read_text()
        for name in ('testIndonesianPhotoWorkflow', 'testIndonesianPDFWorkflow',
                     'testIndonesianLargeTextModeGridAndPrivacyConsent'):
            self.assertIn('func '+name, ui)

    def test_indonesian_pushkin_full_keys_and_shortcuts_safety_text(self):
        root = ROOT / 'pushkin/ios/ArvectumNotify/Resources'
        en = i18n.read_strings(root / 'en.lproj/Localizable.strings', [])
        translated = i18n.read_strings(root / 'id.lproj/Localizable.strings', [])
        self.assertEqual(len(translated), len(en))
        self.assertEqual(set(translated), set(en))
        for key in en:
            self.assertEqual(i18n.placeholders(en[key]),
                             i18n.placeholders(translated[key]), key)
        self.assertEqual(translated['History'], 'Riwayat')
        self.assertEqual(translated['Settings'], 'Pengaturan')
        self.assertEqual(translated['Group %d'], 'Grup %d')
        warning = translated['Newly imported automations are disabled. Turn each one on in Shortcuts; PUSHKIN cannot read its enabled state. A notification from one app does not verify every app.']
        self.assertIn('nonaktif', warning)
        self.assertIn('tidak dapat membaca', warning)
        copy = translated['Clearing this local checklist does not remove any automation or notification history.']
        self.assertIn('tidak menghapus otomatisasi', copy)
        privacy = translated["iOS does not allow PUSHKIN to read every app's notifications or turn on automations itself. You control which apps are included."]
        self.assertIn('tidak mengizinkan', privacy)
        self.assertIn('Anda menentukan', privacy)
        self.assertIn('"id"', (ROOT / 'pushkin/ios/ArvectumNotify/BrandStyle.swift').read_text())
        ui = (ROOT / 'pushkin/ios/ArvectumNotifyUITests/IndonesianLocalizationUITests.swift').read_text()
        self.assertIn('func testIndonesianTabsAndNavigation', ui)

    def test_uhvat_indonesian_four_bundles_and_durable_media_copy(self):
        for bundle in ('WhatIOS','WhatWatch','WhatPhoneWidget','WhatWatchComplication'):
            root = ROOT / 'what/ios' / bundle
            en = i18n.read_strings(root / 'en.lproj/Localizable.strings', [])
            idn = i18n.read_strings(root / 'id.lproj/Localizable.strings', [])
            self.assertEqual(set(en), set(idn), bundle)
            for key in en:
                self.assertEqual(i18n.placeholders(en[key]),
                                 i18n.placeholders(idn[key]), (bundle, key))
            self.assertEqual(set(i18n.read_strings(root/'en.lproj/InfoPlist.strings', [])),
                             set(i18n.read_strings(root/'id.lproj/InfoPlist.strings', [])), bundle)
        source = i18n.read_strings(ROOT/'what/ios/WhatIOS/id.lproj/Localizable.strings', [])
        self.assertEqual(len(source), 247)
        self.assertEqual(source['Catch that thought'], 'Tangkap ide itu')
        self.assertEqual(source['New text note'], 'Catatan teks baru')
        self.assertIn('Audio asli tetap disimpan', source['A new transcription will replace your current text, including any manual corrections. The original audio will be kept.'])
        self.assertIn('hingga iPhone mengonfirmasi', source['Your Watch last reported recordings waiting for iPhone confirmation. Audio stays on Watch until iPhone confirms saving; background delivery can be delayed.'])
        self.assertIn('500 MB', source['Audio exceeds 500 MB. Your original is safe.'])
        self.assertIn('maksimal 10', source['Select up to 10 audio files at a time.'])
        self.assertEqual(source['%d indexed'], '%d diindeks')
        self.assertIn('"id"', (ROOT/'what/ios/Shared/CaptureBrand.swift').read_text())
        ui = (ROOT/'what/ios/WhatIOSUITests/IndonesianLocalizationUITests.swift').read_text()
        self.assertIn('func testIndonesianAXXXLHomeControlsWithoutRecording', ui)

    def test_chickmark_indonesian_all_bundles_and_sensitive_permission_copy(self):
        root = ROOT / 'chickmark/ios'
        for bundle, count in (('HabitsByArvectum',315),('HabitsByArvectumWatch',22),
                             ('HabitsByArvectumWidget',16),('HabitsByArvectumWatchWidget',5)):
            en = i18n.read_strings(root/bundle/'en.lproj/Localizable.strings', [])
            idn = i18n.read_strings(root/bundle/'id.lproj/Localizable.strings', [])
            self.assertEqual(len(idn), count)
            self.assertEqual(set(idn), set(en))
            for key in en:
                self.assertEqual(i18n.placeholders(en[key]), i18n.placeholders(idn[key]), (bundle,key))
        idn = i18n.read_strings(root/'HabitsByArvectum/id.lproj/Localizable.strings', [])
        self.assertEqual(idn['habit.create'], 'Buat kebiasaan')
        self.assertIn('tidak ada pengukuran kesehatan', idn['health.privacy'].lower())
        self.assertIn('menghapus catatan', idn['backup.warning'])
        self.assertIn('tidak diimpor', idn['water.export.explanation'])
        self.assertIn('Ketuk tombol Tempel sistem', idn['review.paste.instructions'])
        self.assertIn('Notifikasi tidak menampilkan transkrip', idn['review.privacy.explanation'])
        self.assertIn('tidak membuat hari terlewat', idn['weekly.gapNote'])
        for bundle in ('HabitsByArvectum','HabitsByArvectumWatch'):
            en = i18n.read_strings(root/bundle/'en.lproj/InfoPlist.strings', [])
            idp = i18n.read_strings(root/bundle/'id.lproj/InfoPlist.strings', [])
            self.assertEqual(set(en), set(idp))
            self.assertIn('Apple Health', idp['NSHealthShareUsageDescription'])
            self.assertIn('Apple Health', idp['NSHealthUpdateUsageDescription'])
        ui = (root/'HabitsByArvectumUITests/IndonesianLocalizationUITests.swift').read_text()
        self.assertIn('func testIndonesianEmptyStateAndNewHabitForm', ui)

    def test_photo_turkish_full_catalog_and_privacy_copy(self):
        root = ROOT / 'photo-pdf-to-size/ios/PhotoPodRazmer/Resources'
        en = i18n.read_strings(root/'en.lproj/Localizable.strings', [])
        tr = i18n.read_strings(root/'tr.lproj/Localizable.strings', [])
        self.assertEqual(len(tr), 161)
        self.assertEqual(set(tr), set(en))
        for key in en:
            self.assertEqual(i18n.placeholders(en[key]), i18n.placeholders(tr[key]), key)
        self.assertIn('görsele dönüştürülür', tr[next(k for k in tr if 'PDF pages are rasterized' in en[k])])
        self.assertIn('Yandex Mobile Ads', tr[next(k for k in tr if 'Photos and PDFs are processed only on your device' in en[k])])
        self.assertIn('iOS ayrıca izleme izni', tr[next(k for k in tr if 'ads are shown regardless of your choice' in en[k].lower())])
        plist = i18n.read_strings(root/'tr.lproj/InfoPlist.strings', [])
        self.assertEqual(set(plist), set(i18n.read_strings(root/'en.lproj/InfoPlist.strings', [])))
        self.assertIn('reklam tanımlayıcısı', plist['NSUserTrackingUsageDescription'])
        ui = (ROOT/'photo-pdf-to-size/ios/PhotoPodRazmerUITests/TurkishLocalizationUITests.swift').read_text()
        self.assertIn('func testTurkishPhotoWorkflow', ui)
        self.assertIn('func testTurkishPDFWorkflow', ui)
        self.assertIn('func testTurkishLargeTextModeGridAndPrivacyConsent', ui)

    def test_pushkin_turkish_shortcuts_terminology_and_safety(self):
        root = ROOT / 'pushkin/ios/ArvectumNotify/Resources'
        en = i18n.read_strings(root/'en.lproj/Localizable.strings', [])
        tr = i18n.read_strings(root/'tr.lproj/Localizable.strings', [])
        self.assertEqual(len(tr), len(en))
        self.assertEqual(set(en), set(tr))
        for k in en:
            self.assertEqual(i18n.placeholders(en[k]), i18n.placeholders(tr[k]), k)
        self.assertEqual(tr['History'], 'Geçmiş')
        self.assertEqual(tr['Settings'], 'Ayarlar')
        self.assertIn('kapalıdır', tr[next(k for k in tr if 'Newly imported automations' in en[k])])
        self.assertIn('kendi', tr[next(k for k in tr if 'iOS does not allow PUSHKIN' in en[k])])
        self.assertIn('silmez', tr[next(k for k in tr if 'Clearing this local checklist' in en[k])])
        self.assertIn('Kestirmeler', tr[next(k for k in tr if 'Only Shortcuts knows whether' in en[k])])
        self.assertIn('kopyalamak', tr[next(k for k in tr if 'Your group plan is stored locally' in en[k])])
        ui = (ROOT/'pushkin/ios/ArvectumNotifyUITests/TurkishLocalizationUITests.swift').read_text()
        self.assertIn('func testTurkishTabsAndNavigation', ui)

    def test_uhvat_turkish_all_four_bundles_and_original_media_safety(self):
        for bundle in ('WhatIOS','WhatWatch','WhatPhoneWidget','WhatWatchComplication'):
            root=ROOT/'what/ios'/bundle
            en=i18n.read_strings(root/'en.lproj/Localizable.strings', [])
            tr=i18n.read_strings(root/'tr.lproj/Localizable.strings', [])
            self.assertEqual(set(en),set(tr),bundle)
            for k in en:
                self.assertEqual(i18n.placeholders(en[k]),i18n.placeholders(tr[k]),(bundle,k))
            self.assertEqual(set(i18n.read_strings(root/'en.lproj/InfoPlist.strings', [])),
                             set(i18n.read_strings(root/'tr.lproj/InfoPlist.strings', [])),bundle)
        en=i18n.read_strings(ROOT/'what/ios/WhatIOS/en.lproj/Localizable.strings', [])
        tr=i18n.read_strings(ROOT/'what/ios/WhatIOS/tr.lproj/Localizable.strings', [])
        self.assertEqual(len(tr),247)
        self.assertEqual(tr['Catch that thought'],'Düşünceyi yakalayın')
        self.assertEqual(tr['New text note'],'Yeni metin notu')
        for phrase,required in (
            ('A new transcription will replace your current text','Orijinal ses kaydı korunur'),
            ('Your Watch last reported recordings waiting for iPhone confirmation','onaylayana kadar ses Watch'),
            ('The final video segment has not finished writing','Orijinal dosyalar'),
            ('The full note temporarily replaces','en fazla beş dakikalığına'),
            ('The last valid backup will be used','Silinen notlar geri yüklenmez'),
            ('Audio exceeds 500 MB','500 MB'),
            ('Select up to 10 audio files','en fazla 10')):
            key=next(k for k in en if phrase in en[k]);self.assertIn(required,tr[key])
        self.assertIn('"tr"',(ROOT/'what/ios/Shared/CaptureBrand.swift').read_text())
        ui=(ROOT/'what/ios/WhatIOSUITests/TurkishLocalizationUITests.swift').read_text()
        self.assertIn('func testTurkishAXXXLHomeControlsWithoutRecording',ui)

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
        self.assertEqual(result['english_identical_triaged'], 52)
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
        expected = [
            "en", "ru", "es", "fr", "de", "pt-BR", "pt-PT", "it",
            "ja", "ko", "zh-Hans", "zh-Hant", "nl", "id", "tr", "pl",
        ]
        self.assertEqual(len(expected), 16)
        for app in ("photo-pdf-to-size", "pushkin", "what", "chickmark"):
            app_expected = expected + (["vi"] if app == "photo-pdf-to-size" else [])
            self.assertEqual(reg["apps"][app]["ios"]["sourceCatalogs"], app_expected)

        self.assertEqual([sum(x["tier"] == t for x in reg["targets"]) for t in (1, 2, 3)], [20, 20, 10])

    def test_all_active_ios_source_locales_have_ui_smoke_coverage(self):
        """Maintain iPhone UI smoke for the evolving source locale matrix.

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
            "ja": "Japanese", "ko": "Korean", "nl": "Dutch", "id": "Indonesian", "tr": "Turkish", "pl": "Polish", "vi": "Vietnamese", "zh-Hans": "SimplifiedChinese", "zh-Hant": "TraditionalChinese",
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
            expected = {"ru", "en", *code_names} - ({"vi"} if app != "photo" else set())
            self.assertEqual(
                locales, expected,
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
                if locale not in locales:
                    continue
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
        self.assertEqual(covered, 65)

    def test_all_active_ios_bundles_have_registry_localized_catalogs(self):
        """Each app's own source locale packs are present in all its active bundles.

        This tests source parity, not linguistic quality or App Store release.
        """
        registry = i18n.config()
        for app in ("chickmark", "pushkin", "what", "photo-pdf-to-size"):
            for name in registry["apps"][app]["bundles"]:
                bundle = ROOT / name
                baseline = i18n.read_strings(
                    bundle / "en.lproj/Localizable.strings", [])
                self.assertTrue(baseline, f"{app}/{name} missing English")
                for code in registry["apps"][app]["ios"]["sourceCatalogs"]:
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
        keys = [247, 6, 6, 5]
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
            ("HabitsByArvectum", 315),
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
        self.assertEqual(len(fr), len(en))
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
        self.assertEqual(len(es), len(en))
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


class EditorialLocalizationRegressionTests(unittest.TestCase):
    """Protect source copy fixed in the 2026-10-29 editorial pass."""

    @staticmethod
    def loc(path):
        return i18n.read_strings(ROOT / path, [])

    def test_korean_transcript_and_backup_semantics(self):
        what = self.loc("what/ios/WhatIOS/ko.lproj/Localizable.strings")
        chick = self.loc("chickmark/ios/HabitsByArvectum/ko.lproj/Localizable.strings")
        watch = self.loc("chickmark/ios/HabitsByArvectumWatch/ko.lproj/Localizable.strings")
        widget = self.loc("chickmark/ios/HabitsByArvectumWidget/ko.lproj/Localizable.strings")
        self.assertEqual(what["Saved transcript"], "저장된 녹취록")
        self.assertEqual(what["Folder"], "폴더")
        self.assertEqual(what["Save"], "저장")
        self.assertIn("UhWhat?", what["UhWhat?: review a note"])
        self.assertEqual(chick["backup.menu"], "백업")
        self.assertEqual(chick["backup.result"], "백업")
        self.assertIn("아직 녹취록이 없습니다", chick["review.attachment.noText"])
        self.assertEqual(watch["watch.completed"], "완료")
        self.assertEqual(watch["watch.health.unit.steps"], "걸음")
        self.assertEqual(widget["widget.action.complete.format"], "%@ 완료")
        for translation in (*what.values(), *chick.values(), *watch.values(), *widget.values()):
            self.assertNotIn("성적표", translation)
            self.assertNotIn("어뭐", translation)

    def test_french_phone_widget_keeps_uhwhat_brand(self):
        widget = self.loc("what/ios/WhatPhoneWidget/fr.lproj/Localizable.strings")
        for translation in widget.values():
            self.assertNotIn("euh quoi", translation.lower())
            if "UhWhat" in translation:
                self.assertIn("UhWhat?", translation)


    def test_camera_rear_label_is_not_navigation_back(self):
        labels = {
            "ru": "Основная", "es": "Trasera", "fr": "Caméra arrière",
            "de": "Rückkamera", "pt-BR": "Traseira", "pt-PT": "Traseira",
            "it": "Posteriore", "ja": "背面", "ko": "후면",
            "zh-Hans": "后置", "zh-Hant": "後置", "nl": "Achtercamera",
            "id": "Kamera belakang", "tr": "Arka kamera",
        }
        for locale, expected in labels.items():
            with self.subTest(locale=locale):
                strings = self.loc(
                    f"what/ios/WhatIOS/{locale}.lproj/Localizable.strings"
                )
                self.assertEqual(strings["Back"], expected)

    def test_french_and_portuguese_archival_and_review_actions(self):
        fr = self.loc("what/ios/WhatIOS/fr.lproj/Localizable.strings")
        pt = self.loc("what/ios/WhatIOS/pt-PT.lproj/Localizable.strings")
        self.assertEqual(fr["Mark reviewed"], "Marquer comme consultée")
        self.assertEqual(fr["Original note"], "Note d’origine")
        self.assertEqual(fr["Search transcripts and dates"],
                         "Rechercher dans les transcriptions et les dates")
        self.assertEqual(pt["Archive"], "Notas arquivadas")
        self.assertEqual(pt["Archive is empty"], "Ainda não há notas arquivadas")
        self.assertEqual(pt["Saved transcript"], "Transcrição guardada")


    def test_auto_followup_menu_captions_are_short_and_consistent(self):
        key = "Automatically remind about new notes"
        expected = {
            "ru": "Автонапоминания",
            "en": "Automatic reminders",
            "fr": "Rappels automatiques",
            "pt-PT": "Lembretes automáticos",
            "pt-BR": "Lembretes automáticos",
        }
        for locale in (
            "ru", "en", "es", "fr", "de", "pt-BR", "pt-PT", "it",
            "ja", "ko", "zh-Hans", "zh-Hant", "nl", "id", "tr"
        ):
            with self.subTest(locale=locale):
                strings = self.loc(
                    f"what/ios/WhatIOS/{locale}.lproj/Localizable.strings"
                )
                caption = strings[key]
                self.assertLessEqual(len(caption), 30,
                                     "Native iOS menus truncate long captions")
                self.assertEqual(caption.strip(), caption)
                if locale in expected:
                    self.assertEqual(caption, expected[locale])
        source = (ROOT / "what/ios/WhatIOS/RecordingLibraryView.swift").read_text()
        self.assertIn(
            'CaptureBrand.text("Автонапоминания",',
            source
        )


    def test_european_portuguese_pushkin_settings_terminology(self):
        labels = self.loc(
            "pushkin/ios/ArvectumNotify/Resources/pt-PT.lproj/Localizable.strings"
        )
        self.assertEqual(labels["Settings"], "Definições")
        self.assertEqual(labels["Developer"], "Programador")
        self.assertEqual(
            labels["Support and missing-app requests"],
            "Apoio e pedidos de aplicações em falta"
        )
        self.assertIn(
            "aplicações associadas",
            labels["Review notifications captured from apps you connected."]
        )


    def test_archive_folder_and_action_have_distinct_semantics(self):
        expected = {
            "ru": ("Архив", "В архив"),
            "en": ("Archive", "Archive"),
            "fr": ("Archive", "Archiver"),
            "pt-PT": ("Notas arquivadas", "Arquivar"),
            "ko": ("보관소", "보관"),
        }
        for locale in (
            "ru", "en", "es", "fr", "de", "pt-BR", "pt-PT", "it",
            "ja", "ko", "zh-Hans", "zh-Hant", "nl", "id", "tr"
        ):
            with self.subTest(locale=locale):
                strings = self.loc(
                    f"what/ios/WhatIOS/{locale}.lproj/Localizable.strings"
                )
                self.assertIn("Archive", strings)
                self.assertIn("Archive action", strings)
                self.assertLessEqual(len(strings["Archive action"]), 15)
                if locale in expected:
                    self.assertEqual(
                        (strings["Archive"], strings["Archive action"]),
                        expected[locale]
                    )
        source = (ROOT / "what/ios/WhatIOS/RecordingLibraryView.swift").read_text()
        self.assertIn('CaptureBrand.text("В архив", "Archive action")', source)
        self.assertIn('CaptureBrand.text("Архив", "Archive")', source)


    def test_notification_counts_name_notifications_in_each_language(self):
        translations = {
            "es": "Notificaciones guardadas",
            "fr": "Notifications enregistrées",
            "de": "Gespeicherte Benachrichtigungen",
            "pt-BR": "Notificações salvas",
            "pt-PT": "Notificações guardadas",
            "it": "Notifiche salvate",
            "ja": "保存した通知",
            "ko": "저장된 알림",
            "zh-Hans": "已保存的通知",
            "zh-Hant": "已儲存的通知",
            "id": "Notifikasi tersimpan",
        }
        for lang, expected in translations.items():
            with self.subTest(lang=lang):
                values = self.loc(
                    f"pushkin/ios/ArvectumNotify/Resources/{lang}.lproj/Localizable.strings"
                )
                self.assertEqual(values["Captured records"], expected)

    def test_accessibility_transcription_label_is_not_progress_status(self):
        names = {
            "de": "Transkript der Aufnahme",
            "pt-BR": "Transcrição da gravação",
            "pt-PT": "Transcrição da gravação",
            "ja": "録音の文字起こし",
            "ko": "녹음 내용 텍스트",
            "zh-Hans": "录音转写文本",
            "zh-Hant": "錄音轉寫文字",
            "nl": "Transcriptie van opname",
        }
        for lang, expected in names.items():
            with self.subTest(lang=lang):
                values = self.loc(
                    f"what/ios/WhatIOS/{lang}.lproj/Localizable.strings"
                )
                self.assertEqual(values["Recording transcription"], expected)

    def test_european_portuguese_editorial_grammar_across_four_apps(self):
        photo = self.loc(
            "photo-pdf-to-size/ios/PhotoPodRazmer/Resources/"
            "pt-PT.lproj/Localizable.strings"
        )
        push = self.loc(
            "pushkin/ios/ArvectumNotify/Resources/"
            "pt-PT.lproj/Localizable.strings"
        )
        what = self.loc("what/ios/WhatIOS/pt-PT.lproj/Localizable.strings")
        chick = self.loc("chickmark/ios/HabitsByArvectum/"
                         "pt-PT.lproj/Localizable.strings")
        self.assertEqual(photo["Файлы"], "Ficheiros")
        self.assertIn("aplicação Ficheiros",
                      photo["PDF-файл из приложения «Файлы»"])
        self.assertEqual(push["Captured records"], "Notificações guardadas")
        self.assertEqual(push["Developer"], "Programador")
        self.assertEqual(push["Settings"], "Definições")
        self.assertEqual(what["Recording transcription"], "Transcrição da gravação")
        self.assertEqual(what["Reviewed"], "Revisto")
        self.assertIn("nenhuma cópia de segurança utilizável",
                      what["No usable backup was found. Your data was not changed."])
        self.assertTrue(what[
            "The last valid backup will be used. Recent text edits may be missing. Deleted notes will not be restored."
        ].startswith("Será utilizada a última cópia de segurança"))
        self.assertEqual(chick["habit.skip.today"], "Ignorar hoje")
        self.assertEqual(chick["habit.skip.undo"], "Anular dia ignorado")
        self.assertEqual(chick["notification.openSettings"], "Definições")
        self.assertEqual(chick["backup.menu"], "Cópia de segurança")

    def test_french_and_dutch_editorial_context(self):
        push_fr = self.loc(
            "pushkin/ios/ArvectumNotify/Resources/fr.lproj/Localizable.strings"
        )
        chick_fr = self.loc(
            "chickmark/ios/HabitsByArvectum/fr.lproj/Localizable.strings"
        )
        what_nl = self.loc("what/ios/WhatIOS/nl.lproj/Localizable.strings")
        self.assertEqual(push_fr["Received"], "Reçues")
        self.assertEqual(chick_fr["habit.completed.toast"], "Habitude validée !")
        self.assertEqual(what_nl["Back"], "Achtercamera")
        self.assertEqual(what_nl["Front"], "Frontcamera")


    def test_korean_chickmark_actions_weekdays_and_uhwhat_brand(self):
        values = self.loc(
            "chickmark/ios/HabitsByArvectum/ko.lproj/Localizable.strings"
        )
        required = {
            "common.save": "저장",
            "common.undo": "실행 취소",
            "common.ok": "확인",
            "weekday.tue.short": "화",
            "weekday.wed.short": "수",
            "weekday.sat.short": "토",
            "weekday.sun.short": "일",
            "detail.resume": "습관 재개",
            "detail.pause": "습관 일시 중지",
            "stats.streak": "연속 기록",
            "stats.completion": "완료",
            "status.completed": "완료",
            "habit.edit.action": "편집",
            "oneoff.edit": "편집",
            "review.source.title": "UhWhat?에서 온 메모",
            "review.source.section": "UhWhat?에서 가져옴",
            "review.oneoff.open": "UhWhat?에서 가져온 메모 열기",
            "review.import.alert": "UhWhat?에서 가져오기",
            "water.export.error": "물 섭취량 내보내기 불가",
        }
        for key, value in required.items():
            with self.subTest(key=key):
                self.assertEqual(values[key], value)

    def test_dutch_chickmark_weekdays_and_korean_video_copy(self):
        nl = self.loc(
            "chickmark/ios/HabitsByArvectum/nl.lproj/Localizable.strings"
        )
        self.assertEqual(nl["weekday.mon.short"], "ma")
        self.assertEqual(nl["weekday.tue.short"], "di")
        self.assertEqual(nl["weekday.wed.short"], "wo")
        ko = self.loc("what/ios/WhatIOS/ko.lproj/Localizable.strings")
        self.assertEqual(ko["OK"], "확인")
        self.assertEqual(ko["Video note"], "동영상 메모")
        self.assertEqual(ko["Video capture"], "동영상 녹화")
        self.assertEqual(ko["Privacy policy"], "개인정보 처리방침")
        self.assertIn("녹취록", ko[
            "The audio and transcript will be deleted from this iPhone. This cannot be undone."
        ])

    def test_traditional_chinese_privacy_sentence_uses_traditional_script(self):
        zh = self.loc(
            "pushkin/ios/ArvectumNotify/Resources/"
            "zh-Hant.lproj/Localizable.strings"
        )
        text = zh[
            "Everything stays on this iPhone. No account, cloud sync, ads or analytics in version 1.0."
        ]
        self.assertIn("雲端同步", text)
        self.assertIn("帳戶", text)
        self.assertNotIn("云同步", text)


    def test_chickmark_weekday_short_names_all_supported_locales(self):
        columns = (
            "weekday.mon.short", "weekday.tue.short", "weekday.wed.short",
            "weekday.thu.short", "weekday.fri.short", "weekday.sat.short",
            "weekday.sun.short",
        )
        expected = {
            "ru": ("Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"),
            "es": ("Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"),
            "fr": ("Lun.", "Mar.", "Mer.", "Jeu.", "Ven.", "Sam.", "Dim."),
            "de": ("Mo.", "Di.", "Mi.", "Do.", "Fr.", "Sa.", "So."),
            "pt-BR": ("Seg.", "Ter.", "Qua.", "Qui.", "Sex.", "Sáb.", "Dom."),
            "pt-PT": ("Seg.", "Ter.", "Qua.", "Qui.", "Sex.", "Sáb.", "Dom."),
            "it": ("Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"),
            "ja": ("月", "火", "水", "木", "金", "土", "日"),
            "ko": ("월", "화", "수", "목", "금", "토", "일"),
            "zh-Hans": ("周一", "周二", "周三", "周四", "周五", "周六", "周日"),
            "zh-Hant": ("週一", "週二", "週三", "週四", "週五", "週六", "週日"),
            "nl": ("ma", "di", "wo", "do", "vr", "za", "zo"),
            "id": ("Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"),
        }
        for locale, names in expected.items():
            with self.subTest(locale=locale):
                strings = self.loc(
                    f"chickmark/ios/HabitsByArvectum/{locale}.lproj/Localizable.strings"
                )
                self.assertEqual(tuple(strings[k] for k in columns), names)

    def test_turkish_resizing_and_portuguese_shortcuts_terms(self):
        tr = self.loc(
            "photo-pdf-to-size/ios/PhotoPodRazmer/Resources/"
            "tr.lproj/Localizable.strings"
        )
        self.assertEqual(tr["filename.file_size"], "yeniden boyutlandırılmış")
        pt = self.loc("chickmark/ios/HabitsByArvectum/"
                      "pt-PT.lproj/Localizable.strings")
        self.assertIn("fechar a app Livros",
                      pt["health.shortcuts.instructions"])
        self.assertIn("o seu hábito", pt["health.shortcuts.instructions"])


    def test_italian_and_german_system_copy_is_natural(self):
        photo = self.loc(
            "photo-pdf-to-size/ios/PhotoPodRazmer/Resources/"
            "it.lproj/Localizable.strings"
        )
        self.assertEqual(photo["Печатать без масштабирования"], "Stampa al 100%")
        self.assertEqual(photo["Обработать PDF"], "Gestisci PDF")
        de = self.loc(
            "pushkin/ios/ArvectumNotify/Resources/"
            "de.lproj/Localizable.strings"
        )
        self.assertEqual(de["You searched for"], "Ihre Suche nach")
        self.assertTrue(de["Try another app, date range or search."].startswith(
            "Versuchen Sie"
        ))


    def test_chinese_quick_capture_covers_audio_video_and_text(self):
        expected = {
            "zh-Hans": ("快速记录", "发送至 ChickMark"),
            "zh-Hant": ("快速記錄", "傳送至 ChickMark"),
        }
        for locale, captions in expected.items():
            values = self.loc(
                f"what/ios/WhatIOS/{locale}.lproj/Localizable.strings"
            )
            self.assertEqual(values["QUICK CAPTURE"], captions[0])
            self.assertEqual(values["To ChickMark"], captions[1])

    def test_traditional_chinese_does_not_garbled_health_completion(self):
        values = self.loc(
            "chickmark/ios/HabitsByArvectum/zh-Hant.lproj/Localizable.strings"
        )
        self.assertIn("當天累計數值", values["health.description"])
        self.assertNotIn("噹噹", values["health.description"])
        push = self.loc(
            "pushkin/ios/ArvectumNotify/Resources/zh-Hant.lproj/Localizable.strings"
        )
        self.assertIn("雲端同步", push[
            "No account, cloud sync, ads or analytics. PUSHKIN stores your notification content on this iPhone only."
        ])
        self.assertNotIn("賬戶", push[
            "No account, cloud sync, ads or analytics. PUSHKIN stores your notification content on this iPhone only."
        ])

    def test_indonesian_skip_and_shortcut_undo_are_not_delete_habit(self):
        values = self.loc(
            "chickmark/ios/HabitsByArvectum/id.lproj/Localizable.strings"
        )
        self.assertEqual(values["habit.skip.undo"], "Batalkan hari yang dilewati")
        self.assertEqual(values["shortcut.undo.title"],
                         "Batalkan Penyelesaian Kebiasaan")


    def test_korean_watch_transfer_count_and_watchface_widget_caption(self):
        watch = self.loc(
            "what/ios/WhatWatch/ko.lproj/Localizable.strings"
        )
        self.assertEqual(watch["%d waiting for iPhone"],
                         "iPhone 전송 대기 중: %d개")
        widget = self.loc(
            "chickmark/ios/HabitsByArvectumWatchWidget/"
            "ko.lproj/Localizable.strings"
        )
        self.assertEqual(widget["watch.widget.description"],
                         "시계 화면에서 오늘의 습관 진행 상황을 확인하세요.")


    def test_dutch_android_resize_action_means_dimensions_not_file_format(self):
        import xml.etree.ElementTree as ET
        values = {
            node.attrib["name"]: node.text
            for node in ET.parse(
                ROOT / "photo-pdf-to-size/android/app/src/main/res/"
                "values-nl/strings.xml"
            ).getroot()
            if node.tag == "string"
        }
        self.assertEqual(values["resize_photo"], "Fotoafmetingen wijzigen")



    def test_chickmark_turkish_source_full_iphone_watch_widgets(self):
        root = ROOT / "chickmark/ios"
        for bundle, expected in (
            ("HabitsByArvectum", 315),
            ("HabitsByArvectumWatch", 22),
            ("HabitsByArvectumWidget", 16),
            ("HabitsByArvectumWatchWidget", 5),
        ):
            with self.subTest(bundle=bundle):
                en = i18n.read_strings(root / bundle / "en.lproj/Localizable.strings", [])
                tr = i18n.read_strings(root / bundle / "tr.lproj/Localizable.strings", [])
                self.assertEqual(len(en), expected)
                self.assertEqual(set(en), set(tr))
                for key in en:
                    self.assertEqual(i18n.placeholders(en[key]), i18n.placeholders(tr[key]), key)
        for bundle in ("HabitsByArvectum", "HabitsByArvectumWatch"):
            en = i18n.read_strings(root / bundle / "en.lproj/InfoPlist.strings", [])
            tr = i18n.read_strings(root / bundle / "tr.lproj/InfoPlist.strings", [])
            self.assertEqual(set(en), set(tr))
        en = i18n.read_strings(root / "HabitsByArvectum/en.lproj/AppShortcuts.strings", [])
        tr = i18n.read_strings(root / "HabitsByArvectum/tr.lproj/AppShortcuts.strings", [])
        self.assertEqual(set(en), set(tr))
        ui_tr = i18n.read_strings(root / "HabitsByArvectum/tr.lproj/Localizable.strings", [])
        self.assertEqual(ui_tr["habit.create"], "Alışkanlık oluştur")
        self.assertEqual(ui_tr["habit.name.placeholder"], "Alışkanlık adı")
        self.assertIn("iCloud", ui_tr["backup.warning"])
        self.assertIn("CloudKit", ui_tr["health.privacy"])
        self.assertIn("transkripsiyon", ui_tr["review.privacy.explanation"])
        self.assertIn("Kestirmeler", ui_tr["health.shortcuts.instructions"])
        self.assertIn("Türkçe", (root / "HabitsByArvectum/Localization.swift").read_text())
        self.assertIn("testTurkishEmptyStateAndHabitForm",
                      (root / "HabitsByArvectumUITests/TurkishLocalizationUITests.swift").read_text())

    def test_polish_photo_source_and_permission_copy(self):
        root = ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Resources"
        en = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
        pl = i18n.read_strings(root / "pl.lproj/Localizable.strings", [])
        self.assertEqual(len(en), 161)
        self.assertEqual(set(en), set(pl))
        for key in en:
            self.assertEqual(i18n.placeholders(en[key]), i18n.placeholders(pl[key]), key)
        en_info = i18n.read_strings(root / "en.lproj/InfoPlist.strings", [])
        pl_info = i18n.read_strings(root / "pl.lproj/InfoPlist.strings", [])
        self.assertEqual(set(en_info), set(pl_info))
        self.assertEqual(pl["Уменьшить фото"], "Zmniejsz zdjęcie")
        self.assertEqual(pl["Уменьшить PDF"], "Zmniejsz PDF")
        self.assertIn("identyfikatora reklamowego",
                      pl_info["NSUserTrackingUsageDescription"])
        self.assertIn("rasteryzowane", pl[
            "Обработка выполняется только на устройстве. При сильном сжатии страницы PDF растрируются, поэтому поиск и выделение текста в готовом файле могут быть недоступны."
        ])
        self.assertIn("testPolishPhotoResult",
                      (ROOT / "photo-pdf-to-size/ios/PhotoPodRazmerUITests/PolishLocalizationUITests.swift").read_text())


    def test_pushkin_polish_complete_i_phone_and_shortcuts_safety(self):
        base = ROOT / "pushkin/ios/ArvectumNotify/Resources"
        en = i18n.read_strings(base / "en.lproj/Localizable.strings", [])
        pl = i18n.read_strings(base / "pl.lproj/Localizable.strings", [])
        self.assertEqual(len(pl), len(en))
        self.assertEqual(set(en), set(pl))
        for key in en:
            self.assertEqual(i18n.placeholders(en[key]), i18n.placeholders(pl[key]), key)
        self.assertEqual(pl["History"], "Historia")
        self.assertEqual(pl["Settings"], "Ustawienia")
        self.assertEqual(pl["Shortcuts"], "Skróty")
        self.assertIn("nie może sprawdzić ani zmienić", pl[
            "Only Shortcuts knows whether an automation is enabled. PUSHKIN cannot check or change that switch."
        ])
        self.assertIn("wyłącznie na tym iPhonie", pl[
            "No account, cloud sync, ads or analytics. PUSHKIN stores your notification content on this iPhone only."
        ])
        self.assertIn("nie usuwa automatyzacji ani historii", pl[
            "Clearing this local checklist does not remove any automation or notification history."
        ])
        swift = (ROOT / "pushkin/ios/ArvectumNotify/BrandStyle.swift").read_text()
        self.assertIn('"pl"', swift)
        ui = ROOT / "pushkin/ios/ArvectumNotifyUITests/PolishLocalizationUITests.swift"
        self.assertIn("testPolishTabsSetupAndSettings", ui.read_text())


    def test_uhvat_polish_full_iphone_watch_widgets_and_safety_copy(self):
        root = ROOT / "what/ios"
        for bundle, expected in (
            ("WhatIOS", 247), ("WhatWatch", 6),
            ("WhatPhoneWidget", 6), ("WhatWatchComplication", 5)
        ):
            for name in ("Localizable.strings", "InfoPlist.strings"):
                en = i18n.read_strings(root / bundle / "en.lproj" / name, [])
                pl = i18n.read_strings(root / bundle / "pl.lproj" / name, [])
                self.assertEqual(set(en), set(pl), (bundle, name))
                if name == "Localizable.strings":
                    self.assertEqual(len(pl), expected)
                for key in en:
                    self.assertEqual(i18n.placeholders(en[key]),
                                     i18n.placeholders(pl[key]), (bundle, name, key))
        ios = i18n.read_strings(root / "WhatIOS/pl.lproj/Localizable.strings", [])
        self.assertEqual(ios["Catch that thought"], "Zapisz tę myśl")
        self.assertEqual(ios["Archive action"], "Archiwizuj")
        self.assertIn("Oryginalne nagranie zostanie zachowane", ios[
            "A new transcription will replace your current text, including any manual corrections. The original audio will be kept."
        ])
        self.assertIn("dźwięk", ios[
            "Your Watch last reported recordings waiting for iPhone confirmation. Audio stays on Watch until iPhone confirms saving; background delivery can be delayed."
        ].lower())
        self.assertIn("Usunięte notatki nie zostaną odzyskane", ios[
            "The last valid backup will be used. Recent text edits may be missing. Deleted notes will not be restored."
        ])
        self.assertIn("500 MB", ios["Audio exceeds 500 MB. Your original is safe."])
        self.assertIn("maksymalnie 10", ios["Select up to 10 audio files at a time."])
        watch = i18n.read_strings(root / "WhatWatch/pl.lproj/Localizable.strings", [])
        self.assertEqual(watch["%d waiting for iPhone"], "Oczekujące na iPhone’a: %d")
        self.assertIn('"pl"', (root / "Shared/CaptureBrand.swift").read_text())
        self.assertIn("testPolishAXXXLHomeControlsWithoutRecording",
                      (root / "WhatIOSUITests/PolishLocalizationUITests.swift").read_text())


    def test_polish_chickmark_complete_iphone_watch_widgets_shortcuts_health(self):
        root = ROOT / "chickmark/ios"
        bundles = (
            ("HabitsByArvectum", 315),
            ("HabitsByArvectumWatch", 22),
            ("HabitsByArvectumWidget", 16),
            ("HabitsByArvectumWatchWidget", 5),
        )
        for bundle, count in bundles:
            with self.subTest(bundle=bundle):
                en = i18n.read_strings(root / bundle / "en.lproj/Localizable.strings", [])
                pl = i18n.read_strings(root / bundle / "pl.lproj/Localizable.strings", [])
                self.assertEqual(len(en), count)
                self.assertEqual(set(en), set(pl))
                for key in en:
                    self.assertEqual(i18n.placeholders(en[key]),
                                     i18n.placeholders(pl[key]), (bundle, key))
        for bundle in ("HabitsByArvectum", "HabitsByArvectumWatch"):
            en = i18n.read_strings(root / bundle / "en.lproj/InfoPlist.strings", [])
            pl = i18n.read_strings(root / bundle / "pl.lproj/InfoPlist.strings", [])
            self.assertEqual(set(en), set(pl))
            for key in en:
                self.assertEqual(i18n.placeholders(en[key]),
                                 i18n.placeholders(pl[key]), key)
        en = i18n.read_strings(root / "HabitsByArvectum/en.lproj/AppShortcuts.strings", [])
        pl = i18n.read_strings(root / "HabitsByArvectum/pl.lproj/AppShortcuts.strings", [])
        self.assertEqual(len(en), 4)
        self.assertEqual(set(en), set(pl))
        ios = i18n.read_strings(root / "HabitsByArvectum/pl.lproj/Localizable.strings", [])
        self.assertEqual(ios["habit.create"], "Utwórz nawyk")
        self.assertEqual(ios["habit.name.placeholder"], "Nazwa nawyku")
        self.assertNotEqual(ios["habit.undo"], ios["habit.skip.undo"])
        self.assertEqual(ios["habit.multi.unchecked"], "Niewykonane")
        self.assertIn("iCloud", ios["backup.warning"])
        self.assertIn("usuni", ios["backup.warning"].lower())
        self.assertIn("CloudKit", ios["health.privacy"])
        self.assertIn("reklam", ios["health.privacy"].lower())
        self.assertIn("schowka", ios["review.paste.expired"])
        self.assertEqual(ios["restart.settings.title"], "Łagodny powrót")
        self.assertIn("nie zawiera treści transkrypcji",
                      ios["review.privacy.explanation"])
        watch = i18n.read_strings(
            root / "HabitsByArvectumWatch/pl.lproj/Localizable.strings", [])
        self.assertEqual(watch["watch.step.remove"], "Cofnij jeden krok")
        self.assertIn("Polski", (root / "HabitsByArvectum/Localization.swift").read_text())
        self.assertIn("testPolishEmptyStateAndNewHabitForm",
                      (root / "HabitsByArvectumUITests/PolishLocalizationUITests.swift").read_text())


    def test_vietnamese_photo_complete_i_phone_permissions_and_pdf_safety(self):
        root = ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Resources"
        en = i18n.read_strings(root / "en.lproj/Localizable.strings", [])
        vi = i18n.read_strings(root / "vi.lproj/Localizable.strings", [])
        self.assertEqual(len(en), 161)
        self.assertEqual(set(en), set(vi))
        for key in en:
            self.assertEqual(i18n.placeholders(en[key]),
                             i18n.placeholders(vi[key]), key)
        info_en = i18n.read_strings(root / "en.lproj/InfoPlist.strings", [])
        info_vi = i18n.read_strings(root / "vi.lproj/InfoPlist.strings", [])
        self.assertEqual(set(info_en), set(info_vi))
        self.assertIn("PDF", vi["Уменьшить PDF"])
        self.assertIn("500", vi["500 КБ"])
        self.assertIn("raster hóa", vi[
            "Обработка выполняется только на устройстве. При сильном сжатии страницы PDF растрируются, поэтому поиск и выделение текста в готовом файле могут быть недоступны."
        ])
        self.assertIn("dữ liệu", vi["Разрешить для рекламы"])
        self.assertEqual(vi["Отказаться"], "Từ chối")
        self.assertIn("không yêu cầu quyền App Tracking Transparency", vi[
            "Фото и PDF обрабатываются только на устройстве. Для показа рекламы используется Yandex Mobile Ads. Вы можете разрешить рекламному SDK обработку технических данных или отказаться. Геолокация отключена, разрешение App Tracking Transparency приложение не запрашивает."
        ])
        self.assertIn("iOS có thể yêu cầu quyền theo dõi", vi[
            "«Фото и PDF под размер» бесплатно и поддерживается рекламой. Реклама будет показываться независимо от вашего выбора. Вы можете разрешить или не разрешить Yandex Mobile Ads обработку данных для рекламы. Если разрешите, iOS может отдельно спросить разрешение на отслеживание. При отказе реклама останется, но без доступа к рекламному идентификатору. Фото и PDF обрабатываются только на устройстве, геолокация отключена."
        ])
        self.assertIn("mã định danh quảng cáo",
                      info_vi["NSUserTrackingUsageDescription"])
        self.assertIn("testVietnamesePhotoResult", (ROOT /
            "photo-pdf-to-size/ios/PhotoPodRazmerUITests/VietnameseLocalizationUITests.swift"
        ).read_text())



if __name__ == "__main__":
    unittest.main()
