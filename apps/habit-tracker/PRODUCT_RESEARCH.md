# Habits by Arvectum — Product research

Updated: 2026-10-01

## Product thesis

Habits should remain easier to maintain than the habits themselves.

The default loop stays:

1. Create a habit in seconds.
2. See only what matters today.
3. Check it off with one tap.
4. See useful progress immediately.
5. Let sync, widgets and Watch remove friction rather than add setup.

## Broader competitor / user review

Products reviewed: HabitKit, Streaks, Habitify, Everyday, Way of Life,
Loop Habit Tracker, Strides, Productive, Finch and current App Store / habit-tracker
user discussions. The review is intentionally cross-product: repeated user value
matters more than copying any one competitor.

### Repeated things users praise

#### 1. A tracker that gets out of the way

Streaks and Way of Life are repeatedly praised for visual simplicity and low
daily interaction cost. A recurring complaint about alternatives is that the
tracker itself becomes another productivity system that needs maintenance.

**Take:** Habits by Arvectum keeps the default interaction surface deliberately
small.

#### 2. Show only what is due now

Users explicitly ask for habits that are not due today to disappear rather than
remain as disabled clutter.

**Take:** Today remains the primary screen and contains only due habits.

#### 3. Progress should be readable at a glance

Users praise simple green/completed states, chains, grids, streak numbers and
widgets because they answer "how am I doing?" without requiring analysis.

**Take:** keep a small visual history, current streak, best streak and completion
rate. Avoid a statistics dashboard in the core loop.

#### 4. A missed exceptional day should not erase motivation

Way of Life users specifically value the three-state model: done / not done /
skip. Finch users also praise a lower-guilt approach, while users criticize
systems where a single miss invalidates months of accumulated progress.

**Take:** add a neutral Skip state. Skip neither grows nor breaks the streak and
is excluded from completion-rate denominator.

#### 5. Apple Watch and widgets are high-value when they remove friction

Streaks is repeatedly praised for Apple Watch integration and widgets. Habitify
users describe Watch support and complications as a major selection criterion.

**Take:** Watch is required before public release, not an optional later extra.
The Watch UI is Today-first with one-tap completion and overall progress.

#### 6. Sync quality is part of the product, not infrastructure detail

Habitify reviews show users leaving otherwise attractive apps when Watch and
iPhone states diverge or require relaunching to refresh.

**Take:** synchronization must be live when devices are reachable, durable when
offline, idempotent and self-reconciling after reconnection.

#### 7. Flexible frequency matters, but not on day one

Streaks/Strides-style goals such as N times per week are useful for exercise and
other non-daily habits. However, exposing them in the default creation flow adds
meaningful complexity.

**Take:** support fixed weekdays now. Add N/week later behind progressive
disclosure.

#### 8. Small completion feedback is valuable

Productive users praise satisfying check-off feedback; Streaks users like enough
gamification to make chains motivating.

**Take:** keep haptics and subtle completion animation. Do not build XP, coins,
pets or a reward economy into Habits.

#### 9. Undo must be obvious

Widget users complain when accidental completion is hard to undo.

**Take:** completion is a reversible desired state everywhere. Tapping again undoes it; Today also gives a short explicit Undo affordance after completion, while widget/Watch controls follow the same desired-state model.

#### 10. Pause/resume is useful when life changes

A user should not have to delete a habit and lose history because of travel,
illness or a temporary change.

**Take:** add pause/resume, but model the paused period explicitly so statistics
do not treat paused days as failures.

#### 11. The best visualizations are simple, persistent and glanceable

Everyday and Way of Life reviews repeatedly praise a clean grid / color history
that is understandable immediately. Habitify users praise calendar views; Streaks
users praise seeing a streak build without opening an analytics dashboard.

**Take:** keep the compact history grid, but align it to real calendar weeks with weekday headers so columns are instantly readable. Expose Today progress in Widget/Watch. Do not add a separate analytics home screen just to show more charts.

#### 12. Gentle reminders beat guilt and aggressive gamification

