# QA 26.10.2026 — zh-Hant native UI + pt-PT редактура

Ветка `feature/portfolio-roadmaps-zh-hant-20261025`, Xcode 27.1, временный изолированный iPhone 18 Pro Simulator iOS 27.0 (после QA удалён).

- [x] **6/6 Native XCTest PASS:** Фото/PDF 3/3, Pushkin 1/1, Ухват 1/1, ChickMark 1/1. Все четыре `xcodebuild test` завершились кодом 0, четыре XCResult сохранены.
- [x] Логи/результаты: `/Volumes/ArvectumSSD/Arvectum/qa/ios-zh-hant-native-20261026/{photo,pushkin,what,chickmark}.{log,xcresult}` и `status.log`.
- [x] PT-PT исправления во всех 4 приложениях и Watch-ресурсах: согласования, резервное копирование, восстановление, разрешения и региональные слова; 16 форм registo, 2 apenas и 2 ligados.
- [x] Core Python **62/62 PASS**, locale parity PASS, plutil PT-PT PASS. Машинная выборка: 182 файла, 9484 строковых значения вне EN, 31 похожее на английский значение требует классификации; PT-PT сканер: 0 оставшихся характерных региональных ошибок.
- [ ] Нет проверки носителями, полного реального VoiceOver/Watch/widgets/consent и physical upgrade. Korean только 2 из 4 продуктов. GitHub manual CI матрица ещё не запускалась.
- [ ] Новые signed IPA: прежний Photo/PDF архив подписан **до нынешних изменений**, три других app archives заблокированы provisioning profiles для app/widgets/Watch.
- [ ] Проверить Apple Review/public статусы read-only: прежний статус датирован 24.10, он не является сегодняшним наблюдением.

Внешних Apple загрузок, публикаций, редактирования live карточек и пользовательских данных не было. Для каждого Apple upload нужен отдельный approval точной версии/build/hash по AGENTS.md; после одобрения использовать AFTER_APPROVAL.
