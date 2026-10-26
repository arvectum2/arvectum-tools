# Arvectum Tools — исторический срез C8 на 26.10.2026

**Более актуальный C9: [12/20 Tier 1, корейский 4/4](LOCALIZATION_C9_2026-10-26.md).** Данные ниже сохраняют историю до добавления KO в Ухват и ChickMark.

Источник: рабочая ветка `feature/review-ux-photo-chickmark-20261026` (срез исходного кода `84af001`, документация обновлена последующими коммитами) на Mac mini через ARC. Это **готовность исходников**, а не число языков в опубликованных App Store версиях.

## Матрица

| Приложение | Полные source-каталоги | KO | Что не готово |
|---|---|---|---|
| Фото/PDF | 12 языков, 159 UI-ключей | iPhone draft, native UI PASS | Physical Files/Photos/ad fill, privacy/visa editorial |
| Pushkin | 12 языков, 151 UI-ключ | iPhone draft, native UI PASS | Physical Shortcuts/история, editorial |
| Ухват | 11 языков, 231 iPhone + Watch/widgets | Нет | KO all targets, Watch ACK/background/recordings |
| ChickMark | 11 языков, 311 iPhone + Watch/widgets | Нет | KO all targets, HealthKit/CloudKit/Watch |
| Where? | 0, PAUSED | Нет | Offline MVP по отдельному решению |

Общие 11 языков: `en, ru, es, fr, de, pt-BR, it, ja, zh-Hans, zh-Hant, pt-PT`. `pt-PT` — редакторский черновик, несмотря на полную структуру ключей. KO доступен только в **2/4 приложений** (Фото/PDF и Pushkin): **11/20 языков Tier 1 во всех 4 приложениях**, 12/20 в двух. Остались KO в Ухвате и ChickMark, а также `hi, ar, id, tr, vi, nl, pl, th`. Манифест Core содержит 50 целевых языков и не содержит исключённый ранее язык.

Android Фото/PDF: English + восемь draft-каталогов (`ru/de/es/fr/it/nl/pl/pt-BR`). Расширение Android отложено до iOS QA.

## Проверки 26.10

- [x] `localization_portfolio.py --report`: структура, ключи и placeholders PASS; каталоги 12/12/11/11 по приложениям.
- [x] 56/56 профильных `test_localization_portfolio.py` PASS.
- [x] Предыдущая native QA: pt-PT 6/6, ko 4/4, zh-Hant 6/6, 11-язычная manual UI matrix — 4/4 jobs SUCCESS.
- [x] GitHub PR [#151](https://github.com/arvectum2/arvectum-tools/pull/151): **21/21 CI checks SUCCESS**, PR OPEN. Предыдущий кодовый commit PR [#152](https://github.com/arvectum2/arvectum-tools/pull/152) (`84af001`) успешно проходил CI; оба PR OPEN.
- [ ] Последний commit PR #152 после правок документации проходит **новый** CI: на контрольной проверке часть jobs IN_PROGRESS/QUEUED; не считать этот прогон завершённым до окончательного зелёного статуса.
- [x] ASO Фото/PDF: **20 draft metadata локалей**, в `metadata-2026-10-26-review.json` есть тайский `th`; эти метаданные не означают поддержку языка интерфейсом.

## Публичные версии и RC

| Приложение | Публичная RU версия (Apple Lookup 26.10) | Следующий RC |
|---|---|---|
| Фото/PDF | 1.0.2 | 1.0.3 (15), готовится новый подписанный IPA |
| Pushkin | 1.0.2 | Новый build/версия не утверждены |
| Ухват | 1.1.1 | Новый build/версия не утверждены |
| ChickMark | 1.5.1 (Productivity) | 1.5.2 (20), готовится новый подписанный IPA |

4/4 ранее подписанных IPA — старые QA-артефакты, **не** готовые к новой загрузке. Требуются новый код/версия, архивирование, подпись, SHA-256, физические тесты и явное per-release approval.

**Privacy-коррекция Фото/PDF:** после commit `cd8ebc3` код снова показывает выбор рекламного согласия. `YandexAds.setUserConsent(false)` до разрешения, геолокация выключена, при положительном выборе может появиться ATT. Утверждение «ATT полностью убран и согласие всегда false» **устарело**. AppMetricaAdSupport по-прежнему заявляет tracking=true; live App Privacy без review не менять.

## Следующие задачи

- [ ] P0: редактура носителями `pt-PT/zh-Hant/ko`, privacy/permissions/ASO и физическая QA без изменения личных HealthKit/Shortcuts/записей.
- [ ] P0: подписать новые RC, проверить CI/SHA-256; решение о merge #151 перед #152 принять отдельно от внешнего релиза.
- [ ] P1: завершить KO в Ухвате и ChickMark (iPhone/Watch/widgets), потом остальные восемь Tier 1 с native QA.
- [ ] P1: финальные ASO/скриншоты с соответствующих подписанных сборок, проверить реальные storefront languages.
- [ ] PAUSED: Where? MVP/PAO; Growth Agent, site deploy и Android языковое расширение.

**Никаких** изменений App Store Connect, TestFlight, App Review, опубликованных карточек или сайта без отдельного явного разрешения на конкретный релиз/изменение.
