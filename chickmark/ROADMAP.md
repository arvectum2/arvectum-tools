# ChickMark — Product Roadmap

## 2026-10-14 — App Store 1.4.1 (15) review submission completed
- [x] Public 1.4.1 (15) was independently verified APP_STORE_ELIGIBLE and VALID, attached to App Store draft with localized RU/EN/ES What's New and App Review Notes.
- [x] **Apple App Privacy P0 closed** via authenticated App Store Connect: old Data Not Collected replaced by published Data Not Linked to You, eight SDK categories completed (Coarse Location, Device ID, Product Interaction, Advertising Data, Crash Data, Performance Data, Other Diagnostic Data, Other Data Types). See metadata/privacy-review-1.4.1.md for purposes and caveat about AppMetrica AdSupport IDFA capability; ChickMark does not request IDFA/ATT and sets SDK location and consent false.
- [x] App Store Connect confirmed 1 Item Submitted and independently displayed **iOS 1.4.1 Waiting for Review**. Version has MANUAL release; no public App Store release yet (public 1.4.0 remains live).
- [x] Complete release branch Habits iOS CI passed (run 38615994169); PR #39 extended Xcode Cloud UI smoke timeout to 900s without changing app assertions. A main CI rerun was requested; its eventual result is separate from the physically tested build.
- [ ] Await Apple Review decision and subsequently make a deliberate MANUAL public-release decision. No asynchronous promise of release.
- [ ] Optional extended device QA (offline Watch reconciliation, midnight, revoked Health permission, live Yandex fill) remains; no installed app data was deleted.


## 2026-10-14 — 1.4.1 (15) cloud CI slower simulator startup
- [x] Xcode 27 CI completed unit/integration checks but essential two UI tests exceeded the old **270-second** hard-stop while simulator launch/idling was slow; no UI assertion failed in the captured log. Keep both exact test result assertions unchanged and extend the bounded CI smoke allowance to **900 seconds**, within the 35-minute workflow cap. Verify CI green on main.


