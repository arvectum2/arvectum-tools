# PUSHKIN — patch 1.0.1 (build 4), 19.10.2026

**Статус:** локальная подготовка. Публичный iPhone релиз 1.0 (первоначальный build 1, App ID 6817847111). Этот патч **не загружен** в App Store Connect.

## Источник и состав

- Release branch `release/pushkin-1.0.1-build4-20261019` от `main` (включает фиксы #68 безопасного удаления, #69 поиска micro-shortcut, #75 пошагового Shortcuts onboarding и #90 адаптивности).
- `MARKETING_VERSION=1.0.1`, `CURRENT_PROJECT_VERSION=4`, `TARGETED_DEVICE_FAMILY=1` в `pushkin/ios/project.yml`; соответствующий XcodeGen .pbxproj обновлён. **iPad пока не публиковать**: для crashfix-патча оставлено семейство iPhone, iPad/Duo ждут полной app-specific проверки.
- SwiftData schema, существующая история и пользовательские Shortcuts не очищаются; никакого сетевого сервиса или передачи содержимого уведомлений в рекламу.
- Старый локальный A5 кандидат 1.0.1(3) с тегом `pushkin-ios-v1.0.1-build3-rc1` не содержал новых A6/iPad изменений; **не подменять** его этим кандидатом.

## Доказательства и открытые проверки

- 18.10 в отдельном `ru.arvectum.tools.notify.physicalqa` на реальном iPhone 13: **17/17 unit + 3/3 UI PASS**, включая удаление только синтетических уведомлений. См. [физический протокол](PHYSICAL_IPHONE_QA_2026-10-18.md).
- На исходнике 1.0.1(4) Xcode 27.1, `build-for-testing` **PASS**, unit suite **17/17 PASS** на свежем выделенном симуляторе. Полные UI-прогоны на этом новом симуляторе **BUILD INTERRUPTED** без проваленных тестовых assert; результат **не засчитывать за PASS**. Артефакты: `/Volumes/ArvectumSSD/Arvectum/tmp/pushkin-patch-20261019`. Достоверная локальная UI база остаётся физический изолированный QA 18.10.
- [ ] Только с разрешения владельца: реальный импорт Shortcuts и enable в отдельной тестовой автоматизации, захват тестового уведомления, refresh micro и проверка покрытия. Не нарушать действующие автоматизации; 1000 пакетов != доказанная доставка 1000 источников.
- [ ] Прогон сохранности истории при **upgrade** с публичной сборки на отдельной тестовой базе; никакой reinstall с удалением пользовательского приложения.
- [x] Distribution-signed archive и IPA **1.0.1(4)** подготовлены 19.10 на Mac mini, `xcodebuild archive`/export **SUCCEEDED**; `codesign --verify --deep --strict` PASS; Apple Distribution: LLC ARVECTUM (VML75VY94V). Подтверждены `ru.arvectum.tools.notify`, версия `1.0.1`, build `4`, device family `[1]`, **1001** `.shortcut`. Source SHA `58767113fae8d14637b74246fe90dcf24cbc0c8a`; IPA SHA-256 `6f3bfdfc039b857b49d961c7e8c060c6c1f1921caa0e49c8404052d983bc5309`. Артефакты на ArvectumSSD: `releases/pushkin/patch-1.0.1-build4-20261019`. **НЕ загружено в ASC.**

## Подготовленные тексты What's New (не отправлены)

RU: Исправлена ошибка при удалении уведомлений из истории. Улучшены настройка Shortcuts и работа с локальными пакетами автоматизаций.

EN: Fixed an issue when deleting notification history. Improved Shortcuts setup and bundled automation packages.

Новая отправка в ASC — отдельное решение. После выпуска проверить фактический build и сохранность истории. [Roadmap](../ROADMAP.md).
