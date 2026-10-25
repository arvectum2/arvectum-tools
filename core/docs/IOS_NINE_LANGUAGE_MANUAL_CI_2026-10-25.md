# Core C5.8 — on-demand iPhone UI localization CI

Date: 25 October 2026.

## Purpose

One GitHub Actions manual-dispatch entrypoint can run the nine-locale
native iPhone UI regression across four apps. The workflow is opt-in:
it has ONLY workflow_dispatch (no push, PR or schedule trigger), so
a normal commit does not launch four billable macOS jobs.

Workflow: .github/workflows/ios-nine-language-ui-matrix.yml
Name: iOS nine-language UI matrix (manual)

## Matrix / test selection

| App | XCUITest classes selected |
| --- | ---: |
| Photo/PDF | 8 |
| Pushkin | 8 |
| Uhvat | 7 (French is in CoreLanguageCoverageUITests) |
| ChickMark | 7 (Spanish is in CoreLanguageCoverageUITests) |
| Total | **30 classes covering 36 app-locale pairs** |

Each job first runs the Core localization audit and registry tests,
generates its Xcode project, creates and boots a unique iPhone 18 Pro
iOS 27.0 simulator, runs the existing native localization UI suites,
and exports its XCTest result bundle plus log for seven days.
Every simulator is shut down/deleted, even after job failure.

Tests use synthetic local app fixtures, no personal notification
history, real voice recordings, iCloud habits or photo library.
No code signing, Apple submission, publishing or TestFlight actions.

## Verified in this task

- [x] YAML parsed with Ruby Psych and exposes 4 matrix entries.
- [x] All shell scripts passed bash -n syntax check.
- [x] 30 XCUITest source class files found in the specified targets.
- [x] Core 46 localization registry tests PASS.
- [x] Existing Mac mini independent iPhone UI evidence for all
  36 app-locale pairs and 10 new baseline/missing suites already PASS
  (see IOS_NINE_LANGUAGE_UI_MATRIX_2026-10-25.md).
- [ ] This new GitHub workflow itself has NOT been dispatched or run
  on xcode-27 runners. Do not call it green until real jobs complete.

## How to run later

GitHub repository > Actions > iOS nine-language UI matrix (manual)
> Run workflow > choose main > Run workflow.

This is an opt-in quality gate, not an App Store release gate.
Physical iPhone/Watch, native speaker proofreading, long text and
VoiceOver still require separate release QA.
