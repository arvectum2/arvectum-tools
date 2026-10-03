# Arvectum Growth Agent — Roadmap

**Status:** planned / build incrementally
**Created:** 2026-10-03
**Principle:** exhaust free distribution before paid acquisition.

## Mission

Build a reusable promotion system for all Arvectum Tools apps that can research demand, improve store positioning, create and distribute content, grow SEO traffic, measure results, and progressively automate execution.

The system should optimize for profitable organic growth first. Paid acquisition stays out of scope until an app demonstrates sufficient organic conversion, retention, and monetization to justify CAC.

## Portfolio growth loop

1. Ship a useful app.
2. Make the App Store page understandable in seconds.
3. Capture real search intent and user language.
4. Improve metadata, screenshots and localized positioning.
5. Publish useful content around concrete user problems.
6. Participate in relevant existing discussions.
7. Cross-promote other Arvectum utilities.
8. Measure source -> store page -> install -> activation -> retention.
9. Reallocate effort toward channels and queries that work.
10. Repeat continuously.

## Free-distribution backlog

### App Store / ASO
- [ ] Audit title, subtitle, keywords, categories and localizations for each app.
- [ ] Build keyword sets from real user language, competitor positioning and search demand.
- [ ] Rewrite first three screenshots around outcomes rather than UI.
- [ ] Add ratings prompt only after a successful user moment.
- [ ] Maintain localized metadata for priority storefronts.
- [ ] Use custom product pages where they materially match distinct user intents.
- [ ] Prepare featuring nominations for meaningful launches/updates.
- [ ] Create campaign links for every external channel.

### SEO / arvectum.com
- [ ] Create one landing page per app.
- [ ] Create intent pages answering concrete problems users search for.
- [ ] Generate structured FAQ and comparison content where useful.
- [ ] Maintain titles, descriptions, canonical URLs, sitemap and internal linking.
- [ ] Link relevant articles directly to the matching app/product page.
- [ ] Track indexed pages, search impressions, clicks and installs attributable to SEO.

### Communities
- [ ] Maintain a queue of Reddit/forum/Telegram threads where users already express the pain solved by an app.
- [ ] Draft contextual answers that solve the user's problem first and mention the app only when relevant.
- [ ] Never mass-post identical promotional text.
- [ ] Track each thread and resulting traffic separately.
- [ ] Revisit old high-intent threads when a release materially changes the answer.

### Social / short-form content
- [ ] Turn each concrete user problem into a 10–30 second demo concept.
- [ ] Reuse concepts across Shorts, Reels, TikTok, VK Clips and owned channels.
- [ ] Generate platform-specific captions instead of blind cross-posting.
- [ ] Maintain a content calendar driven by real search/community demand.
- [ ] Track content -> store traffic -> install conversion.

### Cross-promotion
- [ ] Add a restrained "Other Arvectum apps" surface where it does not harm the core flow.
- [ ] Deep-link directly to relevant store pages.
- [ ] Attribute cross-app installs separately.
- [ ] Avoid popups/interstitials solely for portfolio promotion.

## Growth Agent capability ladder

### Phase 0 — Manual operating system
Goal: standardize the work before automating it.

- [ ] Define per-app growth profile: value proposition, target jobs, languages, markets, competitors and forbidden claims.
- [ ] Define channel checklist and release-growth checklist.
- [ ] Define analytics naming and campaign-link conventions.
- [ ] Store approved brand voice, screenshots, app metadata and product facts in machine-readable form.
- [ ] Start with "Фото под размер" as the first full organic-growth test.

Exit: the same promotion workflow can be executed manually for any app without inventing the process again.

### Phase 1 — Research Agent
Read-only agent that continuously finds opportunities.

- [ ] Collect App Store metadata and competitor changes.
- [ ] Discover search queries and recurring user phrasing.
- [ ] Find relevant Reddit/forum/social discussions.
- [ ] Identify SEO content gaps.
- [ ] Detect new reviews and recurring complaints.
- [ ] Produce a prioritized opportunity queue with source evidence.
- [ ] Never publish or change public metadata.

Exit: agent reliably finds better opportunities than ad-hoc manual research.

### Phase 2 — Growth Copilot
Agent prepares complete drafts, but a human approves public changes.

- [ ] Draft App Store title/subtitle/keyword/localization changes.
- [ ] Draft screenshot copy and creative briefs.
- [ ] Draft SEO pages and updates.
- [ ] Draft Reddit/forum replies specific to each thread.
- [ ] Draft social posts and short-video scripts.
- [ ] Generate campaign links and tracking metadata.
- [ ] Explain expected metric affected by each proposed action.
- [ ] Present changes as reviewable diffs.

Exit: human work becomes mostly review/approval rather than writing/research.

