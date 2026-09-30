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

## Broader competitor / user-review synthesis

Products reviewed: HabitKit, Streaks, Habitify, Everyday, Way of Life,
Loop Habit Tracker, Strides, Productive and Finch, plus current store reviews
and habit-tracking community discussions.

### Repeated praise signals

1. **A tracker that gets out of the way.**
   Everyday, Way of Life and Streaks are repeatedly praised for simplicity,
   fast check-off and clear visual state. Users explicitly complain when the
   tracker becomes another system that needs daily maintenance.

2. **Only show what matters today.**
   Users ask for habits that are not due to disappear from the daily view.
   Habits by Arvectum already follows this rule.

3. **Visual progress at a glance.**
   Grids, chains, streaks, progress rings and very small charts are useful when
   they answer "how am I doing?" without opening an analytics dashboard.

4. **A neutral state for exceptional days.**
   Everyday and Way of Life users specifically praise Skip because illness,
   travel or planned recovery should not turn one exceptional day into a broken
   streak. Habitify also supports done / skipped / missed.

5. **Watch and widgets must remove steps.**
   Streaks is praised for its Apple Watch experience. Habitify reviews value
   completing habits from Watch but criticize flows that require drilling
   through screens. The watch rule for Arvectum is therefore: today's habits
   first, one-tap completion, overall progress visible immediately.

6. **Sync reliability is a product feature, not infrastructure detail.**
   Cross-device sync attracts users to Habitify, while sync failures in Watch,
   Health and widgets appear prominently in negative reviews. Live sync must be
   optimistic, idempotent and resilient to temporary offline operation.

7. **Flexible frequency matters, but should not contaminate the simple default.**
   Streaks, Loop and Strides are valued for schedules such as N times per week
   and for more flexible goal types. This belongs behind an optional advanced
   frequency mode rather than the default create flow.

8. **Small completion feedback is enough.**
   Productive users praise the satisfying completion sound/feedback. Finch shows
   that rewards can be motivating, but also shows how the game can overtake the
   self-care tool. Arvectum keeps haptics/micro-animation and does not build an
   XP economy.

9. **Long-term progress should survive one miss.**
   Finch users praise cumulative progress that does not require an unbroken
   streak. Loop's strength-style model points in the same direction. We keep
   streaks, but also show completion/consistency so streak is not the only
   definition of success.

10. **Automation is useful only when it eliminates logging.**
    Habitify and Streaks gain value from Apple Health and service integrations.
    Automatic completion is a later enhancement, not a launch dependency.

## Product decisions

### Required before public release

- local-first, no-account core;
- one-tap completion / undo;
- Today contains only due habits;
- very short create/edit flow;
- visual history;
- current streak + completion consistency;
- best streak in details;
- optional local reminder;
- archive/restore;
- **Skip day** as a neutral exceptional-day state;
- system Light/Dark and accessibility-size layouts;
- RU + EN;
- **Apple Watch companion app**;
- **live iPhone ↔ Watch sync**;
- **offline Watch check-offs that reconcile when connectivity returns**;
- deterministic/idempotent sync protocol so repeated delivery is safe.

### High priority immediately after Watch/live sync

- interactive Home Screen widget;
- Lock Screen widgets / Watch complications;
- flexible frequency: N times per week;
- private iCloud sync across the user's Apple devices;
- automatic sync with Apple Health for habits where Health has authoritative data.

### Validate before building

- quantitative habits (pages, liters, repetitions);
- quit/break-a-habit mode;
- export/import;
- smart/adaptive reminder timing;
- additional statistics beyond current/best streak and consistency.

## Explicit do-not-build list

Do not add unless later user evidence overturns this decision:

- AI coach;
- social feed / public leaderboard;
- challenges as a core navigation area;
- XP, levels, pets or reward economy;
- notes/journaling on every habit day;
- categories/tags before habit counts make them necessary;
- multiple dashboard display modes;
- custom themes beyond system Light/Dark;
- multiple reminders per habit in the default UI;
- account creation as a prerequisite for tracking;
- complex goal configuration in the first-run path.

## Design principles extracted from reviews

- Every new feature must either remove an action, improve recovery after a miss,
  or make progress easier to understand.
- A widget is bad if it forces the user to open the app to understand state.
- A Watch app is bad if completion takes more than one obvious tap.
- Sync is considered broken if two devices can visibly disagree for long.
- Skipping is not failure; planned or exceptional days should be representable.
- Streak is motivational context, not the user's score or moral judgment.
- Advanced flexibility belongs behind progressive disclosure.

## Sources reviewed

- HabitKit current App Store / product feature set.
- Streaks App Store listing and user reviews.
- Habitify App Store listing, version history and user reviews.
- Everyday App Store reviews.
- Way of Life App Store reviews.
- Loop Habit Tracker Google Play reviews.
- Strides App Store reviews.
- Productive App Store reviews.
- Finch App Store reviews.
- Current habit-tracking community discussions.
