# Release checklist — «Фото под размер» → RuStore

## Product freeze
- [x] По весу
- [x] По размеру
- [x] На паспорт
- [x] Новых функций до первого рыночного теста не добавлять
- [x] Первая публичная версия без рекламы и аналитики

## Identity
- [x] Название в приложении: «Фото под размер»
- [x] Название на витрине: «Фото под размер»
- [x] Новая продуктовая иконка: портрет в рамке + стрелки внутрь
- [x] Arvectum wordmark в шапке
- [x] Arvectum.com в футере

## Android
- [ ] Финальный visual QA на реальном телефоне
- [x] assembleRelease
- [ ] lintRelease
- [x] unit tests
- [x] проверить package: ru.arvectum.tools.tosize
- [x] проверить minSdk / targetSdk — 26 / 37
- [x] проверить отсутствие INTERNET
- [x] проверить список permissions — только служебный DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
- [x] проверить versionCode/versionName — 5 / 0.4.0
- [x] подписать production release постоянным ключом
- [ ] сделать резервную копию signing key

## RuStore card
- [x] Название
- [x] Категория: Полезные инструменты
- [x] Краткое описание
- [x] Подробное описание
- [x] Что нового
- [x] Комментарий модератору
- [x] Сайт разработчика
- [x] Иконка 512×512
- [ ] Минимум 3 финальных скриншота 9:16 с реального/эмулированного приложения
- [ ] Проверить каждый скриншот: ≤5 МБ, одна ориентация

## Privacy / data
- [x] PRIVACY.md
- [x] Декларация: данные не собираются и не передаются
- [x] Реклама отсутствует
- [x] Аналитика отсутствует
- [x] Публичная политика: https://github.com/arvectum2/arvectum-tools/blob/main/PRIVACY.md (рабочая URL; branded page на arvectum.com уже подготовлена в landing repo и ждёт деплоя)

## Console
- [ ] Добавить приложение в RuStore Console владельцем компании
- [ ] Загрузить подписанный APK или AAB
- [ ] Проверить автоматически определённые permissions
- [ ] Заполнить безопасность данных
- [ ] Загрузить иконку и скриншоты
- [ ] Отправить на модерацию

## Signing certificate

SHA-256: B6:E3:1E:F5:AE:30:AC:C7:1A:9A:7A:39:6B:D7:E7:18:EB:C7:B6:16:38:FC:A2:5F:E6:8B:2C:70:C3:E5:19:42

Production keystore is stored outside git on the Mac mini at ~/Arvectum/signing/photo-pod-razmer/photo-pod-razmer-release.jks. Back it up before the first store publication; future updates must use the same key.
