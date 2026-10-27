# 26.10.2026 — Signed App Store IPA preflight (ARC, Mac mini)

Источник кода: `feature/portfolio-roadmaps-zh-hant-20261025` at **`471c5ac1a0a16e1e4ebaf0cb901407d914bdfccc`**. Xcode 27.1, Mac mini. Выполнены четыре Release iOS Simulator builds, четыре локальных iOS device `.xcarchive`, четыре App Store **IPA exports**, **4/4 PASS**. Перепроверена подпись всех четырёх IPA через macOS `ditto -x -k`, затем `codesign --verify --deep --strict` и `codesign -dv`. Authority = **Apple Distribution: LLC ARVECTUM (VML75VY94V)** для всех. Экспорт/подпись выполнялись только на Mac mini; никакой App Store Connect/TestFlight upload, отправки на App Review, изменения карточек Apple или управления профилями через портал не было.

Каталог QA на Mac mini: `/Volumes/ArvectumSSD/Arvectum/qa/ios-signed-archive-c63-v2-20261026/`

| App | CFBundleVersion (IPA) | Size (bytes) | SHA-256 | Relative IPA |
| --- | --- | ---: | --- | --- |
| Фото/PDF | 1.0.1 (13) | 5,474,279 | `ca2e8b777778f9a61bb38ff7e1b25908c0a3edd4dc6142a5e049aaf7863df743` | `ipa-photo/PhotoPodRazmer.ipa` |
| Pushkin | 1.0.2 (6) | 15,091,163 | `8d009dc7044da67f9dfb2bc5550b9d4ccd3547d996b419d91e60a16dea4efdc9` | `ipa-pushkin/ArvectumNotify.ipa` |
| Ухват | 1.1.1 (9) | 4,031,315 | `6529a4a004c07538a7d79d2bb22cb09dd807bd2c7f0710cfdda3a26833b518d5` | `ipa-uhvat/WhatIOS.ipa` |
| ChickMark | 1.5.1 (19) | 8,349,195 | `74f6b57dabf93c58780dd18a35b4e8d43c17daa21fdf9cc86efa68f7991c68f6` | `ipa-chickmark/HabitsByArvectum.ipa` |

Использованы существующие профили (31 локальный профиль найден): Photo и Pushkin — ручной экспорт с профилями App Store; Ухват и ChickMark — автоматический выбор **уже установленных Xcode-managed Store-профилей** для main/Watch/widget. Техническая ошибка первого ручного экспорта `Xcode managed profile requires automatic` исправлена. `-allowProvisioningUpdates` не применялся. Исходный CI/root зафиксирован в QA логах. Папки `ipa-photo`, `ipa-pushkin`, `ipa-uhvat`, `ipa-chickmark` содержат итоговые артефакты.

## Важное ограничение

Все четыре IPA **только подписанные QA-артефакты, не готовые к новой публикации**: Фото/PDF в архиве имеет `1.0.1 (13)`, хотя в RU App Store уже опубликована `1.0.2`; другие имеют версии/билды, соответствующие опубликованным `1.0.2 (6)`, `1.1.1 (9)`, `1.5.1 (19)` (build public lookup не показывает, совпадение версий и прежних внутренних значений). Для следующего релиза нужны согласованные **новые версии и build numbers**, затем повторная подпись/новые SHA-256; ни один из приведённых файлов не отправлять в ASC.

Отдельно остаются P0: native-speaker proofread языков, физическая Watch/iPhone/VoiceOver, фоновые очереди и разрешения, полная GitHub UI-матрица, защита существующих пользовательских данных. Согласно `AGENTS.md`, upload/review/live metadata требуют **явного подтверждения конкретного номера версии/build/hash в текущем диалоге**. Для публикации после разрешения — `AFTER_APPROVAL`.

[Native UI QA](IOS_PTPT_KO_NATIVE_QA_2026-10-26.md) · [Apple public lookup](APPLE_PUBLIC_LOOKUP_2026-10-26.md).
