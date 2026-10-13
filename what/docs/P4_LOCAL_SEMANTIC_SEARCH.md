# What? — P4 local semantic retrieval (2026-10-13)

## Scope
- Search only saved transcripts and manually written notes. Audio without text is not embedded.
- Source text is divided into short phrases (~300 characters). Each result retains its original recording UUID.
- Apple NLContextualEmbedding offers on-device contextual vectors for Russian, English and other languages on iOS 17+.
- Only already downloaded assets are used. There are no network calls during search.
- For Russian queries without assets, a distinct user-confirmed action downloads the Apple language model. Once downloaded, future searches work offline.
- Case-insensitive text/partial word coverage search is always available as fallback. The UI clearly labels which engine was used.
- Hybrid ranking prefers exact phrase matches. Results contain dated snippets and a link to original recordings, not invented text.
- Persisted semantic-search-index.json stores only SHA256 text digests and numeric vectors, not duplicate plaintext transcripts.
- A manual edit or model revision change invalidates cached vectors; deletion purges derived entries under the shared repository storage lock.
- Serial on-device inference uses a Swift actor. No third-party API or remote inference.

## Constraints
- On-device Russian semantic availability depends on locally installed Apple assets.
- Mean pooling of contextual token embeddings is a lightweight baseline, not a trained retrieval-specific model. Real paraphrase quality needs physical acceptance.
- This is retrieval, not question answering.

## Physical acceptance
- [x] Build 11 installed and byte-for-byte preservation verified for 13 recordings, 13 audio files, 6 transcripts and existing archive-state files (2026-10-13)
- [ ] Technical Watch queue information is hidden from main Inbox but accessible in Sync diagnostics
- [ ] Smart search opens, text search works, tapping a result opens the original recording
- [ ] Russian query with no exact words retrieves a relevant source when semantic model is available
- [ ] Archive results included, deleted recordings excluded
- [ ] Transcript corrections immediately reflected in search results
- [ ] Missing model does not trigger a download without confirmation
