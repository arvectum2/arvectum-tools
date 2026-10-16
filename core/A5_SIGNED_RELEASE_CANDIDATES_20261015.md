# A5 — независимые подписанные релизные кандидаты, 2026-10-15

**Статус:** 4/4 локальных distribution-signed `.ipa` экспортированы на ArvectumSSD, 4/4 проверены по bundle ID, версии, номеру сборки, вложенным подписанным компонентам и `codesign --verify --deep --strict`. **Ни один новый A5 IPA не загружен и не отправлен на App Review; ни одно приложение на пользовательских устройствах не обновлено.** Источник — актуальный `origin/main` на момент отсечения `657ce0d` плюс изменение только версии/build в изолированных release branches.

## Сборки и происхождение

| Приложение | A5 кандидат | Зафиксированный Git SHA / RC tag | SHA-256 экспортированной IPA |
| --- | --- | --- | --- |
| Pushkin | **1.0.1 (3)** | `c3b0910`, `pushkin-ios-v1.0.1-build3-rc1` | `024939f90c7b9f9452f3e9279e2dca72bb5402b6c9fd44b109e354d43bb49f8b` |
| Ухват | **1.0.2 (7)** | `fecedac`, `uhvat-ios-v1.0.2-build7-rc1` | `0f89bd6aab1756838b701e48941eac93a009a9f4bfe29ea94f158dd707f0ab82` |
| ChickMark | **1.4.2 (16)** | `2ef6e53`, `chickmark-ios-v1.4.2-build16-rc1` | `f94370fa7994d4149f0e751031ba54a2b1fd79950b84a346be4aaec6ba14699a` |
| Фото/PDF | **1.0.2 (14)** | `09cc263`, `photo-size-ios-v1.0.2-build14-rc1` | `e886c0d97c1670a8372a8d6b8840ed3cd1e08c1c22994bc4f338cf2ec6d18676` |

**Канонические branch refs:** `release/pushkin-1.0.1-build3-a5-20261015`, `release/what-1.0.2-build7-a5-20261015`, `release/chickmark-1.4.2-build16-a5-20261015`, `release/photo-size-1.0.2-build14-a5-20261015`. Кандидаты не сливаются в `main`: версии каждого приложения независимы. Все четыре release-branch refs, RC tags и `main` независимо сверены по GitHub/GitVerse SHA после запуска зеркалирования. Отдельные `rc1`-теги обозначают **source freeze для подписанного кандидата, не публичный релиз**.

**Артефакты, только локально на Mac mini:** `/Volumes/ArvectumSSD/Arvectum/releases/a5-20261015/`. Подкаталоги `pushkin-1.0.1-build3`, `what`, `chickmark`, `photo-1.0.2-build14` содержат `.xcarchive`, `export/*.ipa`, журналы сборки/экспорта и (где применимо) `DerivedData`. Машинный результат проверок: `A5_SIGNED_AUDIT.json` и `A5_EXPORTED_IPA_SIGNING_AUDIT.json` в том же каталоге; [проверяемая обезличенная Git-аттестация](A5_SIGNED_RELEASE_ATTESTATION_20261015.json). Для **экспортированных IPA** проверены `codesign --verify --strict` через macOS `ditto`, Team ID и `get-task-allow=false` для каждого app/appex. IPA **не класть в публичный GitHub/GitVerse**.

**Единственные основные RC1 артефакты** — ровно четыре SHA-256 в таблице выше, на них ссылаются аннотированные RC-теги. В каталоге есть также повторные корректно подписанные экспорты из тех же исходников: `what-1.0.2-build7/export/WhatIOS.ipa` (SHA-256 `978e49a845db6311e81ba9d0d4bb2be18d9dd9a55ef9fdd84310b1c56db0fce5`) и `chickmark-1.4.2-build16/export/HabitsByArvectum.ipa` (SHA-256 `02dea1db1f58b9eb519ecf42f7bc4ac8989ef5ff4d789a01fa2a5031cc6d107b`). Их подписи проверены, но это **альтернативные экспорты, не выбранные для возможной A5 загрузки**. Хеши не взаимозаменяемы; если в будущем выбран другой файл, потребуется отдельное обновление provenance-реестра и контрольного тега.

**Проверка вложений:** Pushkin — 1 подписанный iPhone bundle, 1001 встроенный shortcut; Ухват — 4 подписанных bundle (iPhone + Watch + complication + widget); ChickMark — 4 (iPhone + Watch и widgets); Фото/PDF — 1 iPhone bundle. У всех вложенных целей те же marketing/build; корпус RuWordNet не обнаружен в архивных компонентах. Экспорт Apple Distribution, команда `codesign` PASS. Это **не** является утверждением о побайтовой воспроизводимости IPA из Git с идентичным сертификатом/профилем/временем подписи.

## App Store Connect, read-only lookup 2026-10-15

