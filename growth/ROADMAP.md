# Arvectum Tools — Growth Roadmap

## 24.10.2026 · Публичные версии RU и приёмка Growth


- [x] Фото/PDF 1.0.2(14) — принят Apple, WAITING_FOR_REVIEW, авто-выпуск AFTER_APPROVAL. [Акт](../photo-pdf-to-size/docs/appstore/RELEASE_1_0_2_SUBMITTED_2026-10-24.md).
- [ ] Дождаться решения Apple и проверить публикацию RU-витрины.

- [x] Официальный Apple RU Lookup снова проверен по всем четырём приложениям: **Pushkin 1.0.1**, Ухват **1.1.0**, ChickMark **1.5.0**, Фото/PDF **1.0.1**; рейтинги **0/0/2/2** оценок соответственно (у последних двух 5.0/5). [Датированный baseline](docs/APP_STORE_BASELINE_2026-10-24.md).
- [x] **Pushkin уже публичен в версии 1.0.1**: историческое WAITING_FOR_REVIEW от 19.10 не следует считать текущим статусом. Точный номер внутреннего билда не подтверждён публичным API.
- [x] Apple RU Lookup подтвердил текущую категорию ChickMark **Health & Fitness** (genreId 6013). **Productivity** по-прежнему запланирована для следующей разрешённой редактируемой ASC версии.
- [x] Site [PR #15](https://github.com/arvectum2/arvectum-site/pull/15) подготовлен: predeploy/rollback checklist, GitHub CI 2/2 SUCCESS, локальный npm run verify PASS (54 indexable HTML, 0 orphans, 71 статический HTML, PHP lint); **не merged и не deployed**.
- [ ] P1: согласованный merge/deploy сайта с сохранением env/storage, резервной копией, post-deploy smoke и индексацией. Действие требует отдельного approval.
- [ ] P1: ASC Analytics 403 — получить read-only доступ; category ChickMark Productivity — только следующая разрешённая редактируемая версия. Отдельно замерить реальные РСЯ fill/выручку.

## 19.10.2026 · базовые RU рейтинги измерены, ASC Analytics заблокированы

- [x] Apple RU Lookup: Pushkin **1.0 — 0 оценок**, Ухват **1.1.0 — 0 оценок**, ChickMark **1.5.0 — 5.0/5 (2 оценки)**, Фото/PDF **1.0.1 — 5.0/5 (2 оценки)**. **Это не установки и не глобальный рейтинг.** [Акт baseline](docs/APP_STORE_BASELINE_2026-10-19.md).
- [ ] **G0 Analytics 403:** у текущего ASC ключа для всех 4 apps GET analyticsReportRequests вернул **403 FORBIDDEN_ERROR**. Impressions/downloads/views/conversion помечены **нет доступа**, не 0. Apple предписывает соответствующие API roles: Admin для первоначального запроса отчёта, Sales and Reports/Finance для чтения уже запрошенного.
- [ ] Запрашивать отдельный минимальный доступ к отчётам после одобрения владельца; существующий publishing key не менять.
- [x] SEO site PR #15 **2/2 CI SUCCESS**, но всё ещё OPEN и **не deployed**.


## 19.10.2026 · G1 CI сайта исправлен, деплой НЕ сделан

- [x] [arvectum-site PR #15](https://github.com/arvectum2/arvectum-site/pull/15) branch growth/tools-public-release-20261019 обновлена коммитом **8b5dc3f**. GitHub проверки **verify SUCCESS**, **Mirror repository SUCCESS**, PR **OPEN**.
- [x] Причина прежнего FAILURE устранена: частные /schlam HTML demo имеют robots noindex, не в sitemap; к ним неприменимы обязательные публичные canonical/favicon/placeholder требования, но сохранены тесты noindex, внутренних ресурсов и безопасности путей. На намеренно испорченных noindex, sitemap или canonical тесты **краснеют**.
- [x] Два скриншота Ухвата оптимизированы 847 728→242 068 и 273 269→163 777 байт; ограничения ресурсов соблюдены. **Локальный npm run verify PASS**: SEO/JS/граф/статика/ресурсы/PHP.
- [ ] **G1 Deploy still OPEN:** PR не merged в site main, сайт не развернут. Требуются отдельное согласование merge/deploy, post-deploy smoke, sitemap, HTTP, Search Console/Вебмастер. Нельзя считать страницу опубликованной по зелёному CI.
- [ ] **G0/2:** baseline ASO/SEO/РСЯ и категория ChickMark Productivity ещё не выполнены.


## 19.10.2026, вечер — Growth: четыре публичных продукта, Pushkin ожидает Apple

**Текущее:** публичны Pushkin 1.0, Ухват 1.1.0, ChickMark 1.5.0, Фото/PDF 1.0.1. **Pushkin 1.0.1 (5)** submitted и WAITING_FOR_REVIEW, **AFTER_APPROVAL: автопубликация**, а не ручной выпуск.

- [x] Сверены RU storefront, категория ChickMark Health & Fitness и новая Apple review-заявка Пушкина; ссылки в [матрице](../core/docs/PORTFOLIO_RECONCILIATION_2026-10-19_EVENING.md).
- [ ] **G0 P1 в общей очереди (первый приоритет внутри Growth):** снять по каждой версии реальные App Store Connect impressions, product page views, first-time downloads, conversion, рейтинг/отзывы и дату/регион, поисковые показы Google/Yandex; неизвестно ≠ нулю.
- [ ] **G1 сайт P0:** [arvectum-site PR #15](https://github.com/arvectum2/arvectum-site/pull/15) **OPEN**, проверка **verify FAILURE**; подготовленные RU/EN страницы и ссылки **не считать развернутыми**. Проверить причину CI, убрать регрессию, затем отдельное разрешение на merge/деплой.
- [ ] **G2 категория P1:** владелец выбрал ChickMark **Productivity**; пока в Apple Health & Fitness. Опубликованная READY_FOR_SALE версия дала 409 на PATCH; изменить с отдельно согласованной следующей editable версией, перепроверить storefront.
- [ ] **G3 ASO/SEO P1:** приоритет — FAQ/landing Pushkin и реальные ссылки для Ухвата, ChickMark и Фото/PDF, локализованная мета/скриншоты, Search Console, Яндекс Вебмастер. Оценивать индексацию после фактического деплоя.
- [ ] **G4 РСЯ P1:** снять живые native/banner fill, показы, выручку и влияние на UX Фото/PDF; тестовая загрузка SDK не является monetization.
- [ ] **G5 communities P2:** полезные адресные ответы на реальные запросы без искусственной накрутки установок/отзывов, массового спама, мультиаккаунтов и покупки стимулированного трафика.
- [ ] **Growth Agent:** остаётся на паузе; ни запуск автономных постов, ни расходы, ни изменение внешних карточек этим обновлением не согласованы.

**Ниже — исторические тексты до отправки Pushkin build 5; они не описывают текущие ASC-статус и тип публикации.**


## Публичные релизы и следующий выпуск · 19.10.2026

Пушкин: App Store **1.0**, обновление **1.0.1(4) WAITING_FOR_REVIEW**, выпуск после одобрения **вручную**. Ухват: **1.1.0**; ChickMark: **1.5.0**, HealthKit в `main` не означает наличие в публичном бинарнике. Фото/PDF: **1.0.1**. Сайт: PR #15 ожидает исправления существовавших проблем `/schlam` до deploy. Категория ChickMark Productivity потребует новой редактируемой версии ASC.


## Growth · Релизы и ASO, 19.10.2026

- [x] Проверены публичные версии Apple RU: Pushkin 1.0, Ухват 1.1.0, ChickMark 1.5.0 и Фото/PDF 1.0.1.
- [x] Подготовлена новая RU/EN landing page Пушкина + прямые ссылки App Store на опубликованный Ухват + ссылка из Tools hub: [arvectum-site PR #15](https://github.com/arvectum2/arvectum-site/pull/15). SEO 54 страницы/0 orphans PASS; **не развернуто на хостинге**. PR verify красный только из-за ранее существовавших static ошибок страниц `/schlam/`, assets What также превышают старые лимиты; не называть общую проверку зелёной.
- [ ] **Категория ChickMark:** согласовано **Productivity** вместо Health & Fitness, но ASC API PATCH `/v1/appInfos/{id}` на опубликованном `READY_FOR_SALE` вернул **409 ENTITY_ERROR.RELATIONSHIP.INVALID_STATE**. Категория **не изменилась**; перенести в следующий редактируемый App Store version, не создавать отдельный бинарник лишь ради метаданных. [Краткий протокол](docs/CHICKMARK_CATEGORY_ASC_2026-10-19.md).


## Публичные релизы: новая база ASO · 19.10.2026

- [x] **G19-0 · Доступность:** Pushkin **1.0**, Ухват **1.1.0** и ChickMark **1.5.0** доступны в Apple RU storefront; Фото/PDF **1.0.1**. [Read-only реестр](../core/docs/PUBLIC_RELEASE_RECONCILIATION_2026-10-19.md). Старая фраза «Pushkin после решения Apple» ниже — исторический план.
- [ ] **G19-1 · Измерить эффект:** зафиксировать dated App Store Connect impressions, views, first-time downloads, конверсию, реальные ratings/отзывы и регион; отсутствие данных ≠ 0. Стартовая точка после публикации Pushkin, сравнение до/после по ChickMark/Ухвату.
- [ ] **G19-2 · Карточка ChickMark:** категория RU storefront до сих пор **Здоровье и фитнес / Health & Fitness**, а владелец выбрал **Productivity**. Подготовить/внести корректировку в ASC после проверки ограничений Apple и проверить публичную витрину; не считать смену уже состоявшейся.
- [ ] **G19-3 · ASO/SEO:** проверить RU/EN страницы и продуктовые landing pages, ссылки на новый Pushkin, первые скриншоты и ключевые слова. Качество конверсии и отзывы важнее искусственных скачиваний.
- [ ] **G19-4 · РСЯ:** после релизов проверить реальные paid impressions/fill/revenue и удобство нативного блока на устройстве; показатели SDK test/demo не засчитывать как доход.



## Контрольная точка · 18.10.2026 — активная очередь
**Режим:** organic-first, только измеримые гипотезы; [Growth Agent](agent/ROADMAP.md) остаётся на паузе до решения владельца.

- [ ] **G18-0 · База метрик:** датированные App Store Connect impressions, page views, first-time downloads, conversion, ratings и retention proxies по опубликованным версиям; отдельно РСЯ fill/impressions/доход по блокам, GSC/Яндекс Вебмастер. Не превращать отсутствие данных в нули.
- [ ] **G18-1 · ASO и SEO:** RU/EN/ES metadata/первые три скриншота/ссылки поддержки, реальные landing pages arvectum.com, индексирование, внутренние ссылки; по приоритету — опубликованные Фото/PDF, ChickMark, Ухват. Pushkin — после решения Apple, Where? не рекламировать как готовый.
- [ ] **G18-2 · Communities:** найти действительные вопросы пользователей (в т.ч. Reddit по истории уведомлений iPhone), подготовить полезные неоднотипные ответы и измерять переходы → активацию; без массового автоматического размещения.
- [ ] **G18-3 · РСЯ и кросс-промо:** сравнить фактический доход с удержанием, оценками, заполнением и не перекрываемым основным действием. Изменение рекламного UI остаётся в app-roadmap.
- [ ] **G18-4 · Гипотеза сообщества разработчиков (17.10):** исследовать добровольный обмен вниманием, полезными отзывами и качественными тестами приложений (репутация/кредиты). Отдельно исследовать коммерческую платформу привлечения пользователей. Перед проектированием денежных выплат/вознаграждений за установку — проверить правила Apple/Google, антифрод, мультиаккаунты, реальную активацию/удержание и unit economics; не планировать искусственную накрутку рейтинга как утверждённую механику.
- [ ] **G18-5 · Growth Agent:** сперва подтверждённые источники/метрики и read-only research; публичные посты, смена метаданных и платные действия только с отдельным approval.

**Статусы Apple по состоянию на имеющиеся доказательства:** [портфельный реестр](../core/PORTFOLIO.md).


**Очередность:** [единый план работ](../core/EXECUTION_PLAN.md). B0 (проверяемая аналитика) выполняется параллельно с безопасностью/релизами приложений; Growth Agent активировать поэтапно после качественного data baseline.

## Growth checkpoint — 2026-10-15
- [x] Reconciled App Store distribution baselines in
  [Portfolio registry](../core/PORTFOLIO.md): Фото/PDF iOS 1.0.1
  publicly released (owner confirmed 2026-10-15), Ухват 1.0.0
  public, ChickMark 1.4.0 public. This does not establish revenue,
  conversion, or retention analytics.
- [ ] G0: establish a dated per-app App Store Connect baseline (impressions, page views, installs, conversion, retention proxies, ratings), RСЯ fill/revenue and search indexing; missing data must not be called zero.
- [ ] G1: compare published builds with RU/EN/ES storefront listings, screenshots, support/marketing URLs and SEO product pages.
- [ ] G2: track search-led discovery via the current Arvectum Tools website hub and individual product pages with Search Console and Yandex Webmaster.
- [ ] G3: run small hypothesis-driven keyword, creative and community outreach experiments with per-app measures, costs and outcomes.
- [ ] G4: assess cross-promotion and advertising on both revenue and product retention/reviews.
- [ ] Growth Agent research and automated monitoring remain paused until a trustworthy data baseline and concrete decision; no external posts without explicit approval.


**Updated:** 2026-10-15. **Owner:** portfolio distribution, market research, ASO, SEO, acquisition, conversion, retention measurement and monetization strategy.

## Current / verify
- [ ] Audit per-app App Store metadata and screenshot conversion with actual listing data.
- [ ] Validate current SEO landing pages, Google Search Console and Yandex Webmaster indexing.
- [ ] Establish truthful baseline of installs, conversion, retention and revenue by released app.
- [ ] Verify realized RСЯ revenue and placement performance for Фото и PDF под размер.

## Experiments
- [ ] Keep a centralized experiment register: hypothesis, app, cohort, channel, metric, result.
- [ ] Test app-specific search keywords, locales, creatives and targeted communities.
- [ ] Cross-promote the portfolio without disrupting utility flows.
- [ ] Evaluate ads by revenue **and** app-retention/review impact; report per-app metrics.
- [ ] Build Growth Agent research/monitoring only with verifiable data and approval for external posts.

## Boundaries
- No app features, crash fixes, image/PDF logic or watchOS capture tickets here.
- Marketing assets and store conversion hypotheses live here; implementation of specific in-app UI/SDK lives with the app.
- Historic app-specific marketing reports remain as evidence in their original app docs.
- Cross-link dependencies; never duplicate owners' checkbox states.

[Portfolio index](../core/PORTFOLIO.md) · [Core principles](../core/CORE_PRINCIPLES.md).
