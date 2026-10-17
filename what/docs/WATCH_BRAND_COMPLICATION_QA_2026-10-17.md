# Ухват — фирменный значок на циферблате, 2026-10-17

**Gate: owner-confirmed visual acceptance PASS on their actual Watch face; production upload remains STOPPED pending roadmap/release-scope review.**

## Defect reported by owner
- Released Watch complication appears as generic SF microphone instead of UhWhat's navy/mint identity.
- Separate QA watch face complication appeared as an empty square.
- Owner requires same recognisable icon as UhWhat app, not generic mic.

## Implemented
- Full-color complication mode embeds and displays byte-for-byte the same PNG as Watch AppIcon (WhatComplicationIcon image in its widget-extension asset catalog). Exact SHA-256 equality enforced by what/tests/watch_complication_brand_smoke.sh.
- Accented/tinted modes draw a SwiftUI vector shape with exact contour coordinates from what/ios/tools/generate_brand.swift; do not rely on a template-rendered icon file that can become a block or disappear.
- Supports watch face circular, rectangular, inline and corner families.
- Keeps widgetURL(what://capture) on production and widgetURL(whatqa://capture) on QA plus the separately physically accepted foreground-autostart fallback. No changes to watch audio queue, storage or ACK code.
- watchOS simulator build PASS; signed QA9 iPhone/Watch build PASS; Assets.car in Watch complication extension contains new image; brand smoke test PASS, vector contours match generator.
- QA9 installed **in place** on physical iPhone 13 and Apple Watch SE: ru.arvectum.tools.what.qa / .watch v1.0.2 (9). Never uninstalled production or QA. Backups on ArvectumSSD under builds/what-complication-qa9-20261017/device-backup.
- After install read-only verification: 17/17 iPhone QA Application Support files remained with same names and sizes. Watch durable queue remained zero pending. No user note deleted.
- The previously exported production 1.0.2 (7) IPA (SHA-256 39ae71cc...) is superseded for release; it predates the branding change.

## Watch face acceptance checklist (OWNER INPUT REQUIRED)
- [x] **Physical owner PASS (2026-10-17):** user confirmed «проверка прошла. значок правильный, запись сохранилась». Correct branded icon now appears on their actual Watch face instead of blank square/microphone. Exact face/family and whether it is tinted were not separately identified.
- [ ] Optional cross-face QA: other widget families and tinted/one-color watch face appearance remain unverified. watchOS may apply tint and disallow navy background in accented mode; silhouette should remain recognizable.
- [x] **Owner-reported test flow PASS (2026-10-17):** user responded «проверка прошла. значок правильный, запись сохранилась» after the prescribed one-tap/record/save check. Recording saved, but sound playback and duplicate count for this exact QA9 note were not explicitly stated. Earlier QA8 sound + no-duplicate acceptance remains valid for that earlier build.
- [ ] Explicit QA9 confirmation of playback/no duplicate, if required for final release acceptance.
- [x] The previously reproduced generic microphone / empty square appearance no longer occurs on owner's tested QA9 watch face. No extra image needed for this case.

## Other roadmap, not silently declared complete
Full 27-item audit: what/docs/WHAT_ROADMAP_AUDIT_2026-10-17.md (4 ready, 12 partial, 11 open). Release scope selection is pending owner decision. Text/video/iPad/Duo, reminder/ChickMark, advanced search and physical transcription QA were never declared delivered by this branding fix.

## User verification result (2026-10-17)

**Owner:** «проверка прошла. значок правильный, запись сохранилась». The actual watch-face brand image and saved capture are confirmed. Do not silently treat sound/dedup or alternate face families as proven from this short report. App Store upload remains on hold by owner's explicit instruction.
