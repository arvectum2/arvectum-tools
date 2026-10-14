# Where? — Product Roadmap

## MVP execution plan — 2026-10-14
**Stage:** approved concept, no working implementation independently verified. The central value proposition is photograph → remember where stored → find it entirely offline.
- [ ] W0: capture object and storage-place photos, durable local records, browsing and corrections on actual iPhone.
- [ ] W1: add offline OCR, editable extracted labels and source-photo provenance.
- [ ] W2: add local embeddings and hybrid text/semantic retrieval with a small grounded retrieval-quality benchmark.
- [ ] W3: acceptance in airplane mode, app restart, safe deletion, migrations and measured search latency.
- [ ] Evaluate Siri/Apple Intelligence only as optional add-on; VLM, NFC tags and Android remain beyond MVP.


**Status:** MVP concept approved; implementation status not verified.
**Owner:** Where? product only.

## Product contract
Photograph an object and its storage place, then remember and find where the object is.
MVP must work completely offline on iOS, with no account or backend.

## MVP
- [ ] Capture object photo and storage location/context.
- [ ] Persist objects and storage locations locally.
- [ ] OCR for visible text.
- [ ] On-device embeddings and semantic search.
- [ ] Browse and correct stored entries.
- [ ] Verify offline operation, data integrity and practical search latency.

## P1 — Expiry Tracking / «Сроки годности» (post-MVP)
**User need:** photograph a medicine, cosmetic or other product (or add a text-only entry), note when its package was opened, and receive a reminder when its usable lifetime ends. This must not delay W0–W3 or require network, an account, a backend, or the ChickMark app.

- [ ] **E0 · Product card:** photo (optional), title, short note, category (medicine/cosmetic/other), opening date, and optional link to an existing Where? object/storage location. Support quick entry without a photo.
- [ ] **E1 · Two expiry rules:** capture printed/absolute expiration date and separate post-opening lifetime (PAO, e.g. 2 months or 12M). Calculate the effective expiry as the **earlier** of the two when both are set; use the specified one when only one exists. Never infer a medicine's PAO or assert its safety from generic category defaults; show dates and source values for manual verification.
- [ ] **E2 · Local reminders:** user-controlled notifications (suggest 7 days before and on expiry), rescheduled when dates change, cancelled when deleted/completed, deduplicated per item, with permission-denied handling and scheduling within iOS pending-notification limits. Use privacy-safe notification text by default.
- [ ] **E3 · Review states:** «В порядке», «Скоро истечёт», «Срок истёк»; mark «Использовано» / «Выброшено»; duplicate an item to record opening a new package without re-entering its description.
- [ ] **E4 · Offline acceptance:** verify month-boundary and leap-year date arithmetic, time zones/DST, past dates, changed opening dates, reinstall/backup migration where supported, app restart, airplane mode, denied notification permission, many simultaneously tracked items, and no alerts from deleted/retired packages.
- [ ] **E5 · OCR enhancement (later):** detect printed expiry dates and PAO markings like 6M/12M from packaging photos on-device; require user confirmation before saving inferred dates. Keep OCR optional; manual input must always work.

**Architecture:** isolate product-expiry model/calculation and notification scheduler from the object-location search core so the same module could support a dedicated expiry utility later. Integration with ChickMark is optional and not required for reminders.

## Later
- [ ] Explore on-device VLM only after a lightweight offline core proves useful.
- [ ] Evaluate optional Siri/Apple Intelligence integration where technically feasible.
- [ ] Android version after iOS product validation.
- [ ] NFC tags/keyfobs: deferred hardware backlog.

No Growth or Core work is duplicated here; link to their respective roadmaps.