Finch reviews praise supportive, non-guilt notifications. Everyday users praise
skip/grace behavior and explicitly reject "million-feature" or AI-heavy trackers.

**Take:** reminders stay neutral and factual. No shame copy, streak-loss pressure,
coins, XP, pets or reward currencies.

#### 13. Cloud sync is valued because it prevents friction and loss, not because
it is a feature users want to configure

Users asking for simple trackers often name cloud sync together with visual
simplicity and widgets. Habitify's negative Watch reviews show that stale state is
worse than having no Watch app at all.

**Take:** private CloudKit sync is invisible by default, requires no Arvectum
account, and must preserve local-first operation when offline.

#### 14. Flexible goals and automation are valuable, but belong behind the core
loop

Streaks/Strides users value flexible frequencies, negative habits and Health-based
auto-completion. These solve real cases, but they broaden both the data model and
creation UI substantially.

**Take later:** N/week goals and selective Apple Health auto-completion after the
binary habit loop, Watch, widgets and sync are stable.

#### 15. Habit stacking is useful, but not worth a relationship graph in MVP

Some Everyday users praise habit stacking because one established behavior can
cue another. The underlying idea is useful; a full dependency graph between
habits is not required to deliver it.

**Do not build now:** no habit-to-habit graph or routine builder in MVP. Revisit
only if users ask for sequencing after launch.

#### 16. Personal ordering matters, but should not add controls to Today

Users of minimalist trackers value arranging habits in the order that matches
their routine. This is useful personalization with almost no model complexity.

**Take:** manual drag ordering lives in Manage. Today, Watch and widgets simply
inherit the same order.

#### 17. A blank day and a failed day are not the same thing

Everyday-style visual history is praised partly because state is readable at a
glance; users explicitly ask for a distinction between failure and missing/no
data.

**Take:** fixed-schedule history distinguishes completed, intentionally skipped,
paused/unscheduled and genuinely missed past days. Flexible N/week habits are
judged at the week level, so individual dates are never falsely labelled missed.

## What Habits by Arvectum takes

### Required before public release

- local-first storage;
- instant one-tap check/uncheck;
- Today shows only due habits;
- short create flow;
- visual history;
- current streak + best streak + completion rate;
- archive/restore;
- neutral Skip state;
- pause/resume without deleting history;
- optional reminders;
- system Light/Dark;
- RU + EN;
- native Apple Watch companion app;
- live iPhone ↔ Watch synchronization;
- offline Watch queue + deterministic reconciliation;
- multi-device sync architecture that does not require an Arvectum account.

### High-priority expansion

- interactive Home Screen widget;
- Lock Screen widget / Watch complications;
- overall Today progress outside the full app;
- private CloudKit sync across the user's Apple devices;
- flexible frequency such as N times/week.

### Validate before building

- quantitative habits (pages, liters, reps);
- Apple Health auto-completion;
- quit/break-a-habit mode;
- export/import backup;
- additional analytics.

## Explicit do-not-build list for the core product

Do not add merely because competitors have them:

- categories and filters in the default UI;
- notes/journaling per day;
- social feed or leaderboards;
- achievements / XP / coins;
- virtual pets;
- share cards;
- multiple dashboard display modes;
- multiple reminders per habit;
- custom theme marketplace;
- AI coaching;
- mandatory account system;
- a complicated goals/project-management hierarchy.

## Decision rule

A feature is accepted when it does at least one of these without materially
increasing daily interaction cost:

1. removes taps;
2. prevents lost data or inconsistent state;
3. preserves motivation without manipulating the user;
4. makes progress understandable faster;
5. lets the user act without opening the iPhone app.

## Sources reviewed

- Apple App Store ratings/reviews for Streaks.
- Apple App Store ratings/reviews for Habitify.
- Apple App Store ratings/reviews for Everyday.
- Apple App Store ratings/reviews for Way of Life.
- Loop Habit Tracker product/community materials.
- Strides product materials and comparative user discussions.
- Apple App Store ratings/reviews for Productive.
- Apple App Store ratings/reviews for Finch.
- HabitKit official product/help materials and App Store listing.
- Current habit-tracker/productivity user discussions.
