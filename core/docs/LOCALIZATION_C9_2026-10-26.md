# Arvectum Tools — C9, исторический срез 26.10.2026

**Следующий C10: [64 локализованных карточки и исходная редакторская сверка](EDITORIAL_ASO_C10_2026-10-26.md).**

Проверено через ARC на Mac mini, новая ветка `feature/korean-portfolio-20261026` поверх ветки PR #152. **Корейский — машинный перевод, только черновик:** ключи, форматирование, runtime и локальный Simulator QA прошли; native-speaker редактура и физическая приёмка остаются открыты.

| Продукт | Полные source-локали | KO-статус | Публичная RU версия |
| --- | ---: | --- | --- |
| Фото/PDF | 12 | Native UI PASS ранее | 1.0.2, опубликованы RU/EN |
| Pushkin | 12 | Native UI PASS ранее | 1.0.2, опубликованы RU/EN/ES/FR |
| Ухват | 12 | iPhone/Watch/widgets, 14 unit + 1 UI PASS | 1.1.1, опубликованы RU/EN/ES/FR |
| ChickMark | 12 | iPhone/Watch/widgets, 10 unit + 1 UI PASS | 1.5.1, опубликованы RU/EN/ES/FR |
| Where? | 0 | PAUSED | Не опубликовано |

Общие **12/20 Tier 1** исходных языков: en, ru, es, fr, de, it, ja, pt-BR, pt-PT, zh-Hans, zh-Hant, ko. Остаток: hi, ar, id, tr, vi, nl, pl, th. Это **не** число новых языков в App Store и не гарантия качества машинного перевода.

## Подтверждённые проверки

- [x] Структурный аудит Core PASS, 57/57 Python tests PASS. Проверено совпадение ключей/placeholder у KO Localizable, InfoPlist и AppShortcuts, переменная applicationName не потеряна.
- [x] KO Ухват — native XCUITest в AXXXL, синтетический экран без записи аудио; ChickMark — синтетическое хранилище, CloudKit отключён, UI создания привычки. Обе сборки **TEST SUCCEEDED**. Логи и XCResult: `/tmp/arvectum-korean-qa-20261026`.
- [x] Публичный App Store: 4 приложения × 12 витрин = **48 проверенных карточек**. [ASO-аудит](ASO_PUBLIC_AUDIT_2026-10-26.md), [данные](ASO_PUBLIC_STOREFRONTS_2026-10-26.json).
- [ ] Корейская редактура носителем (особенно HealthKit, разрешения, защита данных, Siri и длинные строки), Watch/iPhone/VoiceOver QA на физических устройствах и недеструктивное обновление.
- [ ] Реальный ASO: локализовать карточки Фото/PDF и ChickMark вместо русского fallback за рубежом; переснять RU Pushkin, где первый скриншот англоязычен; доработать первый экран ChickMark.
- [ ] Новые подписанные IPA/SHA-256 и конкретное разрешение владельца до любого App Store Connect upload/metadata mutation.

Порядок: сперва качество уже подготовленных языков и ASO, затем восемь остальных Tier 1; Where? и Growth Agent — пауза.
