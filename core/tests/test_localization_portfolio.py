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
        # The iPhone catalog gained two Watch delivery-state explanations.
        keys = [230, 6, 6, 5]
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
            ("HabitsByArvectum", 302),
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
        self.assertEqual(len(fr), 151)
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
