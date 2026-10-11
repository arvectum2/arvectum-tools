# What? — Roadmap

**Branch:** `feature/what`  
**Status:** ACTIVE / MVP discovery and implementation.

## Product concept

**What?** is a local-first voice memory app for Apple Watch + iPhone.

Core promise:

> **Think it → tap once → say it → forget it. What? remembers.**

The product is not positioned as a generic voice recorder. Its core job is to capture a thought from the wrist with minimum friction, preserve the original audio reliably, turn it into text, and later help the user recall and structure what they said.

## Product principles

- [ ] One tap from the Apple Watch watch face should be enough to start capture.
- [ ] A captured thought must never be lost because the iPhone is offline, unreachable, locked, or the app is not running.
- [ ] Original audio is the source of truth and is retained unless the user deletes it.
- [ ] Transcript, chunks, embeddings, summaries, tags and AI answers are derived data and can be rebuilt.
- [ ] Local-first by default; no account or cloud dependency for the core product.
- [ ] AI must never overwrite or replace the original recording/transcript.
- [ ] Every AI-generated answer should be traceable back to the source note and, when possible, the source audio timestamp.
- [ ] Keep the capture flow extremely small; advanced functionality belongs on iPhone, not in the Watch capture UI.

---

## P0 — Reliable Capture

**Goal:** the user taps once on Apple Watch, speaks, stops, and can trust that the thought is saved.

### Watch capture flow
- [x] Create watchOS app target.
- [x] Add a complication / watch-face entry point for fast launch.
- [x] Opening from the capture entry point immediately starts recording after permissions are granted.
- [x] Give immediate haptic confirmation when recording starts.
- [x] Minimal recording UI: timer + stop/finish control.
- [x] Give haptic + visual confirmation after the recording is safely persisted.
- [x] Store each recording locally on Apple Watch before any transfer attempt.
- [x] Assign every recording a stable UUID and creation timestamp.

### Reliable transfer
- [x] Maintain a durable local outbound queue on Apple Watch.
- [x] Transfer recordings to the paired iPhone opportunistically/background where supported.
- [x] iPhone stores the incoming file before acknowledging receipt.
- [x] iPhone sends ACK for the recording UUID.
- [x] Watch deletes its local transfer copy only after confirmed ACK.
- [x] Transfer is idempotent: duplicate delivery must not create duplicate notes.
- [x] Interrupted transfer resumes/retries without user action.
- [x] Provide a small Watch status for pending/unsynced captures.

### P0 acceptance tests
- [x] Capture with iPhone nearby.
- [ ] Capture with iPhone disconnected/unreachable.
- [ ] Capture several notes while iPhone is unavailable, then reconnect.
- [x] Force-close the iPhone app before transfer.
- [x] Restart the Watch app process with a pending item.
- [ ] Reboot Watch/iPhone with pending items.
- [x] Simulate duplicate delivery (repository idempotence test).
- [ ] Verify no successful capture disappears in any tested case.

**Definition of done for P0:** capture is boringly reliable.

---

## P1 — Voice + Text

**Goal:** every note contains the original audio and a searchable transcript.

- [ ] Store original audio on iPhone.
- [ ] Add local speech-to-text pipeline.
- [ ] Store transcript separately from original audio.
- [ ] Keep transcription state: pending / processing / complete / failed.
- [ ] Retry failed transcription without affecting the audio note.
- [ ] Store word/segment timestamps where available.
- [ ] Allow playback of the full original recording.
- [ ] Allow editing/correcting the transcript without modifying the audio.
- [ ] Preserve both original transcript result and user-edited text if useful for provenance.

### P1 acceptance tests
- [ ] Russian speech.
- [ ] English speech.
- [ ] Mixed Russian/English note.
- [ ] Noisy environment.
- [ ] Long pause in the middle of a thought.
- [ ] Transcription failure/retry.
- [ ] Audio remains available even when transcription fails.

---

## P2 — Voice Inbox

**Goal:** a simple iPhone home for everything captured from the wrist.

