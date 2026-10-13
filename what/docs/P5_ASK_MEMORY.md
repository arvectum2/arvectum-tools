# What? — P5 Ask memory, first extractive stage (2026-10-13)

## User interface
- Smart search now has two modes: **Find notes** and **Ask memory**.
- Find notes separates **Word and number matches** from **Similar by meaning**. The ranking/scores remain local.
- Ask memory is intentionally **extractive**. It presents up to three source excerpts, original timestamps and a tap-through to original audio/transcript. A disclaimer explains that it is not a generated answer.
- If no relevant source is found, show **Not enough evidence** instead of constructing unsupported prose.
- The result is not derived from audio that has no saved transcription, and deleted recordings remain excluded by the repository/tombstone index.

## Retrieval and reliability
- Ask memory strips common Russian question/filler terms only for lexical matching, e.g. "Где я оставил ключи?" -> "ключи"; the original complete question is still used for Apple's contextual embedding retrieval.
- Lexical evidence is required at a strong local score, while weak semantic vector neighbors below score 0.81 are excluded from Ask mode. This gate is a heuristic, not a calibrated factual-confidence score.
- Every displayed snippet is an unchanged substring of the saved transcript, linked by recording UUID and source creation date. No synthetic descriptions, summaries or extra factual statements.
- Processing stays on-device; search never downloads an embedding model without the user's separate confirmation.

## Validation
- [x] iOS simulator builds successfully, full unit suite passed.
- [x] Question normalization tests; simulated note about misplaced keys found as a real transcript excerpt; unrelated missing topic abstains.
- [x] Weak semantic results below threshold rejected and answer sources capped at three.
- [x] Signed physical iPhone build 18 installed; 17 recordings, 17 M4A audio files, 15 transcripts and all existing backed-up app-support files were preserved byte-identically (2026-10-13).
- [ ] User validation of Ask memory with a relevant recorded fact, then a question absent from all notes.
- [ ] Russian paraphrase quality evaluation on-device with user-reviewed expected sources; do not assert reliable generalized question answering before this.
