# photo-pdf-to-size — A5 isolated release candidate 1.0.2 (14)

**State as of 2026-10-15: SOURCE-CANDIDATE ONLY. Not uploaded, not submitted, not public.**
**ASC external source:** authenticated read-only lookup on 2026-10-15: public 1.0.1 (13) READY_FOR_SALE confirmed through ASC 2026-10-15.
**Bundle:** `ru.arvectum.tools.tosize`. **Proposed** version/build: `1.0.2 (14)`.
**Source base:** `origin/main@657ce0d6bcce78cf35e07135ef5871da8e07c0ff`, plus ONLY the `photo-pdf-to-size/ios/project.yml` version/build changes in this isolated release branch and this release document. No old release source is blindly merged.
**Release branch:** `release/photo-size-1.0.2-build14-a5-20261015`.

## Included changes — source-only since last submitted build

PR #72: preserve displayed PDF orientation and render 90/270-degree pages using PDFKit. Source-file integrity tests for JPEG, PNG, HEIC and PDF; new CI source regression step. Rasterization warning remains.

## App Store What’s New — draft, not posted

**ru-RU:** Исправили ориентацию страниц при сжатии PDF: повороты на 90° и 270° теперь сохраняются корректно.

**en-US:** Fixed page orientation when compressing PDFs with pages rotated 90° or 270°.

## Pre-submission gates

- [x] Isolated branch from frozen `657ce0d6bcce` base; no automatic merge to `main`.
- [x] Reserved unique marketing/build number; cross-target version consistency is enforced by `project.yml`.
- [ ] Clean generated Xcode project builds on generic iOS Simulator (and watchOS if applicable).
- [ ] Full app unit/UI regression and clean GitHub Actions release-branch checks.
- [ ] Distribution-signed `.xcarchive` with correct team, entitlements and embedded extensions; `.ipa` SHA-256 and signing/profile receipt. **Do not claim signing from a simulator build.**
- [ ] Verify bit-by-bit exported bundle version/build and that any signed artifact includes only intended files.
- [ ] **Physical/external:** Physical post-release Files/Photos imported fixtures, save/share and PDF orientation+memory, consent/ATT, actual native/banner YAN fill and partner impressions. GitHub issue #73. Real device installation state cannot be concluded from CoreDevice listing.
- [ ] **Apple:** actual new App Store version + build association, review notes and required locales only after preceding gates pass. No upload or submission in A5 draft phase.

## Existing QA evidence
- photo-pdf-to-size/docs/A4_POST_RELEASE_QA_2026-10-15.md
- Verified external version state is separate from the submitted build, local code tests and simulated user flows.
- Never use another app's signed IPA or release profile. No user data deleted, reinstalled, replaced, uploaded or reset in preparing this candidate.
