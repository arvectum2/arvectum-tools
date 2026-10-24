import XCTest
@testable import WhatIOS

final class LanguageFallbackTests: XCTestCase {
    func testUnsupportedDeviceLanguagesUseEnglish() {
        for language in ["de", "zh", "pt", "ar", "hi"] {
            XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: language), "en-US")
        }
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: nil), "en-US")
    }

    func testSupportedDeviceLanguagePreserved() {
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "ru"), "ru-RU")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "es"), "es-ES")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "fr"), "fr-FR")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "en"), "en-US")
    }
    func testInterfaceFollowsIOSLanguageNotDictationSetting() {
        XCTAssertEqual(
            CaptureBrand.resolvedInterfaceLanguage(for: ["ru-RU", "en-US"]),
            "ru"
        )
        XCTAssertEqual(
            CaptureBrand.resolvedInterfaceLanguage(for: ["es-ES", "ru-RU"]),
            "es"
        )
        XCTAssertEqual(
            CaptureBrand.resolvedInterfaceLanguage(for: ["en-GB", "es-ES"]),
            "en"
        )
        XCTAssertEqual(
            CaptureBrand.resolvedInterfaceLanguage(for: ["fr-FR", "en-GB"]),
            "fr"
        )
        XCTAssertEqual(
            CaptureBrand.resolvedInterfaceLanguage(for: ["zh-Hans"]),
            "zh"
        )
    }

    func testCompleteDynamicSentencePreservesValues() {
        XCTAssertEqual(
            CaptureBrand.formatted("Вход: %@", "Input: %@", language: "ru", "Microphone"),
            "Вход: Microphone"
        )
        XCTAssertEqual(
            CaptureBrand.formatted("Вход: %@", "Input: %@", language: "en", "Microphone"),
            "Input: Microphone"
        )
        XCTAssertEqual(
            CaptureBrand.formatted("Ожидают iPhone: %d", "%d waiting for iPhone", language: "ru", 4),
            "Ожидают iPhone: 4"
        )
        XCTAssertEqual(
            CaptureBrand.formatted("Ожидают iPhone: %d", "%d waiting for iPhone", language: "en", 4),
            "4 waiting for iPhone"
        )
    }

    func testSpanishCatalogAndFormatting() {
        XCTAssertEqual(
            CaptureBrand.text("Входящие", "Inbox", language: "es"),
            "Bandeja de entrada"
        )
        XCTAssertEqual(
            CaptureBrand.text("Записать", "Record", language: "es-ES"),
            "Grabar"
        )
        XCTAssertEqual(
            CaptureBrand.text("Входящие", "Inbox", language: "de-DE"),
            "Eingang"
        )
        XCTAssertEqual(
            CaptureBrand.text("Ухвати мысль", "Catch that thought", language: "es"),
            "Captura esa idea"
        )
        XCTAssertEqual(
            CaptureBrand.formatted("Все заметки, %@", "All notes, %@", language: "es", "0 notas"),
            "Todas las notas, 0 notas"
        )
        XCTAssertEqual(
            CaptureBrand.formatted("Вход: %@", "Input: %@", language: "es", "Micrófono"),
            "Entrada: Micrófono"
        )
        XCTAssertEqual(
            CaptureBrand.formatted("Восстановлено видео: %d.", "Recovered video notes: %d.", language: "es", 2),
            "Notas de vídeo recuperadas: 2."
        )
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "es"), "1 nota")
        XCTAssertEqual(CaptureBrand.noteCount(2, language: "es"), "2 notas")
        XCTAssertEqual(CaptureBrand.noteCount(0, language: "es"), "0 notas")
    }

    func testSimplifiedChineseUIAndTraditionalChineseFallback() {
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["zh-Hans-CN", "en"]), "zh")
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["zh-CN", "en"]), "zh")
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["zh-Hant-TW", "en"]), "en")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "zh"), "en-US")
        XCTAssertEqual(
            CaptureBrand.text("Все заметки", "All notes", language: "zh-Hans"), "全部笔记")
        XCTAssertEqual(
            CaptureBrand.text("Сохранить", "Save", language: "zh-CN"), "保存")
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "zh-Hans"), "1条笔记")
        XCTAssertEqual(CaptureBrand.noteCount(2, language: "zh-CN"), "2条笔记")
        XCTAssertEqual(
            CaptureBrand.text("Все заметки", "All notes", language: "zh-Hant"), "All notes")
        XCTAssertEqual(CaptureBrand.noteCount(2, language: "zh-TW"), "2 notes")
    }

    func testJapaneseInterfaceIsIndependentFromDictationLanguage() {
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["ja-JP", "en"]), "ja")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "ja"), "en-US")
        XCTAssertEqual(
            CaptureBrand.text("Все заметки", "All notes", language: "ja"), "すべてのメモ")
        XCTAssertEqual(
            CaptureBrand.text("Сохранить", "Save", language: "ja-JP"), "保存")
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "ja"), "1件のメモ")
        XCTAssertEqual(CaptureBrand.noteCount(2, language: "ja"), "2件のメモ")
    }

    func testItalianUIIsIndependentFromDictationLanguage() {
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["it-IT", "en"]), "it")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "it"), "en-US")
        XCTAssertEqual(
            CaptureBrand.text("Все заметки", "All notes", language: "it"), "Tutte le note")
        XCTAssertEqual(
            CaptureBrand.text("Сохранить", "Save", language: "it-IT"), "Salva")
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "it"), "1 nota")
        XCTAssertEqual(CaptureBrand.noteCount(2, language: "it"), "2 note")
    }

    func testBrazilianPortugueseInterfaceWithIndependentTranscription() {
        XCTAssertEqual(
            CaptureBrand.resolvedInterfaceLanguage(for: ["pt-BR", "en-US"]), "pt")
        // German/Portuguese UI does not imply their offline speech models exist.
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "pt"), "en-US")
        XCTAssertEqual(
            CaptureBrand.text("Все заметки", "All notes", language: "pt-BR"),
            "Todas as notas")
        XCTAssertEqual(
            CaptureBrand.text("Сохранить", "Save", language: "pt"), "Salvar")
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "pt-BR"), "1 nota")
        XCTAssertEqual(CaptureBrand.noteCount(2, language: "pt-BR"), "2 notas")
    }

    func testGermanInterfaceLocaleAndLocalTranslation() {
        XCTAssertEqual(
            CaptureBrand.resolvedInterfaceLanguage(for: ["de-DE", "en-US"]), "de")
        XCTAssertEqual(
            CaptureBrand.text("Все заметки", "All notes", language: "de"), "Alle Notizen")
        XCTAssertEqual(
            CaptureBrand.text("Сохранить", "Save", language: "de"), "Speichern")
        XCTAssertEqual(
            CaptureBrand.noteCount(2, language: "de"), "2 Notizen")
    }

    func testFrenchInterfaceAndSafeFormatting() {
        XCTAssertEqual(
            CaptureBrand.text("Входящие", "Inbox", language: "fr-FR"),
            "Boîte de réception"
        )
        XCTAssertEqual(
            CaptureBrand.text("Записать", "Record", language: "fr"),
            "Enregistrer"
        )
        XCTAssertEqual(
            CaptureBrand.formatted("Вход: %@", "Input: %@", language: "fr", "Microphone"),
            "Entrée : Microphone"
        )
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "fr"), "1 note")
        XCTAssertEqual(CaptureBrand.noteCount(2, language: "fr"), "2 notes")
    }

    func testNoteCountPluralFormsAreReadable() {
        XCTAssertEqual(CaptureBrand.noteCount(0, language: "ru"), "0 заметок")
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "ru"), "1 заметка")
        XCTAssertEqual(CaptureBrand.noteCount(2, language: "ru"), "2 заметки")
        XCTAssertEqual(CaptureBrand.noteCount(5, language: "ru"), "5 заметок")
        XCTAssertEqual(CaptureBrand.noteCount(11, language: "ru"), "11 заметок")
        XCTAssertEqual(CaptureBrand.noteCount(21, language: "ru"), "21 заметка")
        XCTAssertEqual(CaptureBrand.noteCount(114, language: "ru"), "114 заметок")
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "en"), "1 note")
        XCTAssertEqual(CaptureBrand.noteCount(25, language: "en"), "25 notes")
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "de"), "1 Notiz")
    }
}
