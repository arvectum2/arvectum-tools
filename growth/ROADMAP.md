# Arvectum Tools — Growth Roadmap

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
