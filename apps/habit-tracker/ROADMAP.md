# Habit Tracker — Roadmap

**Status:** BACKLOG / discovery later.

## Product concept
Product idea: a simple, free and convenient alternative to HabitKit Pro.

Product principle: take the genuinely useful and convenient habit-tracking mechanics, remove unnecessary complexity and feature clutter, and keep the core flow extremely lightweight.

Initial product constraints:
- [ ] Free core product; no paywall around basic habit tracking.
- [ ] Minimal UX: adding and marking a habit should take as few actions as possible.
- [ ] Fast habit creation with sensible defaults and no mandatory setup wizard.
- [ ] Clear, visual progress/history at a glance.
- [ ] No feature accumulation unless it materially improves the core user job.
- [ ] Before implementation, decompose HabitKit Pro: useful mechanics, paid mechanics, recurring user complaints, and removable complexity.
- [ ] Use the research to define a deliberately smaller MVP rather than cloning the full product.

Working formula: **«всё удобное из HabitKit Pro — без лишнего»**.


#### Monetization — advertising, delayed and non-intrusive
**Scope:** this policy applies **only to the Habit tracker** and is not a global Arvectum Tools rule.

**Decision:** all core functionality remains free; monetization is advertising-only.

Ad UX principles:
- no App Open Ads or interstitials in the core flow;
- no ads during onboarding, habit creation/editing, check-off actions, widgets, notifications, or settings;
- Today screen: one small adaptive sticky banner in a dedicated bottom area; it must never cover controls or appear between habits;
- Progress / Statistics: at most one native ad card, placed after useful content;
- banner video is disabled by default; native video may be tested later;
- ads are not shown immediately after installation.

**Delayed activation rule (initial hypothesis):**
- store install date, cold-launch count, and successful check-off count locally;
- ads become eligible only after **both**:
  - at least **3 full days** have passed since first launch; and
  - the user has completed at least **5 cold launches**;
- additionally require at least **3 successful habit check-offs** before the first ad impression;
- if the threshold is not met, the app remains fully ad-free;
- never backfill or compensate for missed impressions;
- after activation, preserve the same calm placement and frequency rules.

Experiment candidates after launch:
- cohort A: activation at day 3 + 5 launches;
- cohort B: activation at day 5 + 7 launches;
- compare D7/D30 retention, ad revenue per DAU, session-abandon rate after first ad, and review sentiment.

## Before development

1. Decompose HabitKit Pro into user jobs and interaction mechanics.
2. Separate essential mechanics from optional complexity.
3. Define an intentionally smaller MVP.
4. Validate onboarding and daily check-in tap count.
5. Validate the delayed-ad thresholds only after the core habit loop is proven.