- [ ] Today view.
- [ ] Yesterday / chronological history.
- [ ] Note card: time, transcript preview, duration, sync/transcription state.
- [ ] Tap note → full transcript + audio playback.
- [ ] Search by exact text.
- [ ] Delete/archive note.
- [ ] Edit transcript.
- [ ] Basic local metadata: createdAt, duration, language, source device.
- [ ] Keep the main screen fast even with a large note history.

### UX principle
The default screen should answer one question immediately:

> **What did I say?**

---

## P3 — Apple Notes / Shortcuts integration

**Goal:** What? remains the source of truth, but notes can flow into the user's existing system.

- [ ] Standard Share Sheet export.
- [ ] Export transcript to Apple Notes.
- [ ] Export/share original audio.
- [ ] Add App Intents for captured notes.
- [ ] Add Shortcuts-friendly actions.
- [ ] Provide a simple onboarding path for an optional "send/copy to Apple Notes" automation.
- [ ] Do not make core capture dependent on Apple Notes integration.

### Export payload
- [ ] Transcript.
- [ ] Capture date/time.
- [ ] Optional title generated from first sentence / user choice.
- [ ] Audio attachment when the destination supports it.

---

## P4 — Semantic Memory

**Goal:** retrieve ideas by meaning, not only exact words.

Example:

> **"What did I say today about Project X?"**

- [ ] Split transcripts into semantic chunks instead of embedding the whole recording as one vector.
- [ ] Preserve chunk → note → audio timestamp linkage.
- [ ] Add local embedding provider abstraction.
- [ ] Generate embeddings locally where practical.
- [ ] Store local vector index.
- [ ] Semantic similarity search across chunks.
- [ ] Combine semantic search with filters: today / yesterday / date range.
- [ ] Return the most relevant source snippets with note timestamps.
- [ ] Deduplicate overlapping chunks/results.
- [ ] Rebuild embeddings/index from source transcripts if required.

### P4 acceptance queries
- [ ] Exact project name.
- [ ] Synonym/paraphrase not present verbatim in transcript.
- [ ] "What ideas did I have about X?"
- [ ] "What did I say about X today?"
- [ ] Same subject mentioned across several recordings.

---

## P5 — Ask Your Memory

**Goal:** turn retrieved voice fragments into a structured answer without inventing facts.

Example output:

> **Ideas about Project X today**
> 1. ...
> 2. ...
>
> **Decisions**
> - ...
>
> **Open questions**
> - ...

- [ ] RAG pipeline over retrieved transcript chunks.
- [ ] Local/system LLM when supported.
- [ ] Graceful fallback to semantic search results when no suitable local LLM is available.
- [ ] Structured categories: ideas / decisions / tasks / questions.
- [ ] Every generated item retains links to its source note(s).
- [ ] Jump from an answer to the exact note.
- [ ] Jump to the relevant audio timestamp where timestamp data is available.
- [ ] Explicit instruction to the model not to invent unsupported items.
- [ ] Evaluate answer faithfulness against retrieved sources.

---

## Backlog after the core product works

- [ ] Automatic project/topic clustering.
- [ ] Suggested tags.
- [ ] Daily/weekly "what you talked about" digest.
- [ ] Auto-detected action items.
- [ ] Reminders generated from spoken notes, only with explicit user confirmation.
- [ ] Cross-device iCloud sync as an optional layer, without weakening local-first capture.
- [ ] Android / Wear OS feasibility study after the Apple Watch product proves demand.
- [ ] Additional export targets beyond Apple Notes.
- [ ] Privacy-preserving optional cloud models for users who want stronger AI than the local device provides.

---

## Non-goals for MVP

- [ ] No social features.
- [ ] No account requirement.
- [ ] No cloud backend required for capture.
- [ ] No generic long-form meeting recorder in the first version.
- [ ] No complex folders/taxonomy before semantic retrieval proves insufficient.
- [ ] No AI dependency in the critical capture path.

---

## Current implementation order

1. **P0 Reliable Capture**
2. **P1 Voice + Text**
3. **P2 Voice Inbox**
4. **P3 Notes / Shortcuts**
5. **P4 Semantic Memory**
6. **P5 Ask Your Memory**

The first release candidate should not move forward until P0 reliability tests are consistently green.