### Phase 3 — Controlled Executor
Agent can execute approved work through official APIs/connectors and repository workflows.

- [ ] Update website SEO content automatically after checks.
- [ ] Open PRs for arvectum.com content/metadata changes.
- [ ] Apply approved App Store metadata changes where supported.
- [ ] Schedule approved posts to owned social accounts.
- [ ] Publish approved community replies using per-platform connectors where permitted.
- [ ] Record every external action in an immutable activity log.
- [ ] Support dry-run mode and rollback where technically possible.

Required guardrails:
- approval required for posting to third-party communities;
- approval required for material App Store positioning changes until stable;
- no duplicate/spam posting;
- per-platform rate limits;
- source-aware factuality checks;
- no fabricated reviews, testimonials, downloads or engagement.

Exit: one approval can safely execute a multi-channel campaign.

### Phase 4 — Limited Autopilot
Autonomous execution only for narrow, reversible, pre-approved classes of work.

Candidate autonomous actions:
- [ ] Refresh SEO internal links and metadata inside approved templates.
- [ ] Publish scheduled owned-channel posts from an approved content queue.
- [ ] Refresh campaign links and reporting dashboards.
- [ ] Update evergreen landing-page facts from the canonical product manifest.
- [ ] Re-run ASO/SEO audits after each release.
- [ ] Surface community opportunities but keep third-party posting human-approved by default.

Exit: routine growth maintenance runs without daily manual effort while public-risk actions remain gated.

## Proposed architecture

### Core
- Growth Orchestrator — schedules jobs and coordinates channel workers.
- Product Manifest — canonical facts for each app.
- Opportunity Store — queries, threads, ideas, experiments and status.
- Content Engine — drafts metadata, SEO and social/community copy.
- Experiment Engine — hypotheses, variants, dates and outcomes.
- Attribution Layer — campaign links and source-to-install reporting.
- Policy Layer — allowed claims, rate limits, approval rules and channel-specific constraints.
- Audit Log — every proposed and executed external action.

### Connectors
Implement only when needed and through official/supported interfaces where practical:
- App Store Connect
- GitHub / arvectum.com repository
- search analytics / site analytics
- Reddit
- owned social accounts
- Telegram/VK/other channels used by Arvectum
- App Store analytics exports

Each connector must support the minimum necessary permissions.

## Human-in-the-loop policy

The target is not "autonomous spam bot".

Default:
- research: autonomous;
- analysis/prioritization: autonomous;
- drafting: autonomous;
- changes to owned reversible content: progressively automatable;
- App Store metadata publication: approval until confidence is established;
- replies/posts in third-party communities: human approval by default;
- paid promotion: separate future decision gate, not part of this roadmap.

## Metrics

Per app:
- App Store impressions
- product-page views
- page-to-install conversion
- organic installs
- activation rate
- D1 / D7 / D30 retention where measurable
- rating and review volume
- search-query/storefront performance
- SEO impressions/clicks
- installs by campaign link
- installs from cross-promotion
- content/community referrals

Agent-level:
- opportunities found per week
- approved/rejected recommendation ratio
- time saved
- actions executed without correction
- traffic/install lift from accepted actions
- spam/moderation incidents: target zero

## First implementation target — Фото под размер

- [ ] Audit current App Store metadata and screenshots.
- [ ] Build Russian + English search-intent map.
- [ ] Create campaign-link taxonomy.
- [ ] Create/upgrade arvectum.com landing page and first SEO intent pages.
- [ ] Add a post-success rating prompt if not already present.
- [ ] Add cross-promo surface for other Arvectum apps when UX-safe.
- [ ] Start community/search opportunity queue.
- [ ] Create weekly organic-growth report.

## Product-specific growth modes

### Фото под размер
Primary motion: search intent + SEO + App Store conversion.

### PUSHKIN
Primary motion: communities and problem-aware discovery around missed/archived notifications, supported by ASO and SEO.

### ChickMark
Primary motion: memorable positioning, visual short-form content, habit-related SEO and creator/community distribution.

## Deferred: paid acquisition

Do not launch paid acquisition merely to create download volume.

Revisit only when:
- organic store-page conversion is understood;
- activation and retention are acceptable;
- monetization per active user is measured;
- a realistic CAC payback model exists;
- free channels have been systematically tested.

## Immediate next steps

1. [ ] Build the Phase 0 growth manifest schema.
2. [ ] Run the complete free-growth checklist for "Фото под размер".
3. [ ] Implement Research Agent read-only prototype.
4. [ ] Add opportunity queue + evidence + status.
5. [ ] Generate reviewable ASO/SEO/community drafts.
6. [ ] Add connectors one by one only after the manual workflow is proven.
