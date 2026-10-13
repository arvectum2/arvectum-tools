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


## Build 19 — semantic retrieval repair and real-model validation

- User's physical tests: "цветок" did not retrieve "эдельвейс"; "журнал" did not retrieve "дневник"; "красота" did not retrieve "эстетика".
- Root defect: LocalSemanticSearch only allowed semantic embeddings for >=2 search terms, even in Ask memory. This was intentional and desirable for strict Find notes single-word queries ("тест" must never match "текст"), but not suitable for Ask memory.
- Second issue: Ask memory discarded approximate semantic hits with an additional cutoff above the search engine cutoff, causing unexplained false negatives.
- Ask memory now allows embeddings for any query length, compares to mean contextual passage vector **and** candidate contextual word vectors. The local cache stores derived numeric vectors only; no duplicated plaintext transcripts. Cache version incremented for schema change.
- Find notes stays strictly lexical for one-word queries, retaining prior regressions.
- Ask memory explicitly shows whether semantic assets are loaded on the device and offers the existing explicit Apple model download confirmation when unavailable. No silent download.
- Ask memory displays possible *source excerpts*, not a generated answer. Similarity is not a factual-confidence score and user should verify original audio.
- [x] Simulator regression suite validates one-word Ask vs Find isolation, the three semantic pairs with injected deterministic vectors, and no hallucinated synonyms when assets absent.
- [ ] The three real Russian Apple embedding cosine scores on physical iPhone remain unmeasured; the developer Xcode probe cannot start while the iPhone is locked.
- [x] Signed build 19 installed on physical iPhone. All 17 recording records, 17 original audio files, 15 transcripts and other app-support files preserved byte-for-byte.
- [ ] User validation on physical iPhone build 19; do not assert the three target pairs work solely from synthetic tests.
