# Ухват — фирменный значок на циферблате, 2026-10-17

**Gate: physical visual test OPEN, production upload STOPPED.**

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
- [ ] Add/reselect «Ухват QA — Запись» complication in watch face edit mode. If watchOS shows an old cached icon, remove this complication slot and select it again. Check that a mint logo silhouette / correct app icon appears instead of an empty square or mic.
- [ ] Check appearance on a full-color face, and tinted/one-color face if available. Note: watchOS may apply face tint and disallow maintaining the navy background in accented mode. Recognisable silhouette is still required.
- [ ] Tap complication **once**, confirm recording starts with no extra tap. Speak a few seconds, press Stop or Digital Crown, verify playable audio on iPhone QA, exactly one note.
- [ ] If still blank or mic, get screenshot of the face/complication from owner or device and investigate WidgetKit face rendering / family-specific availability. **Do not submit to App Store.**

## Other roadmap, not silently declared complete
Full 27-item audit: what/docs/WHAT_ROADMAP_AUDIT_2026-10-17.md (4 ready, 10 partial, 13 open). Release scope selection is pending owner decision. Text/video/iPad/Duo, reminder/ChickMark, advanced search and physical transcription QA were never declared delivered by this branding fix.
