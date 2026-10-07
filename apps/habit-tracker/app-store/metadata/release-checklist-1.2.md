# ChickMark 1.2.0 (Build 4) — ASO / app-ads release

## Goal
- [x] Fix Yandex Advertising Network app-ads.txt discovery by publishing a Marketing URL / developer website.
- [x] Improve App Store search relevance for Russian and English habit-tracker queries.
- [x] Keep the product functionality unchanged from 1.1.

## ASO
- [x] RU name: `ChickMark: трекер привычек`.
- [x] RU subtitle: `Цели, серии и напоминания`.
- [x] RU keywords: `рутина,чеклист,планер,календарь,задачи,мотивация`.
- [x] EN name: `ChickMark: Habit Tracker`.
- [x] EN subtitle: `Goals, streaks & reminders`.
- [x] EN keywords: `routine,daily,planner,checklist,calendar,progress,discipline,motivation,widget,watch,schedule`.
- [x] RU/EN descriptions tightened around habit-tracker intent.
- [x] RU/EN promotional text added.
- [x] Marketing URL set to `https://arvectum.com`.
- [x] Support URL remains `https://arvectum.com/contact.html`.
- [x] Existing RU/EN iPhone and Apple Watch screenshots copied to 1.2.

## app-ads.txt
- [x] `https://arvectum.com/app-ads.txt` returns HTTP 200.
- [x] File contains the Yandex DIRECT declaration: `yandex.com, 331819459, DIRECT`.
- [x] Version 1.1 cannot accept a Marketing URL because Apple locks that field after release.
- [x] Version 1.2 carries the Marketing URL so the live App Store page can expose the developer website after release.

## Build
- [x] Source commit: `29275443b884921b1b08ce8ea689960f5de564d3`.
- [x] Release hygiene passed.
- [x] Archive smoke passed for iPhone app, iPhone widget, Watch app, and Watch widget: 1.2.0 (4).
- [x] Signed App Store archive and IPA created.
- [x] IPA SHA-256: `e72508a08709e4f4c45c3306882976e26061ce472f139adaeceec11a649142b4`.
- [x] Yandex banner ID in exported app: `R-M-20183085-1`.
- [x] Upload succeeded. Delivery/build UUID: `7ab0c228-dddc-46a6-97db-24c87276b0f8`.
- [x] Build 4 processed as VALID and attached to App Store version 1.2.

## App Store Connect
- [x] App Store version ID: `ff201c34-eade-47ed-bedd-dd0935a5dcb8`.
- [x] Release type: MANUAL.
- [x] Review details populated; no demo account required.
- [x] Draft submission validated as READY_FOR_REVIEW.
- [x] Review submission ID: `bee85780-2392-41ae-9bfa-1d0c9a2cbfcc`.
- [x] Submitted to App Review.
- [x] Current state: WAITING_FOR_REVIEW.
- [ ] After Apple approval, manually release 1.2.
- [ ] After release, confirm the App Store page exposes the developer website and re-check Yandex app-ads.txt status.
