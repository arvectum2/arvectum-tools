# PUSHKIN 1.0.2 (6): RU/EN/ES/FR release candidate

24.10.2026. Signed distribution release candidate on Mac mini.
NOT uploaded to App Store Connect/TestFlight or submitted for App Review.
Current Apple state: live 1.0.1 build 5 READY_FOR_SALE;
App Store only lists English under app Languages (RU/en-US store localizations).

- Bundle ID ru.arvectum.tools.notify; iPhone only; iOS 27+.
- Version 1.0.2 build 6, Xcode 27.1.
- Source release/pushkin-1.0.2-four-locales-20261024 from main.
- Source catalog 151/151 keys each in RU, EN, ES, FR.
- Xcode ARCHIVE SUCCEEDED and distribution EXPORT SUCCEEDED.
- Mac mini IPA: /Volumes/ArvectumSSD/Arvectum/releases/pushkin-102-four-locales-20261024/export/ArvectumNotify.ipa
- Size 15 278 115 bytes; SHA-256
  4c5ad84f6f58f83739e064a0752bb12f59ccc742f3557ba64a80aeeb6af1cb89.
- codesign --verify --deep --strict PASS, designated requirement satisfied.
- Signed IPA has runtime Localizable.strings for ru/en/es/fr:
  21444/7958/23244/24032 bytes respectively.
- Portfolio localization audit PASS, 33/33 Python tests PASS.
  Structural checks do not prove all dynamic messages are perfect.
- Last in-code changes since public build include 4-language runtime
  and UI accessibility/design work. No automatic Shortcuts changes
  or user-notification history mutations during preparation.

## Remaining gates

- [x] Four actual IPA language catalogs and signature verified.
- [ ] PR GitHub CI and merge to main.
- [ ] Isolated iPhone Simulator RU/ES/FR UI check without user data.
- [ ] App Store 1.0.2 metadata: RU/EN update, ES/FR new localizations,
      required screenshots.
- [ ] Only after separate owner approval for exact 1.0.2 build 6:
      upload signed IPA, review submission, AFTER_APPROVAL.
- [ ] After approval check READY_FOR_SALE and public language listings.

The app does not automatically capture every iOS notification:
sources require supported Shortcuts automation and explicit setup.
