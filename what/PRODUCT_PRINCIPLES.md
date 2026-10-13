# What? — Product Principles

**Decision: 2026-10-13.**

> **Catch the thought before it disappears. Analyze it later.**
>
> **«Запиши мысль, пока она не ушла. Разберёшь потом».**

## Capture is the product

The normal experience is equally easy on **iPhone and Apple Watch**. On iPhone: **open What? → tap a single large microphone button → speak → stop and save**. On Watch: **tap the complication → speak → stop and save**.

- Capture must not depend on network, transcription permission, indexing, language models, Siri, or login. Watch capture works independently of iPhone presence, while iPhone capture needs no Apple Watch.
- Original audio remains the source of truth. On the Watch, retain it through failed transfers, reboots and lost ACKs; delete the local outbound copy only after confirmed durable receipt on iPhone.
- Do not block starting recording on postprocessing, pending model downloads or organizing the library.
- Make start/stop state and successful durable save obvious. Minimize screens, prompts and configuration after initial microphone permission.
- Preserve interrupted-capture recovery, stable UUID/deduplication and local-first privacy.

### Measurable acceptance targets (not current claims)

- Tap-to-record start target: **2 seconds or less at p95**, measured on the physical Watch under normal ready conditions; log cold launch separately.
- No lost saved recordings during Watch offline periods, app termination, Watch restart, multiple queued recordings, ACK loss/retry and reconnection (verify across repeated stress runs).
- Instrument tap, microphone start, local file finalization, enqueue, transfer and iPhone ACK times in local diagnostics. Never upload speech for telemetry.

## Primary iPhone experience

- App launch opens one Shazam-inspired large microphone button, not the notes inbox.
- One tap starts phone capture immediately; only the first OS microphone permission dialog may intervene.
- A bottom My recordings card opens the existing full inbox, search, playback, archive, transcription and export UI.
- The library has a one-tap return to Capture. The widget and record deep link retain their instant behavior.
- Recordings are preserved independently of search, cloud services or transcription.

## Review happens later

Once an original recording is safely saved, the iPhone can perform optional, repeatable tasks: offline transcription; correction; playback; timeline/archive; export; literal text search; and, later, clustering, summaries, reminders and more advanced analysis.

Recording success does not depend on any of these. If transcription or search fails, the audio remains playable and exportable.

## Siri / App Intents: optional future convenience

Consider Siri / App Intents / Shortcuts to trigger supported user-authorized actions, find notes or initiate post-capture analysis. The capabilities of Siri and Apple Intelligence vary by device/OS, and user authorization/availability must be tested rather than assumed. Siri must never be necessary to record.

## Explicit scope cut

Freeze further custom semantic embedding, RuWordNet ontology, MiniLM, Qwen, and phrase-atlas development. Ask memory is an experimental review feature, not a promise of general question answering. Retain existing research only as optional historical experiments.

Commercial redistribution rights for the private RuWordNet-derived dataset bundled in build 22 are unresolved; do not put this corpus in GitHub or ship it in a public App Store release without clear permission or replacement with a licensed dataset.

## Next engineering order

1. Measure and optimize one-tap iPhone and Apple Watch microphone readiness.
2. Verify robust offline local save, queue, transfer/ACK, retransmission, crash and reboot recovery.
3. Refine fast iPhone review: audio playback, transcription status, transcript edit, simple correct search and export.
4. Only then test Siri/Shortcuts convenience.
5. Validate advanced AI analysis separately with representative tests; never put it on the capture critical path.

**Decision filter:** Does a feature reduce friction or improve safety of catching a fleeting thought? If not, it must not delay Capture.
