import XCTest
@testable import ArvectumNotify

final class CoverageCatalogTests: XCTestCase {
    func testInternationalStarterAppsSurfaceExistingSignedPackages() {
        let international = CoverageCatalog.commonEntries(preferredLanguages: ["en-US"])
        let ids = Set(international.map(\.bundleIdentifier))
        for id in ["com.google.Gmail", "com.burbn.instagram",
                   "com.hammerandchisel.discord", "org.whispersystems.signal",
                   "com.ubercab.UberClient", "doordash.DoorDashConsumer"] {
            XCTAssertTrue(ids.contains(id), "Catalog app should be discoverable: \(id)")
        }
        XCTAssertEqual(international.count, 20)
        let russian = CoverageCatalog.commonEntries(preferredLanguages: ["ru-RU"])
        XCTAssertEqual(russian.first?.bundleIdentifier, "ph.telegra.Telegraph")
        XCTAssertTrue(russian.prefix(6).contains(where: {
            $0.bundleIdentifier == "ru.ozon.OzonStore"
        }))
    }

    func testLocalizedOptionalGroupCopyAndCounts() {
        XCTAssertEqual(PushkinCopy.text("Optional Groups", language: "ru-RU"),
                       "Дополнительные группы")
        XCTAssertEqual(PushkinCopy.text("Clear group plan", language: "ru"),
                       "Очистить план")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "ru"), "1 приложение")
        XCTAssertEqual(PushkinCopy.appCount(2, language: "ru"), "2 приложения")
        XCTAssertEqual(PushkinCopy.appCount(5, language: "ru"), "5 приложений")
        XCTAssertEqual(PushkinCopy.appCount(11, language: "ru"), "11 приложений")
        XCTAssertEqual(PushkinCopy.appCount(21, language: "ru"), "21 приложение")
        XCTAssertEqual(PushkinCopy.appCount(25, language: "ru"), "25 приложений")
        XCTAssertEqual(PushkinCopy.appCount(25, language: "en"), "25 apps")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "es-ES"), "1 aplicación")
        XCTAssertEqual(PushkinCopy.appCount(2, language: "es"), "2 aplicaciones")
        XCTAssertEqual(PushkinCopy.appCount(11, language: "es"), "11 aplicaciones")
    }

    func testRussianCopyAndEnglishFallback() {
        XCTAssertEqual(
            PushkinCopy.text("History", language: "ru-RU"),
            "История"
        )
        XCTAssertEqual(
            PushkinCopy.text("Apps", language: "ru"),
            "Источники"
        )
        XCTAssertEqual(
            PushkinCopy.text("History", language: "en-GB"),
            "History"
        )
        XCTAssertEqual(PushkinCopy.text("History", language: "es-ES"), "Historial")
        XCTAssertEqual(PushkinCopy.text("Apps", language: "es"), "Aplicaciones")
        XCTAssertEqual(PushkinCopy.text("Group %d", language: "es"), "Grupo %d")
        XCTAssertEqual(PushkinCopy.text("History", language: "fr-FR"), "Historique")
        XCTAssertEqual(
            PushkinCopy.text("Unknown label", language: "ru"),
            "Unknown label"
        )
        XCTAssertEqual(
            PushkinCopy.text("History is empty", language: "ru-RU"),
            "История пока пуста"
        )
    }

    func testSpanishCatalogAndUnknownLanguageFallback() {
        XCTAssertEqual(PushkinCopy.text("History", language: "es-ES"), "Historial")
        XCTAssertEqual(PushkinCopy.text("Apps", language: "es"), "Aplicaciones")
        XCTAssertEqual(PushkinCopy.text("Group %d", language: "es"), "Grupo %d")
        XCTAssertEqual(
            PushkinCopy.text("Notification content stays on this device", language: "es-MX"),
            "El contenido de las notificaciones permanece en este dispositivo"
        )
        XCTAssertEqual(PushkinCopy.text("History", language: "fr-FR"), "Historique")
        XCTAssertEqual(PushkinCopy.text("Unknown label", language: "es"), "Unknown label")
        XCTAssertEqual(
            String(format: PushkinCopy.text("Group %d", language: "es"), 5),
            "Grupo 5"
        )
    }

    func testFrenchCatalogAndCount() {
        XCTAssertEqual(PushkinCopy.text("History", language: "fr-FR"), "Historique")
        XCTAssertEqual(PushkinCopy.text("Settings", language: "fr-CA"), "Réglages")
        XCTAssertEqual(PushkinCopy.text("Apps & Setup", language: "fr"), "Apps et configuration")
        XCTAssertEqual(PushkinCopy.text("Group %d", language: "fr"), "Groupe %d")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "fr-FR"), "1 application")
        XCTAssertEqual(PushkinCopy.appCount(2, language: "fr-FR"), "2 applications")
        XCTAssertEqual(PushkinCopy.appCount(0, language: "fr-FR"), "0 applications")
        XCTAssertEqual(PushkinCopy.text("This text is not in source", language: "fr"),
                       "This text is not in source")
    }

    func testGermanUsesBundledTranslationsInsteadOfEnglishFallback() {
        XCTAssertEqual(PushkinCopy.text("History", language: "de-DE"), "Verlauf")
        XCTAssertEqual(PushkinCopy.text("Settings", language: "de"), "Einstellungen")
        XCTAssertEqual(PushkinCopy.text("Apps & Setup", language: "de-DE"), "Apps & Einrichtung")
        XCTAssertEqual(PushkinCopy.text("Group %d", language: "de"), "Gruppe %d")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "de-DE"), "1 App")
    }

    func testEuropeanPortugueseBundleRouting() {
        XCTAssertEqual(PushkinCopy.text("Delete", language: "pt-PT"), "Eliminar")
        XCTAssertEqual(PushkinCopy.text("History", language: "pt-PT"), "Histórico")
    }

    func testBrazilianPortugueseBundleAndAppCount() {
        XCTAssertEqual(PushkinCopy.text("History", language: "pt-BR"), "Histórico")
        XCTAssertEqual(PushkinCopy.text("Settings", language: "pt_BR"), "Ajustes")
        XCTAssertEqual(PushkinCopy.text("Apps & Setup", language: "pt"), "Apps e configuração")
        XCTAssertEqual(PushkinCopy.text("Group %d", language: "pt-BR"), "Grupo %d")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "pt-BR"), "1 app")
        XCTAssertEqual(PushkinCopy.appCount(2, language: "pt-BR"), "2 apps")
    }

    func testTurkishCopyAndShortcutsConsentBoundaries() {
        XCTAssertEqual(PushkinCopy.text("History", language: "tr-TR"), "Geçmiş")
        XCTAssertEqual(PushkinCopy.text("Apps & Setup", language: "tr"), "Uygulamalar ve Kurulum")
        XCTAssertEqual(PushkinCopy.text("Settings", language: "tr-CY"), "Ayarlar")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "tr"), "1 uygulama")
        XCTAssertEqual(PushkinCopy.appCount(25, language: "tr-TR"), "25 uygulama")
        XCTAssertEqual(PushkinCopy.text("Notification content stays on this device", language: "tr"),
                       "Bildirim içeriği bu cihazda kalır")
        XCTAssertTrue(PushkinCopy.text(
            "Only Shortcuts knows whether an automation is enabled. PUSHKIN cannot check or change that switch.",
            language: "tr").contains("kontrol edemez"))
    }

    func testIndonesianBundleRoutingAndShortcutsSafetyWarnings() {
        XCTAssertEqual(PushkinCopy.text("History", language: "id-ID"), "Riwayat")
        XCTAssertEqual(PushkinCopy.text("Apps & Setup", language: "id"), "Aplikasi & Pengaturan")
        XCTAssertEqual(PushkinCopy.text("Settings", language: "id_ID"), "Pengaturan")
        XCTAssertEqual(PushkinCopy.text("Group %d", language: "id-ID"), "Grup %d")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "id"), "1 aplikasi")
        XCTAssertEqual(PushkinCopy.appCount(25, language: "id-ID"), "25 aplikasi")
        XCTAssertEqual(PushkinCopy.text("Unknown UI text", language: "id"), "Unknown UI text")
        let notice = PushkinCopy.text("Only Shortcuts knows whether an automation is enabled. PUSHKIN cannot check or change that switch.", language: "id-ID")
        XCTAssertTrue(notice.contains("tidak dapat memeriksa"))
        XCTAssertEqual(PushkinCopy.text("Notification content stays on this device", language: "id"),
                       "Isi notifikasi tetap di perangkat ini")
    }

    func testDutchBundleRoutingAndShortcutsSafetyWarnings() {
        XCTAssertEqual(PushkinCopy.text("History", language: "nl-NL"), "Geschiedenis")
        XCTAssertEqual(PushkinCopy.text("Apps & Setup", language: "nl"), "Apps en configuratie")
        XCTAssertEqual(PushkinCopy.text("Settings", language: "nl_BE"), "Instellingen")
        XCTAssertEqual(PushkinCopy.text("Group %d", language: "nl-NL"), "Groep %d")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "nl"), "1 app")
        XCTAssertEqual(PushkinCopy.appCount(25, language: "nl-NL"), "25 apps")
        XCTAssertEqual(PushkinCopy.text("Unknown UI text", language: "nl"),
                       "Unknown UI text", "Unknown keys preserve safe English fallback")
        let limited = PushkinCopy.text(
            "Only Shortcuts knows whether an automation is enabled. PUSHKIN cannot check or change that switch.",
            language: "nl-NL"
        )
        XCTAssertTrue(limited.contains("niet controleren"))
        let privacy = PushkinCopy.text("Notification content stays on this device", language: "nl")
        XCTAssertEqual(privacy, "De inhoud van meldingen blijft op dit apparaat")
    }

    func testItalianInterfaceLoadsRealBundledStrings() {
        XCTAssertEqual(PushkinCopy.text("History", language: "it-IT"), "Cronologia")
        XCTAssertEqual(PushkinCopy.text("Settings", language: "it"), "Impostazioni")
        XCTAssertEqual(PushkinCopy.text("Apps & Setup", language: "it-IT"), "App e configurazione")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "it"), "1 app")
        XCTAssertEqual(PushkinCopy.appCount(2, language: "it"), "2 app")
    }

    func testKoreanBundleAndRegionalLanguageFallback() {
        XCTAssertEqual(PushkinCopy.text("History", language: "ko"), "기록")
        XCTAssertEqual(PushkinCopy.text("History", language: "ko-KR"), "기록")
        XCTAssertEqual(PushkinCopy.text("Apps", language: "ko_KR"), "앱")
        XCTAssertEqual(PushkinCopy.text("Apps & Setup", language: "ko"), "앱 및 설정")
        XCTAssertEqual(PushkinCopy.text("Group %d", language: "ko-KR"), "그룹 %d")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "ko"), "1개 앱")
        XCTAssertEqual(PushkinCopy.appCount(25, language: "ko-KR"), "25개 앱")
        XCTAssertEqual(PushkinCopy.text("Unknown UI label", language: "ko"), "Unknown UI label")
    }

    func testJapaneseUsesRealBundledTranslationsAndCounters() {
        XCTAssertEqual(PushkinCopy.text("History", language: "ja-JP"), "履歴")
        XCTAssertEqual(PushkinCopy.text("Settings", language: "ja"), "設定")
        XCTAssertEqual(PushkinCopy.text("Apps & Setup", language: "ja-JP"), "アプリと設定")
        XCTAssertEqual(PushkinCopy.text("Group %d", language: "ja"), "グループ %d")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "ja"), "1件のアプリ")
        XCTAssertEqual(PushkinCopy.appCount(2, language: "ja-JP"), "2件のアプリ")
    }

    func testSimplifiedChineseBundleAndTraditionalChineseFallback() {
        XCTAssertEqual(PushkinCopy.text("History", language: "zh-Hans"), "历史记录")
        XCTAssertEqual(PushkinCopy.text("Settings", language: "zh-CN"), "设置")
        XCTAssertEqual(PushkinCopy.text("Apps & Setup", language: "zh-Hans-CN"), "应用与设置")
        XCTAssertEqual(PushkinCopy.text("Group %d", language: "zh-CN"), "第%d组")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "zh-Hans"), "1个应用")
        XCTAssertEqual(PushkinCopy.appCount(2, language: "zh-CN"), "2个应用")
        XCTAssertEqual(PushkinCopy.text("History", language: "zh-Hant"), "歷史記錄")
        XCTAssertEqual(PushkinCopy.text("Settings", language: "zh-TW"), "設定")
        XCTAssertEqual(PushkinCopy.appCount(2, language: "zh-TW"), "2 個應用程式")
    }

    func testPendingSourceNameIsBriefWithoutChangingSourceIdentity() {
        XCTAssertEqual(
            PushkinDisplayName.brief("CapCut: Photo & Video Editor"),
            "CapCut"
        )
        XCTAssertEqual(PushkinDisplayName.brief("Telegram"), "Telegram")
        XCTAssertEqual(PushkinDisplayName.brief("  "), "")
    }

    func testProductionCatalogHasExactly1000UniqueApps() {
        let entries = CoverageCatalog.entries
        XCTAssertEqual(entries.count, 1000)
        XCTAssertEqual(Set(entries.map(\.bundleIdentifier)).count, 1000)
        XCTAssertFalse(entries.contains {
            $0.bundleIdentifier == "ru.arvectum.pushkin.futuretest"
        })
    }

    func testBaseAndEveryMicroPackageAreBundled() {
        XCTAssertNotNil(CoverageCatalog.basePackageURL)
        let missing = CoverageCatalog.entries.filter {
            CoverageCatalog.packageURL(for: $0) == nil
        }
        XCTAssertTrue(
            missing.isEmpty,
            "Missing micro-packages: \(missing.prefix(10).map(\.name))"
        )
    }

    func testCoveragePackageURLsAreLocalFiles() {
        XCTAssertEqual(CoverageCatalog.basePackageURL?.isFileURL, true)
        XCTAssertTrue(
            CoverageCatalog.entries.allSatisfy {
                CoverageCatalog.packageURL(for: $0)?.isFileURL == true
            }
        )
    }

    func testCommonPickerPrioritizesMassMarketApps() {
        let bundles = Set(CoverageCatalog.commonEntries.map(\.bundleIdentifier))
        XCTAssertTrue(bundles.contains("ph.telegra.Telegraph"))
        XCTAssertTrue(bundles.contains("ru.ozon.OzonStore"))
        XCTAssertTrue(bundles.contains("ru.yandex.ytaxi"))
        XCTAssertTrue(bundles.contains("ru.doublegis.grymmobile"))
        XCTAssertFalse(bundles.contains("ru.arvectum.pushkin.futuretest"))
    }
}
