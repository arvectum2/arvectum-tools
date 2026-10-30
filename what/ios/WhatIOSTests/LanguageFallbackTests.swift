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

    func testPolishCompleteBundleAndIndependentTranscriptionLanguage() {
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["pl-PL", "en-US"]), "pl")
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["pl_PL", "en-US"]), "pl")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "pl"), "en-US")
        XCTAssertEqual(CaptureBrand.text("Ухвати мысль", "Catch that thought", language: "pl"), "Zapisz tę myśl")
        XCTAssertEqual(CaptureBrand.text("Записать", "Record", language: "pl-PL"), "Nagraj")
        XCTAssertEqual(CaptureBrand.text("Все заметки", "All notes", language: "pl_PL"), "Wszystkie notatki")
        XCTAssertEqual(CaptureBrand.text("В архив", "Archive action", language: "pl"), "Archiwizuj")
        for (number, expected) in [
            (0,"0 notatek"), (1,"1 notatka"), (2,"2 notatki"),
            (5,"5 notatek"), (11,"11 notatek"), (12,"12 notatek"),
            (22,"22 notatki"), (25,"25 notatek")
        ] {
            XCTAssertEqual(CaptureBrand.noteCount(number, language: "pl-PL"), expected)
        }
        XCTAssertEqual(CaptureBrand.formatted("Вход: %@", "Input: %@", language: "pl", "Mikrofon"),
                       "Wejście: Mikrofon")
        XCTAssertEqual(CaptureBrand.text("Неизвестно", "Unknown key", language: "pl"), "Unknown key")
    }

    func testTurkishUIRoutingAndIndependentTranscriptionLanguage() {
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for:["tr-TR","en-US"]),"tr")
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for:["tr-CY","en-US"]),"tr")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for:"tr"),"en-US")
        XCTAssertEqual(CaptureBrand.text("Ухвати мысль","Catch that thought",language:"tr"),"Düşünceyi yakalayın")
        XCTAssertEqual(CaptureBrand.noteCount(1,language:"tr"),"1 not")
        XCTAssertEqual(CaptureBrand.noteCount(5,language:"tr-TR"),"5 not")
        XCTAssertEqual(CaptureBrand.formatted("Вход: %@","Input: %@",language:"tr","Mikrofon"),"Giriş: Mikrofon")
        XCTAssertEqual(CaptureBrand.text("Неизвестный","Unknown",language:"tr"),"Unknown")
    }

    func testIndonesianUIRoutingAndIndependentSpeechLanguage() {
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["id-ID", "en-US"]), "id")
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["id_ID", "en-US"]), "id")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "id"), "en-US")
        XCTAssertEqual(CaptureBrand.text("Ухвати мысль", "Catch that thought", language: "id"),
                       "Tangkap ide itu")
        XCTAssertEqual(CaptureBrand.text("Записать", "Record", language: "id-ID"), "Rekam")
        XCTAssertEqual(CaptureBrand.text("Все заметки", "All notes", language: "id_ID"), "Semua catatan")
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "id"), "1 catatan")
        XCTAssertEqual(CaptureBrand.noteCount(25, language: "id-ID"), "25 catatan")
        XCTAssertEqual(CaptureBrand.formatted("Вход: %@", "Input: %@", language: "id", "Mikrofon"),
                       "Masukan: Mikrofon")
        XCTAssertEqual(CaptureBrand.text("Неизвестно", "Unknown key", language: "id"),
                       "Unknown key")
    }

    func testDutchInterfaceWatchLabelsAndIndependentTranscriptionPreference() {
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["nl-NL", "en-US"]), "nl")
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["nl-BE", "en-US"]), "nl")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "nl"), "en-US")
        XCTAssertEqual(CaptureBrand.text("Ухвати мысль", "Catch that thought", language: "nl"),
                       "Leg die gedachte vast")
        XCTAssertEqual(CaptureBrand.text("Записать", "Record", language: "nl-NL"),
                       "Opnemen")
        XCTAssertEqual(CaptureBrand.text("Все заметки", "All notes", language: "nl-BE"),
                       "Alle notities")
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "nl"), "1 notitie")
        XCTAssertEqual(CaptureBrand.noteCount(2, language: "nl-NL"), "2 notities")
        XCTAssertEqual(CaptureBrand.formatted("Вход: %@", "Input: %@", language: "nl", "Microfoon"),
                       "Invoer: Microfoon")
        XCTAssertEqual(CaptureBrand.text("Неизвестно", "Unknown key", language: "nl"),
                       "Unknown key", "Unknown strings fall back to the unchanged English original")
    }

    func testKoreanInterfaceAndCounterWithIndependentDictation() {
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["ko-KR", "en-US"]), "ko")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "ko"), "en-US")
        XCTAssertEqual(CaptureBrand.text("Создать", "New text note", language: "ko"), "새 텍스트 메모")
        XCTAssertEqual(CaptureBrand.text("Записать", "Record", language: "ko-KR"), "녹음")
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "ko"), "1개 메모")
        XCTAssertEqual(CaptureBrand.noteCount(4, language: "ko-KR"), "4개 메모")
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
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["zh-Hant-TW", "en"]), "zh-Hant")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "zh"), "en-US")
        XCTAssertEqual(
            CaptureBrand.text("Все заметки", "All notes", language: "zh-Hans"), "全部笔记")
        XCTAssertEqual(
            CaptureBrand.text("Сохранить", "Save", language: "zh-CN"), "保存")
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "zh-Hans"), "1条笔记")
        XCTAssertEqual(CaptureBrand.noteCount(2, language: "zh-CN"), "2条笔记")
        XCTAssertEqual(
            CaptureBrand.text("Все заметки", "All notes", language: "zh-Hant"), "全部筆記")
        XCTAssertEqual(CaptureBrand.noteCount(2, language: "zh-TW"), "2 則筆記")
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

    func testEuropeanPortugueseRegionalSelection() {
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["pt-PT", "en-US"]), "pt-PT")
        XCTAssertEqual(CaptureBrand.resolvedInterfaceLanguage(for: ["pt-BR", "en-US"]), "pt")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "pt"), "en-US")
        XCTAssertEqual(CaptureBrand.text("Сохранить", "Save", language: "pt-PT"), "Guardar")
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
