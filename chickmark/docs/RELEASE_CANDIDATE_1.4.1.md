# ChickMark 1.4.1 (9) — release candidate / NOT published

**Baseline:** published ChickMark 1.4.0 (8), installed on paired iPhone 13 and Apple Watch SE.
**Source:** development branch feature/chickmark-healthkit-1.4, including merged PRs #7, #10, #11, #13 and #15.
**Candidate version:** 1.4.1 (9) for all iOS / watchOS / widget targets.
**Privacy:** raw HealthKit readings remain local to each device; the iPhone sends only the completion Boolean to the paired Watch, not step samples or counts.

## Candidate changes
- Inline step/current-goal progress on Apple Watch, refreshed while the watch app stays open.
- Automatic HealthKit completion status included in iPhone-to-Watch snapshots without writing synthetic history into SwiftData or CloudKit.
- Foreground HealthKit polling adjusted from 120 to 60 seconds on iPhone and Watch. Underlying Apple Health sample availability and background delivery remain scheduled by iOS; one-minute end-to-end latency is NOT guaranteed.
- One Create/Edit Habit sheet contains Apple Health connection, metric, goal and disconnection, without the old Smart automations subpage.
- Localized Hide keyboard action in Create/Edit, safer grouped step-goal input and preservation of the Health opt-in timestamp.

## Required release gates (not yet all satisfied)
- [ ] Check GitHub Actions CI green (unit, essential accessibility/UI, archive). This remote gate is **separate** from local simulator verification.
- [x] Archive smoke 1.4.1 (9) PASS: matching iPhone/Watch/widgets, all four privacy manifests and zero static audit errors. Signed local development archive PASS including strict codesign validation for all four bundles.
- [ ] Non-destructive backup of existing iPhone user data using in-app JSON export, saved somewhere accessible before touching published app. The signed candidate currently has a development provisioning profile and development push environment, so **do not overlay production CloudKit habits**.
- [ ] Owner's explicit approval for physical in-place installation or TestFlight distribution. Do not uninstall, reset, or overwrite without this gate.
- [ ] Real iPhone HealthKit permission + target edit and auto check at a new, small step threshold, with measured refresh times.
- [ ] Real Watch HealthKit permission, current/goal display, automatic completion propagation and stale-data recovery, online/offline reconciliation and manual override.
- [ ] Verify history, widget, Watch complication and ad banner survive the in-place upgrade.
- [ ] Obtain separate approval before uploading an archive to TestFlight or App Store; submission/review/publication are NOT implied by candidate compilation.

## Local build and test evidence (2026-10-14)
- Full HabitsByArvectumTests: **163/163 passed** on iOS 27 iPhone 13 simulator.
- Two essential UI tests: **2/2 passed** on iOS 27 iPhone 13 simulator (accessibility audit across core screens, multi-check history).
- Previous unified Health editor and keyboard UI smoke: passed; Watch target built successfully after the Health completion fix.
- Release hygiene, localized resources RU/EN/ES, store assets and architecture contract: passed.
- Unsigned Release archive smoke: passed, version 1.4.1 (9), all four targets, privacy checks without static audit errors.
- Signed development archive built and strictly verified; all four embedded bundles show 1.4.1 (9), codesign validates. Archive file on Mac mini: /Volumes/ArvectumSSD/Arvectum/builds/chickmark/1.4.1-9/ChickMark-1.4.1-9-signed.xcarchive
- Signed app's embedded profile: iOS Team Provisioning Profile, development; iPhone UDID authorized, get-task-allow true and aps-environment development. A successful signature does NOT make an App Store/production CloudKit-safe in-place update.
- No upload to TestFlight/App Store. No modifications to the paired physical devices.

## Physical QA confirmed for the published 1.4.0 (8)
The owner reached the step goal; while ChickMark stayed open its displayed progress remained stale. After opening Apple Fitness and accepting new terms, Health data appeared in ChickMark and its checkbox auto-completed. The published Watch did not update progress or checkbox. It is unknown whether accepting Fitness terms, HealthKit delivery delay or both caused the original lag. These are not equivalent to acceptance of the 1.4.1 candidate.
