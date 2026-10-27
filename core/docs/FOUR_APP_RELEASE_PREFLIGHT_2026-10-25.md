# Four-app release preflight — 25 October 2026

Source: `feature/portfolio-roadmaps-zh-hant-20261025`, HEAD `703ad54` at start of run; no source changes in this preflight.

## Verified
- `python3 -m unittest discover -s core/tests -q`: 60/60 PASS.
- `python3 core/tools/localization_portfolio.py --audit`: PASS.
- `xcodegen generate --quiet`: all four Xcode projects PASS.
- `xcodebuild -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`:
  - Photo/PDF: BUILD SUCCEEDED, `/tmp/arvectum-four-rc-photo.log`.
  - Pushkin: BUILD SUCCEEDED, `/tmp/arvectum-four-rc-pushkin.log`.
  - Uhvat: BUILD SUCCEEDED on retry with `-jobs 2`, `/tmp/arvectum-four-rc-what-retry.log`.
  - ChickMark: BUILD INTERRUPTED twice (parallel and `-jobs 2`), `/tmp/arvectum-four-rc-chick.log`, `/tmp/arvectum-four-rc-chick-retry.log`. **Not a passing build**; must retry to completion before release.

## Blocking issues
- Editorial localization sign-off absent for all target languages; see `EDITORIAL_RELEASE_GATE_2026-10-25.md`. No proof of native review, physical accessibility/Watch or privacy/consent QA.
- New KO only in Photo/PDF and Pushkin; PT-PT and ZH-Hant have known linguistic issues. Shipping all current source locales as approved would be misleading.
- No newly signed four-app IPA set, checksums, exact release build increments, real-device upgrade acceptance or App Store metadata reconciliation.
- Per `AGENTS.md`, no Apple upload, TestFlight, review submission or release until owner explicitly approves exact IPA versions and hashes.

**Outcome: 3/4 unsigned Release Simulator builds PASS; all four apps NOT RELEASE-READY.**

## Follow-up verification — 25 October 2026 (ARC)

The initial ChickMark interruption described above was resolved using a persistent tmux build. Verified `/tmp/chick-tmux-build.exit` = `0` and `/tmp/chick-tmux-build.log` contains `** BUILD SUCCEEDED **`. **All four Release Simulator builds now PASS.** This is not a signed device IPA or Apple submission.

ARC direct-funnel access to Mac mini and repository files confirmed. Full Core test discovery: **60/60 PASS**; localization structural audit: **PASS**. Editorial sign-off, signed four-app IPA set, real-device checks, and owner-specific Apple release approval remain open.