## 2026-10-14 — Public release 1.4.1 (15) P0 audit
- [x] Build 1.4.1 (14) internal TestFlight physically accepted: keyboard, Watch threshold/checkmark, face autonomously updated without opening ChickMark; background refresh latency exceeded 25 minutes in one observed test. Green CI 38593557338; all four signed builds; zero archive audit errors.
- [x] Current App Store public 1.4.0 (8) independently verified READY_FOR_SALE using official App Store Connect API. Internal 1.4.1 (14) has buildAudienceType INTERNAL_ONLY and cannot go directly to App Review.
- [x] Merge physically tested feature branch into dedicated public-release branch from main; conflicts resolved retaining tested 1.4.1 behavior, unrelated Arvectum Tools paths unchanged; Watch build and architecture pass. Public build number all four targets bumped to 15.
- [x] New localized public 1.4.1 What's New and updated App Review Notes reflect HealthKit, watchOS background, privacy and ads; updated privacy compliance audit identifies all bundled SDK manifests. See app-store/metadata/release-notes-1.4.1.md, review-notes-1.4.1.md, privacy-review-1.4.1.md.
- [x] **App Privacy now published**: eight categories and purposes declared after reviewing the Yandex/AppMetrica/KSCrash manifests. The previous Data Not Collected label was corrected before review submission.
- [ ] Manual on-device offline Watch reconciliation, Health consent denial, midnight rollover and nonempty Lock Screen widget / ad behavior remain partially simulated, not fully signed-off on physical Watch; no uninstall/reset of owner's data.
- [x] Public-capable signed 1.4.1 (15) archive, 4/4 Apple Distribution IPA components, production push/CloudKit, Watch HealthKit entitlement. Upload succeeded, official App Store Connect API confirmed **VALID / APP_STORE_ELIGIBLE**, attached to iOS App Store draft 1.4.1. Four What’s New locales and App Review Notes updated and verified. Release type **MANUAL** and version status **PREPARE_FOR_SUBMISSION**; no App Review submission or public release.
- [x] Updated and deployed site privacy policy covering optional ChickMark Apple Health processing; HTTPS /privacy returns 200 with new text. Backed up previous file on hosting; only privacy.html replaced (GitHub arvectum2/arvectum-site PR #14). Site-wide check currently has unrelated pre-existing sitemap/Schlam static issues, not caused by privacy paragraph.
- [x] App Privacy questionnaire accessed, completed and published; Apple displays Data Not Linked to You. Reassess if SDK collection, user-consent settings or IDFA behavior changes.
- [ ] Physical offline/overnight/permission-denial and Yandex production-fill QA remain interactive; existing model, backup, CloudKit group code unchanged, full local unit and accepted real Watch foreground/background tests provide partial evidence. No destructive device actions.


## 2026-10-14 — Independent Watch face Health completion physically confirmed
- [x] ChickMark 1.4.1 (14), real Apple Watch: when user reached the HealthKit step goal, Watch face complication **updated itself** without opening ChickMark on either Watch or iPhone. Approximately 25 min after goal it was still stale; it updated soon afterward. **The standalone-autonomy acceptance gate is now closed.**
- [x] Numeric step goal keyboard: user previously confirmed compact down-arrow button works. Watch app HealthKit auto-check: user previously confirmed.
- [x] GitHub Habits iOS CI on build 14 SHA 4f9f588: [run 38593557338](https://github.com/arvectum2/arvectum-tools/actions/runs/38593557338) status **completed / success**. Signed Watch widget extension HealthKit capability and Production CloudKit verified.
- [ ] Optional optimization: record actual OS refresh intervals across several days and evaluate latency UX; not a blocker for functional acceptance and not a guarantee of realtime updates. Public App Store review remains a separate explicit decision.


## 2026-10-14 — 1.4.1 (14) internal independent Watch complication HealthKit QA
- [x] Advance all four targets iPhone, iPhone widget, Watch and Watch complication to build 14, preserving marketing version 1.4.1, bundle identifiers and storage model.
- [x] Include PR #35 independent Watch WidgetKit extension local HealthKit step reader at each OS-scheduled timeline refresh; native Watch Health observer background path remains. Physically 1.4.1 (13) keyboard and Watch app automatic completion worked but Watch complication did not autonomously update.
- [x] Preflight: 173/173 local iOS tests, watchOS build, signed Watch widget HealthKit entitlement confirmed in Apple provisioning and archive, archive privacy audit zero errors.
- [x] Signed internal-only TestFlight Production CloudKit build 1.4.1 (14) exported and uploaded. Apple validated it and API confirmed attachment to existing ChickMark Internal QA group. No public App Store release or direct device installation.
- [x] **Physical user acceptance PASS** (2026-10-14): after meeting step goal, ChickMark remained unopened on both iPhone and Apple Watch, and the **Watch face complication autonomously changed to checked**. First check at roughly 25 min after goal was still stale; it updated shortly after the user reported that observation, with no app launch. Precise latency and wake source (WidgetKit direct HealthKit query vs Watch host app background observer) unmeasured; do not claim instant refresh or identify specific callback without logs.


## 2026-10-14 — follow-up QA 1.4.1 (13): Watch face autonomy
- [x] Owner reports keyboard arrow now works; automatic checkmark appears in Watch ChickMark at goal after launching the Watch app, and watch-face complication subsequently refreshes. It does not update autonomously before launching Watch ChickMark.
- [x] Confirmed Apple watchOS limitation: stepCount background HealthKit observer delivery is hourly capped, at most 4 combined background wake-ups/hour with an active complication (Apple HealthKit documentation). The immediate setting is not a guaranteed fast update.
- [x] Added second independent update path: on each WidgetKit timeline request (nominal policy after 15 min; OS scheduling discretionary), the Watch complication extension itself reads Watch-local stepCount via HKStatisticsQuery if linked step habits exist. Apple engineer confirms extensions can read preauthorized HealthKit samples but must not request authorization themselves. No HealthKit permission dialog; 4-second fail-safe to cached snapshot.
- [x] Watch widget extension gained its own HealthKit entitlement and read purpose string; signed archive and embedded Apple provisioning profile verified extension's healthkit entitlement. Raw step totals do not leave Watch or persist to app-group cache; only derived local completion appears in timeline entry. Existing WidgetKit projection and foreground paths remain as fallback.
- [x] Added 3 pure regression tests for a 4500/4400 success, 4399/4400 below target, skipped day and double-count prevention. Local 173/173 iOS tests, generic watchOS build and signed archive privacy audit all green.
- [x] Version and distribute internal-only TestFlight build 1.4.1 (14). End-to-end Watch complication autonomous refresh **observed by user without tapping/opening ChickMark**, after a delay exceeding ~25 minutes. No public release or device reinstall.


## 2026-10-14 — 1.4.1 (13) internal-only Watch step auto-check retest
- [x] All four iOS/Watch/widget targets advance together from build 12 to build **13**; unchanged app identifiers, version 1.4.1, and SwiftData/CloudKit storage schema.
- [x] Code fix from PR #32: Watch HealthKit 4500/4400 completion now aligns with iPhone same-day manual-recheck policy; explicit skips stay excluded. Numeric keyboard uses compact native down-chevron accessory rather than gesture recognizer. Physical 1.4.1 (12) failure and acceptance gates recorded in QA.
- [x] Focused local checks: **170/170 iOS unit tests**, numeric keyboard arrow simulator UI PASS, generic watchOS build PASS, release hygiene and architecture PASS.
- [x] Signed and privacy-audited Release archive, exported production-CloudKit internal-only IPA 1.4.1 (13), verified all four bundles and Watch background-delivery entitlement, uploaded successfully. Apple App Store Connect API confirmed build VALID and attachment to existing **ChickMark Internal QA** (5 internal builds, same testers). No app installation/uninstall or public review submission.
- [ ] Physical QA: with iPhone ChickMark untouched, confirm Watch UI **and watch-face complication** complete when HealthKit current steps are at least the target, even after a past day-mutation marker; test keyboard arrow on iPhone.


## 2026-10-14 — QA 1.4.1 (12): 4500/4400 steps still unchecked on Watch
- [x] **Physical observation:** user did not open iPhone; native Watch Activity rings updated and Watch ChickMark displayed e.g. **4500/4400**, yet neither Watch app checkmark nor complication completed. User reports that launching ChickMark on iPhone reconciles the checkmark and syncs it back. Therefore this is **not merely a delayed widget repaint**; Watch local qualification policy can reject correct numeric readings.
- [x] Found policy divergence: iPhone HealthHabitAutoPolicy.shouldComplete permits same-day re-completion after a historical manual uncheck if live HealthKit reaches today's target. Watch WatchLocalHealthProjection.qualifies rejected every healthManualOverride, even with 4500 >= 4400. Match iPhone behavior on current-day on-Watch HealthKit verification; keep explicit skipped days excluded and do not mutate stored authoritative iPhone snapshot. Update both Watch app derived UI and complication cache merge to respect current verified progress.
- [x] Added regression test covering Watch step value **4500 / 4400**, stale manual-mutation flag, and Watch face derived count, plus zero case (4399 / 4400), skipped day and prior-target invalidation. Full local 170/170 iOS unit tests and selected numeric-edit UI test passed; Watch generic build passed.
- [x] **Keyboard:** physical QA reported unusual/jittery swipe dismissal. Removed custom UIWindow pan recognizer; restored native ToolbarItemGroup keyboard placement with only one compact downward-chevron button aligned trailing, with VoiceOver label and no large text control. UI simulator verified button tap dismisses numeric keyboard. Follows native Apple SwiftUI keyboard accessory pattern.
- [ ] New internal-only versioned TestFlight candidate; verify **without opening iPhone** that Watch screen and Watch face both automatically check at/above goal. Physical behavior still needs acceptance. No public submission or uninstall/reinstall.


## 2026-10-14 — 1.4.1 (12) internal-only Watch Health background QA
- [x] Advance all four iPhone/Watch/widget targets from build 11 to **build 12** without changing marketing version, app identifiers or data schema.
- [x] Incorporate PR #28: pull-down numeric keyboard dismissal and real watchOS HealthKit observer/background delivery, plus independent Siri Shortcut filter bug correction.
- [x] Preliminary checks: 169/169 iOS unit tests, numeric swipe-down simulator UI pass, generic watchOS build pass, signed watchOS archive contains HealthKit Background Delivery entitlement **and matching provisioning profile**, no archive privacy errors.
- [x] Signed Release archive and internal-only TestFlight export succeeded for build 12. Verified IPA: all four components 1.4.1 (12), production push and CloudKit, Watch HealthKit Background Delivery entitlement in exported Watch binary. Apple App Store Connect API accepted build 12 as VALID and confirmed attachment to the existing **ChickMark Internal QA** internal group (2 existing testers, 4 builds). No user device installation or public App Store review submission.
- [x] Physical iPhone 13 **ChickMark 1.4.1 (12) installed** as read-only verified through Xcode devicectl on 2026-10-14. Physical Watch is paired but remote CoreDevice tunnel timed out; Watch installed version **not remotely verified**. No install or app launch forced.
- [ ] **Physical Watch QA:** install 1.4.1 (12) through TestFlight without uninstalling; open Watch ChickMark once to ensure observer registration, then return to Watch face and keep ChickMark closed. Exceed the goal, optionally check Apple Activity rings, and observe whether the complication updates without launching ChickMark. Record the native Activity steps, goal and elapsed time; system budgets delivery and WidgetKit refreshes, so no instant-update promise.
- [ ] **Physical iPhone numeric keyboard QA:** edit step goal, pull **down on the form above the number pad** (not on individual number keys) and verify keyboard disappears. Simulated UI test passed.
- [x] GitHub Habits iOS CI for commit c7f7d58: [run 38572244812](https://github.com/arvectum2/arvectum-tools/actions/runs/38572244812) **completed SUCCESS**, including unit/integration tests, essential UI smoke, and archive smoke. Prior deterministic Siri Shortcuts bug is fixed; 169/169 local unit tests and step-keyboard swipe UI test passed.


## 2026-10-14 — follow-up physical QA on internal 1.4.1 (11)
- [x] Owner confirmed **Watch app itself automatically checks a step habit correctly**, but the Apple Watch **face complication** updates only after manually launching ChickMark. Existing complication consumed a snapshot projected by running Watch app, without a registered watchOS HealthKit background observer.
- [x] Implement watchOS HKObserverQuery background delivery **only for metrics with opted-in rules in the Watch snapshot**; wake-up handler reads on-watch HealthKit (no permission prompts), verifies day/snapshot/metric+target have not changed, updates local Boolean-only app-group cache and requests a WidgetKit complication reload on changed result. Watch app delegate registers observers at Watch app launch; registration retried after foreground Health authorization. HealthKit Background Delivery entitlement present and signed in watchOS archive and provisioning profile. No raw HealthKit counts are uploaded. OS background budget and WidgetKit rendering remain not guaranteed real-time; background test must be done on physical Watch.
- [x] Owner confirmed numeric step-goal keyboard had no usable downward swipe after removing bulky toolbar. A simultaneous, non-cancelling UIWindow pan recognizer dismisses focused keyboard on deliberate downward form pull, including when Form itself cannot scroll. Numeric Health editor UI test now verifies keyboard closes; no accessory bar.
- [x] Fixed deterministic HabitShortcutBridge.filterEntities bug: passed entities were discarded and global snapshot fetched instead. Existing case-insensitive Siri Shortcuts test now passes (4/4); this was a real source of GitHub CI failure for 1.4.1 (11), in addition to hosted-runner SwiftData read-only noise/timeouts.
- [ ] Physical QA after a separately versioned internal TestFlight build: keep Watch ChickMark closed, pass step threshold on native Activity, leave Watch face visible. Record whether complication changes without opening ChickMark, plus elapsed time and any OS throttling. Separately confirm swipe down numeric keyboard in edit sheet. No public App Store submission.


## 2026-10-14 — 1.4.1 (11) internal Watch + keyboard QA candidate
- [x] Build number 10 → 11 in all four iPhone, Watch and widget targets, same marketing version 1.4.1, same bundle identifiers/data schema.
- [x] Include keyboard-toolbar removal, goal-specific watch-face projection invalidation and Watch foreground HealthKit read improvements from PR #26.
- [x] Prior targeted tests 25 unit + 2 UI and generic Watch build passed. App Store review is NOT requested by this candidate.
- [ ] Signed archive, internal-only TestFlight upload, group assignment and on-device testing with actual Watch numeric current/target when auto-check fails.


## 2026-10-14 — Physical build 1.4.1 (10) UX and Watch face retest
- [x] Owner reported keyboard accessory **large 'Hide keyboard' button obscures step-goal input** and forces scrolling. Removed separate keyboard toolbar; retained standard Form interactive scroll keyboard dismissal, without an obstructing bar. Physical swipe interaction still merits manual QA. Two UI simulator tests passed: no accessory button and unified Health editor usable.
- [x] Owner changed step target on iPhone and saw auto-check disappear appropriately. **Watch-face complication retained old resolved count (1/3)** until owner opened Watch ChickMark app, where updated unchecked state appeared. Caches now bind derived checkoffs to their exact metric/target; stale completion cannot survive new goal once Watch receives corresponding sync snapshot. WidgetKit and WatchConnectivity still OS-scheduled; instant background widget update not guaranteed.
- [x] After walking and opening native Apple Watch Activity rings, step numbers refreshed in Watch ChickMark, but **automatic checkmark did not appear**. Missing exact watch current/target reading and whether manual override is set: do not pretend root cause proven. Watch now re-reads HealthKit when scene becomes active after returning from Activity; queries race-proofed against older snapshot; deterministic threshold qualification extracted and unit-tested.
- [x] Initial focused verification: 25/25 unit tests (HealthKit + Watch complication), generic watchOS build, 2/2 simulator UI tests, release hygiene + architecture check. Real device auto-check and complication update remain acceptance gates.
- [ ] No public App Store submission. Next internal TestFlight candidate only for nondestructive iPhone/Watch QA. Record **exact Watch steps / target** when check fails and whether iPhone auto-checks same habit.


## 2026-10-14 — 1.4.1 (10) internal TestFlight QA build (NOT public)
- [x] Advance **all four iOS/watchOS/widget build numbers** from 1.4.1 (9) to 1.4.1 (10), without changing marketing version, bundle IDs or persistence model.
- [x] Incorporate Watch-face complication fix from [PR #22](https://github.com/arvectum2/arvectum-tools/pull/22), after real device QA found automatic steps completed in Watch ChickMark but not on the watch-face complication. Native Watch Activity rings preceding the synchronized steps is an observation, not a delivery guarantee.
- [ ] Check clean CI, full iOS unit tests, signed four-bundle archive and production CloudKit internal-only TestFlight export and upload. Do not submit or publish a public App Store release.
- [ ] Physically install new internal build non-destructively, observe the Watch-face complication after the Watch ChickMark app has verified HealthKit completion. Validate manual undo, fresh goal and day rollover separately. OS throttling can defer complication repaint.


## 2026-10-14 — WidgetKit reconciliation after physical 1.4.1 (9) TestFlight QA
- [x] **Observed on real paired devices:** changing the Health step goal on iPhone reached the Watch immediately. After walking, iPhone Health and ChickMark showed the same stale step count for over five minutes. Opening the native Watch Activity rings refreshed data in iPhone Health and ChickMark; automatic checkoff appeared on Watch after opening ChickMark. The widget/complication did not update automatically. This does **not** prove opening Activity guarantees HealthKit delivery.
- [x] Watch complication code now merges today's *locally verified Boolean Health completion* into its own transient app-group Caches projection (not CloudKit, not the authoritative WCSession snapshot, never raw step data), and requests WidgetKit reload **only when the projected IDs change**.
- [x] Preserve manual undo/skip priority and day boundary; Watch cached manual override is set immediately while pending iPhone ACK, and only the un-overridden local checkoffs appear in the complication.
- [x] Avoid repeatedly requesting an iPhone widget reload every 60 seconds when HealthKit auto-completion is unchanged; the existing local-only phone widget projection remains in place.
- [x] Verified: 167/167 iOS unit tests, including four new Watch projection edge cases; watchOS generic build passed. No physical devices modified by this patch.
- [ ] **Real Watch/iPhone widget QA after a new TestFlight build:** open Watch app after Health data arrives, verify Watch complication and iPhone widget without manually toggling; check manual undo, offline sync, midnight rollover. WidgetKit may defer reloads; do not promise instant updates, nor background Watch auto-completion while its app is suspended.
- [ ] Keep 1.4.1 (9) TestFlight installed until next build is explicitly approved; no public submission or upgrade was performed for the widget patch.


## 2026-10-14 — 1.4.1 (9) candidate preparation (NOT released)
- [x] Candidate version 1.4.1 (9) pinned across iPhone app, Watch app and both widgets after published 1.4.0 (8); consolidated Watch Health progress, unified habit editing and Health auto-check reconciliation.
- [ ] Complete versioned archive, CI and physical non-destructive device QA before any upload. See [candidate release gate](docs/RELEASE_CANDIDATE_1.4.1.md).


## 2026-10-14 — HealthKit polling + Watch completion reconciliation (1.4.1 code patch, not shipped)
- [x] **Physical iPhone, user-confirmed:** step target exceeded; displayed reading did not change while ChickMark remained open. After opening Apple Fitness and accepting updated terms, Health data appeared in ChickMark and «Прогулка» was marked complete automatically. This proves the iPhone auto-completion worked after new data arrived, NOT that Fitness terms caused the delay.
- [ ] **Physical Watch:** neither the step reading nor automatic checkmark updated. Published Watch build 1.4.0 (8) has no numeric progress UI; local HealthKit data/permission and WatchConnectivity delivery remain separate unresolved gates.
- [x] **Original cadence:** foreground Today polls HealthKit every 120 seconds, observer background delivery requested at hourly, and foreground/observer events also refresh. iOS schedules data availability independently.
- [x] **Next-patch behavior coded:** active foreground poll every 60 seconds on iPhone/Watch (no background polling); phone Health auto-completion projected into paired-Watch Boolean completion snapshot; publish when derived completion state changes. Raw HealthKit data or totals are never sent to WatchConnectivity; synthetic completion not persisted to SwiftData or CloudKit.
- [x] Local verification: 32 focused Health + Watch sync unit tests, iOS simulator test build and Watch simulator build successful; architecture contract OK.
- [ ] **Real-device timing QA:** after Fitness/Apple Health ready, keep ChickMark foreground-active; record step readings in Apple Health and ChickMark at 0 / 30 / 60 / 120 seconds, then background/foreground; compare iPhone auto-check and paired-Watch receipt, local permission and reachability. Never promise a 60-second end-to-end guarantee; underlying HealthKit sample delivery may lag.
- [ ] Signed next release only after non-destructive physical acceptance; published 1.4.0 remains unchanged.



## 2026-10-14 — one unified habit editor (1.4.1 candidate, NOT shipped)
- [x] Apple Health connection, supported metric, numeric threshold, and disconnection are now all controlled by the SAME Create/Edit Habit sheet as habit name, schedule and notifications. This supersedes the older split flow.
- [x] Remove the separate "Smart automations" navigation card and delete the superseded Apple Health settings screen; preserve HealthKit local-only measurement privacy, current rule preferences, their original opt-in date (when the metric is unchanged), and historical habit records.
- [x] Changing the threshold of an already-linked habit does not request Health permission again. Linking a new habit or changing the metric requests access BEFORE saving; failures keep the sheet open and avoid persisting a partial new link. Cancel leaves the stored rule untouched.
- [x] Tests on Mac mini: 29/29 targeted Health + sync tests; 2/2 iOS 27 UI tests for editing + new habit; rebuilt iOS simulator target after deleting the old screen; architecture contract OK.
- [ ] Physical-device acceptance on iPhone 13: link/create, edit/reopen target, cancel/disable, permission denial, automatic step completion; Watch local step/target display and non-destructive installation before submitting next version.

## 2026-10-14 — 1.4.1 usability patch prepared (NOT shipped)
- [x] For an **already linked** Apple Health habit, show the current activity goal and editable numeric threshold directly in the iPhone habit edit form near the habit name. Reuse existing read-only HealthKit association; save only the threshold, preserve the activation date and historical check-ins, refresh iPhone progress and send updated goal metadata to Watch.
- [x] In both creation and editing forms, add a localized **Hide keyboard** accessory action, plus interactive scroll dismissal; include the numeric goal keyboard and the Apple Health configuration screen.
- [x] Fix parsing of localized thousands separators such as 5 000, 5,000 and 5.000 for step targets; prevent fractional/zero/out-of-bounds step goals and ensure loading an existing non-default Health metric does not reset a saved threshold.
- [x] Focused code tests: 28/28 Health and sync cases; iPhone simulator UI smoke for hiding the keyboard: passed. Published 1.4.0 data on physical devices remained untouched.
- [ ] Ship in a versioned 1.4.1 candidate after sign-off: physical iPhone target edit/save/reopen and actual HealthKit automatic check-in, Watch on-device progress, non-destructive upgrade, and App Store review. Do not equate passing simulated checks with public availability.


## 2026-10-14 — published release + physical Watch observation
- [x] Owner confirmed ChickMark 1.4.0 (8) approved and publicly released; iPhone and Watch app inventories both show build 8.
- [x] Owner manually opened Watch app and observed the HealthKit-linked «Прогулка» habit; opening the list did not immediately crash. The Watch design intentionally uses tap-to-check, without per-habit detail navigation.
- [x] Physical defect reproduced from UX/code: published 1.4.0 has no inline current/target HealthKit progress, even when a rule is configured. Automatic completion and checkbox alone are insufficient as feedback.
- [x] Fix prepared: locally measured current/goal + gauge below each Watch Health habit, explanatory fallback when Health data are unavailable, no measured value in WatchConnectivity/CloudKit. Watch build, 17 protocol tests and architecture check passed on Mac mini.
- [ ] Physical user acceptance of the future patch: real step values, permissions, foreground stability, offline sync, day rollover. Do not mark 1.4.0 itself fixed; release approval/version bump for the patch remains open.


**Updated:** 2026-10-12
**Status:** v1.3.0 (build 5) **published — owner-confirmed 2026-10-11**. Installed on paired physical iPhone 13 and Apple Watch SE, verified via CoreDevice app inventory 2026-10-11. Independent public App Store availability/rollout not re-verified in this audit.
**Authoritative feature evidence:** historical [ChickMark branch snapshot](docs/history/ROADMAP-chickmark-branch-2026-10-11.md) formerly from `feature/chickmark-multicheck`, now integrated into `main`; [earlier planning archive](docs/history/ROADMAP-legacy-2026-10-11.md).
**Shared rules:** [Core](../core/CORE_PRINCIPLES.md). **Promotion and ASO metrics:** [Growth](../growth/ROADMAP.md).

## Published baseline: 1.2
- [x] Local-first SwiftData habit tracking, daily check-off, scheduling and progress.
- [x] Apple Watch and widget integration; app-specific release checks.
- [x] One-off reminders with isolated local persistence.
- [x] First unobtrusive Today ad; keep published schema and 1.2 rollback compatibility.

## 1.3: published (owner-confirmed); physical acceptance remains ongoing
- [x] Multiple check-offs, incremental goals and extended statistics (implementation recorded in branch).
- [x] RU/EN/ES localized UI and localized store assets prepared.
- [x] Signed 1.3.0 (5) candidate and device installation recorded.
- [x] App Review submission recorded 2026-10-11.
- [x] Owner confirmed public release of 1.3.0 (5) on 2026-10-11; physical iPhone and Watch installed versions also match.
- [ ] Independently confirm store rollout in each intended region when relevant.
- [ ] Complete physical-device CloudKit/data-preservation, Watch offline reconciliation and ad/privacy QA evidence. No destructive migration or overwrite of published app.
- [ ] Verify branch documentation and final release notes against the exact uploaded binary.

## 1.3.1 — branding, web links and post-refactor update (App Store preparation)
- [x] Adopt current post-refactor Core modules, without changing published storage schema or Watch/widget IDs.
- [x] Add compact branded Today header (ChickMark, official Arvectum logo, runtime app version).
- [x] Link the header to locale-specific product pages (RU/EN/ES) and test mappings.
- [x] Synchronize iOS, Watch and widget target versions at 1.3.1 (6).
- [x] Regenerated Xcode project; 17 unit tests, 1 UI test and non-uploading release archive audit passed on 2026-10-12.
- [x] Replace unsubmitted App Store Connect 1.4 placeholder with 1.3.1 and configure AFTER_APPROVAL automatic publication (2026-10-12).
- [x] Set and verify locale-specific Marketing URL, Support URL and What’s New for RU, EN-US, ES-ES and ES-MX (2026-10-12).
- [ ] Attach signed 1.3.1 (6) build, pass App Store readiness checks, and submit for Apple review.
- [ ] Final iPhone/Watch non-destructive upgrade and offline-sync smoke, plus App Review.

## Product backlog
- [x] Sliding recurrence: next due date N days after **actual completion** (shipped in 1.3; covered by HabitFrequencyTests.testCompletionIntervalMovesFromActualCompletionDay).
- [ ] Finish edge-case policy/regression coverage for timezone travel, partial goal completion and overlapping interval completions (basic late-completion and future-check-in cases already tested).
- [ ] Evaluate extra monetization placements only after retention evidence; do not add a second native Progress ad by default.

### Proposed 1.4 — less manual tracking (not included in 1.3.1)
- [x] **P1 · Apple Health / HealthKit auto-check (development implemented, physical QA pending):** optional per-habit authorization and mapping for walk distance, workouts and other reliable HealthKit metrics; show a traceable completion source, handle revoked permission, duplicates, and Watch/iPhone reconciliation; preserve local-first privacy and allow manual correction.
- [ ] **P1 · Gentle restart after an interruption:** offer an optional, one-tap return plan after a user-configured gap; preserve all past check-ins and historical streaks, never guilt-trip or silently rewrite missed days.
- [ ] **P2 · Local weekly summary:** 7-day opt-in, low-noise snapshot with completion consistency, best day and trend; respect pauses/skips and flexible weekly goals; no account or remote analytics.
- [ ] **P2 · Negative/reduction habits:** distinguish "avoided today", "slipped" and quantity limits from positive habits; define streak, reminder and insight semantics before schema migration.
- [ ] **P3 · Notes on a check-in:** short optional comment attached to a specific habit/day, with backup/restore and migration coverage; no notes required for ordinary one-tap completion.

**Implementation gate:** do not start all five at once. Ship HealthKit and Gentle restart first behind independent opt-in flags, with migration/Watch/widget regression; only add subsequent features if they keep the core check-in friction low.

## Product-specific ad guardrails
Core features stay free. No interruptions during creation, check-off, widgets or reminders.
Delayed initial advertising and its thresholds are **ChickMark-specific**, not portfolio policy.

No app-specific tasks are duplicated in Core or Growth.

## 1.4 HealthKit implementation checkpoint (2026-10-12)
- [x] Read-only per-habit opt-in: steps, walk/run distance and workout duration.
- [x] Local rules, HealthKit observers, foreground 7-day catch-up; raw samples never leave HealthKit.
- [x] Automatic check-in through canonical mutation ledger; manual and Watch corrections take priority.
- [ ] Verify permissions, background delivery, CloudKit/Watch updates on a physical iPhone.
- [ ] Check App Store privacy disclosures and HealthKit capability before uploading 1.4.

### Native Apple integrations (future iterations)
- [x] Siri and Shortcuts — existing App Intents for completing and undoing habits.
- [x] Apple Watch and WidgetKit — existing check-in and offline Watch sync.
- [x] Apple Health — optional read-only thresholds (1.4 development, release gated by physical QA and privacy review).
- [ ] P2 · Apple Reminders — opt-in one-way creation of a reminder from a ChickMark habit; prevent duplicates and clarify it is not two-way status sync.
- [ ] P2 · Apple Calendar — opt-in event creation with write-only EventKit access; avoid overlapping ChickMark native notifications.

## Smart habit signals (2026-10-12 implementation)
- [x] HealthKit running workouts: one run of at least N minutes counts as one day, including flexible weekly goals such as three running days per week.
- [x] HealthKit sleep: asleep stages merged for the wake-up day (noon to noon), deduplicating overlapping tracker records.
- [x] iPhone Shortcuts: existing Complete Habit App Intent can be used with application triggers; user-facing per-habit setup guidance added.
- [x] Smart-metric tests, policy and RU/EN/ES interface updates.
- [ ] App-close events do not prove actual reading duration; reading-time verification is not yet supported.
- [ ] Release gate: HealthKit consent and background delivery, real-device night-boundary QA, plus CloudKit/privacy review.

### Local-only HealthKit projection, October 12 (in development)
- [x] Stop HealthKit-driven writes into SwiftData CloudKit HabitCheckIn and HabitDayMutation.
- [x] Compute temporary HealthKit-derived completions on iPhone; merge for Today and habit-detail progress without persistence.
- [x] Add direct HealthKit checks in the Watch app; send user-selected metric and threshold over existing WatchConnectivity snapshots, never derived readings or pass/fail health results.
- [x] Watch checks honour manual day-level overrides; correct watch manual cancellation of locally verified completion.
- [x] Keep JSON backups, CloudKit, shared widget snapshots and notifications free of automatically generated check-ins.
- [ ] Device QA: authorizations (including denied access), sleep boundaries, late edits/deletions and Watch out-of-range, day transitions, accurate per-device projections.
- [ ] Product completeness: extend derived-state composition to widgets, reminders and background reports without persisting HealthKit results to cloud or iCloud backup.
- [ ] Compliance and privacy manifest/App Store disclosures review before approving version 1.4.

### Local widget and reminder reconciliation, 2026-10-12
- [x] Reminder schedules consume ephemeral local HealthKit completion projections, not CloudKit rows.
- [x] Widget reads a transient App Group cache projection outside normal saved snapshots; cache excluded from iCloud backup.
- [x] Clear widget projection when final HealthKit rule is disconnected; regenerate after manual overrides.
- [x] Signed iPhone 13 Debug build and on-device installation/launch succeeded.
- [x] Full 149-test simulator regression passed.
- [ ] Real HealthKit authorization / permission-denial / sample parity on physical iPhone and Watch still requires interactive QA.
- [ ] Verify automatic results, iPhone widget and watch complication visually with actual health readings.
- [ ] Refresh local App Store privacy disclosures before release.

### In-app language picker (1.4)
- [x] Add language selector to the ☰ Manage screen (available even before the first habit).
- [x] Russian / English / Spanish and System default, stored locally.
- [x] Apply selected language immediately to iPhone UI and ChickMark landing-page links.
- [x] Localization audit RU/EN/ES and 150 automated unit tests passed.
- [x] Signed iPhone 13 installation and launch.
- [ ] Verify appearance and menu interaction manually on physical iPhone; watchOS/widget language remains controlled by its system settings.

### One-screen habit details and Arvectum typography (October 12)
- [x] Use original Arvectum brand typography: embedded PT Sans Bold (from arvectum-site) for ChickMark in top bar.
- [x] Move corporate byline (existing branded wordmark image) and dynamic app version to Manage screen; keep main header chicken + ChickMark only.
- [x] Replace scrolling detail with a 3- or 4-week responsive overview showing identity, stats, activity, HealthKit integration and primary action.
- [x] Preserve full six-week calendar and trend cards in separate History & insights sheet.
- [x] Preserve scrolling only for accessibility text sizes and detailed drilldowns.
- [x] Add iPhone 13-sized UI assertions for no-scroll habit details and relocated version/byline, passing.
- [x] Full 150 unit tests and RU/EN/ES localization audit pass.

### Compact Health automation and uniform stat tiles (October 12)
- [x] Equal fixed heights for the streak, completion %, and check-ins tiles (normal Dynamic Type).
- [x] Simplify HealthKit automation settings into one non-scrolling overview (metric, goal, connect/save, disconnect).
- [x] Remove verbose setup/Shortcuts/privacy paragraphs from automation settings; privacy policy remains accessible from Manage.
- [x] Preserve accessibility scroll support for enlarged text and inline permission/error states.
- [x] Real-device iPhone 13 signed build, install and launch succeeded.
- [x] iPhone 13 UI tests verify stat heights, HealthKit connect button visibility, and non-scrolling detail overview.
- [x] 150 unit tests passed, RU/EN/ES localization audit passed.

### About redesign and local HealthKit goal progress (October 12)
- [x] Replace cluttered Manage footer with a compact two-row Language / About panel.
- [x] Create dedicated About page with original Arvectum wordmark, app version, privacy and support links.
- [x] Display live HealthKit goal progress on Today habits: localized current/target numbers, units and a capped visual bar next to existing completion control.
- [x] Keep readings strictly in memory, not CloudKit, SwiftData, widget snapshots, WatchConnectivity, analytics or ad SDKs; do not replace manual overrides.
- [x] Refresh HealthKit on foreground/observations and every 120 seconds while Today screen is active.
- [x] Add step/distance formatting and fraction tests; 151 iOS unit tests passed.
- [x] iPhone 13 simulator UI tests: About navigation/version/legal, Manage links and habit management passed.
- [x] Signed physical iPhone 13 build, installation, launch successful.
- [ ] Confirm real current step count and auto-complete threshold visually with an opted-in physical iPhone.

### HealthKit threshold auto-check after manual undo (October 12)
- [x] Diagnosed on-device: linked steps rule 7777 and a same-day manual day mutation without check-in prevented auto-completion even at 9316+ steps.
- [x] If today's verified HealthKit reading reaches the goal, allow a local auto check-in despite a previous manual uncheck.
- [x] Preserve explicit skips, paused/archived state, existing manual completions, and historical-day manual overrides.
- [x] Regression test for target met + stale manual mutation + skipped/current/historical edge cases.
- [x] 152 unit tests pass; physical iPhone 13 signed build installed and launched successfully.
- [ ] Verify current-day checkmark visually in iPhone Mirroring using the existing linked walking habit.

### Whole-app iPhone UI/UX audit (October 12)
- [x] Visual review of Today, Detail, Manage, About, New habit and dark mode on iPhone 13 simulator.
- [x] Remove unsolicited keyboard and give Save/Done a discoverable textual control.
- [x] Compact schedule presets responsively; expose current/target on multi-check rows.
- [x] Support large-text branded toolbar and legible seven-column calendar dates.
- [x] Update UI test navigation after custom Today header refactor; add screenshots and regression tests.
- [x] Run localization audit, 152 unit tests and iPhone 13 UI smoke tests.
- [ ] Broaden manual device-by-device review to Apple Watch, widgets, advertisements and iPad (if supported), separately from iPhone audit.

### 1.4 Watch/widget and ad-delivery audit (October 12)
- [x] Watch: remove duplicate 3/5, fix 0/N progress bar, clear yesterday's manual-override state.
- [x] Simulator visual review of Watch SE 40 mm screen; watch app + complication build.
- [x] iPhone widget extension builds; projection, date rollover and commands unit-tested.
- [x] Replace involuntary Yandex Debug demo ID with live R-M-20183085-1; demo is opt-in.
- [x] Add debug-only About > Yandex Ads diagnostics of actual request/load/failure.
- [x] Verify partner.yandex.ru outage (HTTP 503); do not infer placement approval or no-fill status.
- [ ] After infrastructure recovery, verify Yandex placement registration, ad fill and first revenue impressions in YAN.
- [ ] Physical Watch and actual Home/Lock Screen widget manual audit.


### October 13 — final Watch/widget QA pass after RDC recovery
- [x] RDC command execution restored; pulled GitHub branch and verified a clean worktree before changes.
- [x] 155/155 iOS unit tests; RU/EN/ES localization audit.
- [x] iPhone widget extension, Watch app, complications, and signed physical-device app builds pass.
- [x] Physical iPhone 13 + Apple Watch SE installs succeeded; physical Watch app launch confirmed.
- [x] Watch SE simulator RU/EN screenshots visually reviewed.
- [x] ChickMark appears in SpringBoard gallery; small and medium widgets placed successfully on iPhone 13 simulator.
- [x] Empty widget layout cleaned: short small-widget text, no 0/0 on medium/lock and Watch complications.
- [ ] Real nonempty widget interactive check/uncheck/refresh on physical phone, offline and day rollover.
- [ ] Physical WatchConnectivity + watchOS HealthKit consent + tap on modular watch-face complication.
- [ ] Manually place and screenshot all three Lock Screen widget formats and Watch face families.

### 2026-10-13 — critical physical Watch crash on startup
- [x] Found missing watchOS `NSHealthShareUsageDescription` despite on-watch HealthKit authorization, which can cause a fatal privacy termination when a HealthKit-linked habit arrives from iPhone.
- [x] Added permission string in Watch Info.plist and canonical XcodeGen project.yml, RU/EN/ES localizations embedded in watchOS package.
- [x] Added runtime guard before HealthKit authorization and release-time localization/privacy regression check.
- [x] Physical Watch and iPhone signed builds succeeded; 155/155 iOS unit tests and localized permission audit passed.
- [x] Updated packages installed on both physical devices without deleting data; Watch extension process accessible.
- [ ] Confirm foreground app remains open on physical unlocked Watch and approve HealthKit prompt if displayed; remote launch previously denied by watchOS when navigation away from clock was prohibited.

### App Store review — 1.4.0, 13 October 2026
- [x] Replaced unsubmitted 1.3.1 draft with 1.4.0; added four localized release notes and automatic publication after approval.
- [x] Fixed ITMS-90683 HealthKit purpose strings for both iOS and Watch, built and uploaded release build 8.
- [x] Attached processed VALID build 8 to the 1.4.0 App Store version.
- [x] Submitted review ID e8dbe148-4328-4437-bd1b-e0d47a39235b, verified WAITING_FOR_REVIEW and submittedDate 2026-10-13T05:20:06Z.
- [ ] Apple approval and automatic release.
