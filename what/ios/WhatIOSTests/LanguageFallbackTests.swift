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
}
