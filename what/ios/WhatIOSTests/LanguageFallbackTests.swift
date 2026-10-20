import XCTest
@testable import WhatIOS

final class LanguageFallbackTests: XCTestCase {
    func testUnsupportedDeviceLanguagesUseEnglish() {
        for language in ["fr", "de", "zh", "pt", "ar", "hi"] {
            XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: language), "en-US")
        }
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: nil), "en-US")
    }

    func testSupportedDeviceLanguagePreserved() {
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "ru"), "ru-RU")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "es"), "es-ES")
        XCTAssertEqual(CaptureBrand.defaultTranscriptionLocale(for: "en"), "en-US")
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
        XCTAssertEqual(CaptureBrand.noteCount(1, language: "de"), "1 note")
    }
}