- **ChickMark 1.4.1 (15) READY_FOR_SALE**; новая 1.4.2 (16) пока локальный A5 кандидат. Старый статус IN_REVIEW более не актуален.
- **Фото/PDF 1.0.1 (13) READY_FOR_SALE**; исправление вращения страниц только в будущем кандидате 1.0.2 (14).
- **Ухват 1.0.0 (5) READY_FOR_SALE**, 1.0.1 (6) WAITING_FOR_REVIEW; новый 1.0.2 (7) не загружен.
- **Pushkin 1.0.0 (1) WAITING_FOR_REVIEW**, ASC также содержит обработанный build 2 той же marketing version; новый 1.0.1 (3) не загружен.

## Код, тесты и оставшиеся релизные ворота

| Приложение | Патч | Release-branch CI | Что блокирует App Store upload/submission |
| --- | --- | --- | --- |
| Pushkin | [#68](https://github.com/arvectum2/arvectum-tools/pull/68) безопасное удаление; [#69](https://github.com/arvectum2/arvectum-tools/pull/69) локальные Shortcuts | [CI 38786481028](https://github.com/arvectum2/arvectum-tools/actions/runs/38786481028) **SUCCESS** | Решение Apple по первой версии, физический недеструктивный тест удаления и захвата Shortcuts |
| Ухват | [#70](https://github.com/arvectum2/arvectum-tools/pull/70) надёжная Watch-очередь, ACK и AAC | [CI 38786482518](https://github.com/arvectum2/arvectum-tools/actions/runs/38786482518) **SUCCESS** | Решение Apple по 1.0.1, реальная Watch↔iPhone проверка 1-tap/Digital Crown/offline/duplicate |
| ChickMark | [#71](https://github.com/arvectum2/arvectum-tools/pull/71) Cloud KVS + native ads post-build15 | [CI 38786487880](https://github.com/arvectum2/arvectum-tools/actions/runs/38786487880) **SUCCESS**: unit, UI-smoke и archive | Второе CloudKit-устройство, владелец подтверждает HealthKit revoke/regrant, физический VoiceOver, настоящие показы Native РСЯ |
| Фото/PDF | [#72](https://github.com/arvectum2/arvectum-tools/pull/72) ориентация PDF 90/270 | **Initial [CI 38786493214](https://github.com/arvectum2/arvectum-tools/actions/runs/38786493214) FAIL** (clean iOS Files UI, timeout); [PR #74](https://github.com/arvectum2/arvectum-tools/pull/74) merged, **two [PR/push CI runs](https://github.com/arvectum2/arvectum-tools/actions/runs/38793584633) [SUCCESS](https://github.com/arvectum2/arvectum-tools/actions/runs/38793592199)** with all 31 unit + 5 app-owned UI checks. [Release-branch CI 38795581835](https://github.com/arvectum2/arvectum-tools/actions/runs/38795581835) underway | Физические Files/Photos/Share/экспорт, ATT/consent и РСЯ [#73](https://github.com/arvectum2/arvectum-tools/issues/73) |

Предыдущие A1–A4 полные локальные тесты прошли. Новые signed RC не заменяют физические тесты; для неподтверждённых сценариев не указывать PASS. **Ни одна релизная дата Apple не обещается.**

## Выпуск только после этих ворот

1. Подтвердить все release-branch CI и GitVerse sha/tag. Привязать QA-кейсы к signed RC; не изменять бинарник после принятия.
2. Закрыть соответствующие физические и внешние приёмочные ворота каждого приложения без сброса реальных данных/разрешений.
3. Если исправления потребуют изменения кода, **пересобрать новый RC** и обновить SHA/build (при загрузке использовать новый уникальный build, если прежний уже был загружен).
4. Только затем подготовить ASC новую App Store Version, согласовать локализованные What's New, загрузить проверенную IPA, привязать build и отправить на review. Для Pushkin и Ухвата дождаться решения о предыдущей версии либо корректно спланировать смену ревью.
5. После публичного статуса READY_FOR_SALE проверить витрину и фактические ad impressions/данные распространения. Не заявлять фиксы публичными заранее.

**Where?** остаётся PAUSED.


## Additional signed-export reconciliation (2026-10-15)

Two independently exported and successfully verified QA copies also exist under the same SSD release root. The Uhvat copy is at `what-1.0.2-build7/export/WhatIOS.ipa` (SHA-256 `978e49a845db6311e81ba9d0d4bb2be18d9dd9a55ef9fdd84310b1c56db0fce5`); the ChickMark copy is at `chickmark-1.4.2-build16/export/HabitsByArvectum.ipa` (SHA-256 `02dea1db1f58b9eb519ecf42f7bc4ac8989ef5ff4d789a01fa2a5031cc6d107b`). Both copies passed the version/build, all four App Store profiles with `get-task-allow=false`, and `codesign --verify --strict` checks. Each separate export has its own SHA-256; their exact receipt files are preserved in their release branches.

**Only the canonical IPA paths and SHA-256 entries in `A5_SIGNED_AUDIT.json` are selected for any future App Store upload.** The additional QA copies must not be accidentally substituted or uploaded. Both export sets reference the same per-app source RC commit, but independent signing/export is not a bitwise-reproducibility claim.

**Public machine-readable attestation:** [A5_SIGNED_RELEASE_ATTESTATION_20261015.json](A5_SIGNED_RELEASE_ATTESTATION_20261015.json) contains the canonical RC source tags, signing/entitlement checks and all four SHA-256 values.
