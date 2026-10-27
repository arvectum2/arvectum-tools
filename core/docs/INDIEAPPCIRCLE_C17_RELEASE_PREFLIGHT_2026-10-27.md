# C17 — Indie App Circle: подписанные кандидаты на релиз, 27.10.2026

**Все IPA проверены и подписаны локально, но не отправлены в Apple.**

| Приложение | Apple ID | Новая версия | SHA-256 IPA | Доступных ASC локалей |
| --- | --- | --- | --- | ---: |
| Фото/PDF | 6816346084 | 1.0.4 (16) | ef7c6c32e17515db19f754d50d844ab66419feefc33e2d31dd76297d755e4c40 | 3/16 |
| Pushkin | 6817847111 | 1.0.3 (7) | 2502c204f2962eabf888df2e75675570dfb7975f00ac24a264cd2129e9dabe08 | 4/16 |
| Ухват | 6822476399 | 1.1.2 (10) | b92667e7088a645956a955d7d8ec90dce5ffd529f13c9c72cdd7a6a4c7d9c656 | 4/16 |
| ChickMark | 6818711298 | 1.5.3 (21) | cf050d6591419472a2271e11abefd2348cfdff64c21a935e34baaaf761ae8d5c | 5/16 |

IPA лежат на Mac mini: /Volumes/ArvectumSSD/Arvectum/qa/indieappcircle-release-candidates-20261027/export-PRODUCT/. Файлы не должны попадать в публичный Git.

## Изменения продукта

- ChickMark: собственные группы прямо в форме новой привычки без миграции данных.
- Pushkin: международные приложения из проверенного существующего каталога появляются первыми.
- Ухват: подсказка о расшифровке аудио на 12 языках, privacy manifests в iOS/Watch/widget/complication.
- Фото/PDF: понятная стрелка возврата после результата.
- Для 4 приложений готовы 64 What’s New, 448 нативных региональных PNG и 144 iPad маркетинговых JPEG.

## Результаты

- Все 4 Apple Distribution IPA проверены codesign --verify --deep --strict, версии вложенных bundles и их privacy manifests совпадают.
- 85 Core Python tests, новые UI тесты ChickMark и Pushkin, локализационный аудит PASS.
- ASC read-only: все текущие версии READY_FOR_SALE, а локалей там только 3–5, не 16.

## Незакрытые релизные ограничения

- [ ] P0 Photo/PDF App Privacy: YandexMobileAds / AppMetrica содержат встроенные privacy manifests с рекламными идентификаторами, coarse location и tracking. Прежде чем менять анкеты Apple, подтвердить фактическую передачу данных и текущие ответы ASC.
- [ ] Авторизованная сверка новых локалей, экранов, App Privacy и Accessibility на конкретной редактируемой версии.
- [ ] Неизменяющие личные данные физические iPhone/iPad/Watch тесты нового подписанного релиза.
- [ ] Явное разрешение владельца на каждый из 4 точных version/build/SHA256 и на согласованные ASC метаданные. General consent не является подписью release gate.
- [ ] После разрешения выставить AFTER_APPROVAL, загрузить конкретные IPA и отправить на App Review.

См. INDIEAPPCIRCLE_FEEDBACK_2026-10-27.md и INDIEAPPCIRCLE_APP_PRIVACY_AUDIT_2026-10-27.md.
