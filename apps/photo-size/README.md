# Фото и PDF под размер

Arvectum Tools utility for preparing photos and PDFs to required file-size, pixel-size, or document-photo constraints.

**Principles:** One tool. One job. Done. · Local first.

Native utility for fitting photos and PDFs to practical file constraints. iOS currently includes three photo modes plus PDF-by-file-size:

- **По весу** — make an image fit a maximum file size.
- **По размеру** — set the long side to 600 / 450 / 300 px or a custom value; the short side is calculated automatically with aspect ratio preserved.
- **На паспорт** — prepare the technical file for a passport application through Госуслуги: manual 35×45 crop, 620×797 px, 450 DPI, JPEG, 10 KB–5 MB.
- **PDF по весу (iOS)** — make a PDF fit a maximum file size, fully on-device. Strong compression rasterizes pages, so text selection/search may be lost.

Passport mode changes only crop and technical file parameters. It does not use AI, retouch the image, replace the background, analyze the face, or claim that the photographed person satisfies visual eligibility requirements.

## Product guardrail

Keep the product focused on one job: make a photo or PDF meet a required size/dimension. Avoid turning it into a general editor, converter, scanner, OCR suite, or PDF toolkit unless market validation justifies a separate product.

## Build

### Android

Requirements: JDK 17 and Android 17 preview SDK platform 37.0 (compileSdk 37).

```bash
cd android
./gradlew assembleDebug lintDebug test
```

Debug APK: `android/app/build/outputs/apk/debug/app-debug.apk`.

### iOS

Requirements: Xcode 26.x and XcodeGen.

```bash
cd ios
xcodegen generate
xcodebuild -project PhotoPodRazmerIOS.xcodeproj -scheme PhotoPodRazmer \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

The App Store release target uses bundle ID `ru.arvectum.tools.tosize`. See `docs/appstore/` for release metadata and checklist.

See [ROADMAP.md](ROADMAP.md) for the canonical product contract and [../../BRAND.md](../../BRAND.md) for shared family-level brand rules.
