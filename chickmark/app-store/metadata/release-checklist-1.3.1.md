# ChickMark 1.3.1 (6) — release candidate, NOT submitted

Prepared on 2026-10-12 in branch feature/chickmark-1.3.1-branding-links.
Published baseline remains **1.3.0 (5)** until Apple approves and owner publishes this version.
Do not submit, release, or overwrite the installed physical app without explicit approval.

## What changes
- Refresh app against the 2026-10-11 Arvectum Tools monorepo/Core refactor.
- Show ChickMark name, original Arvectum wordmark, and dynamic app version on Today (including empty state).
- Tapping the brand header opens the localized official product page.
- Keep iOS, Apple Watch, Watch complication, and iOS widget version/build in sync: **1.3.1 (6)**.
- No data model, CloudKit identity, paid feature, new permissions, or advertising policy changes.

## App Store Connect — URLs to enter in NEW 1.3.1 version metadata

| App Store locale | Marketing URL | Support URL |
| --- | --- | --- |
| ru-RU | https://arvectum.com/tools/chickmark/index.html | https://arvectum.com/tools/chickmark/index.html |
| en-US | https://arvectum.com/tools/chickmark/en/index.html | https://arvectum.com/tools/chickmark/en/index.html |
| es-ES | https://arvectum.com/tools/chickmark/es/index.html | https://arvectum.com/tools/chickmark/es/index.html |
| es-MX | https://arvectum.com/tools/chickmark/es/index.html | https://arvectum.com/tools/chickmark/es/index.html |

The app's canonical privacy URL stays https://arvectum.com/privacy.
Live app page: https://apps.apple.com/app/id6818711298.

## What's New drafts

**ru-RU:** Обновили приложение после внутреннего рефакторинга. На главном экране теперь видны название ChickMark, логотип Arvectum и версия приложения. Перейти на официальный сайт ChickMark можно прямо с главного экрана. Сохранили привычный интерфейс и ваши данные.

**en-US:** Refreshed ChickMark after an internal architecture update. The Today screen now shows the ChickMark name, Arvectum branding, and your app version, with a shortcut to the official ChickMark website. Your habits and everyday workflow stay the same.

**es-ES / es-MX:** Hemos actualizado ChickMark tras una mejora interna de su arquitectura. La pantalla de Hoy ahora muestra el nombre de ChickMark, la marca Arvectum y la versión de la app, con un enlace al sitio oficial. Tus hábitos y la forma de usarlos siguen igual.

## Gates
- [x] XcodeGen project regenerated; all four targets are version 1.3.1 (6).
- [x] Official product pages RU/EN/ES respond HTTP 200.
- [x] Source-controlled link mappings and 3-language accessibility labels.
- [x] Release hygiene script green.
- [x] Final target unit/UI smoke passed: 17 unit tests + 1 UI test, including large-font simulator visual QA.
- [x] Unsigned archive audit passed: iPhone app, iOS widget, Watch app and Watch widget all 1.3.1 (6), manifest check clean.
- [ ] Non-destructive real-device iPhone/Watch upgrade + offline-sync sanity.
- [ ] Version 1.3.1 created in App Store Connect with correct localized Marketing and Support URLs.
- [ ] Review and owner approval before submission/public release.
