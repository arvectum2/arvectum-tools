# What? — Russian semantic model evaluation, 2026-10-13

## Confirmed failure
The user reported that the Apple Russian model appears installed (load and vector inference succeeds) but Ask memory returns unreliable results or abstains. Raw contextual cosine scores near 1.0 do not measure real retrieval quality. The asset request can return immediately for already-available assets. App model-status checks establish operational availability, not semantic accuracy.

## Local-only research
- 15 real transcripts from the existing iPhone backup were evaluated on the Mac mini; user text was never transmitted or included in the evaluation output.
- Third-party research weights were downloaded to ArvectumSSD/Arvectum/models/what-semantic-research, outside Git; none were sent to the iPhone.
- Correct inference methods: E5 asymmetric query/passage prefixes, attention-mask mean pooling and L2 normalization; MiniLM mean pooling and L2 normalization; Qwen3 Embedding GGUF last-token pooling via local llama.cpp, with plain and instruction-prefixed queries.
- Exact user-provided keyword-pair tests are necessary but *not sufficient*. Acceptance requires ranking actual saved notes above irrelevant notes.

| Local candidate | Weight size | Isolated journal/diary pair | Actual diary note rank among 15 | Actual Edelweiss note rank for flower |
|---|---|---|---|---|
| multilingual-e5-small INT8 ONNX | 118 MB (+17 MB tokenizer) | 1/10 | 11/15 | 14/15 |
| paraphrase-multilingual-MiniLM-L12-v2 INT8 ONNX | 118 MB (+17 MB tokenizer) | 1/10 | 7/15 | 10/15 |
| Qwen3-Embedding-0.6B Q4_K_M GGUF | ~396 MB (~378 MiB) | 1/10 | 13/15 plain, 10/15 instructed | 14/15 plain, 13/15 instructed |

The literal string aesthetic in Russian nominative ("эстетика") did not occur in the 15 transcripts. It may be inflected or paraphrased; this test needs human-verified relevant notes.

## Decision
- Do NOT ship any tested weights to the phone just because pairwise similarity looks good; all failed note-level retrieval for the reported cases, with large storage costs.
- P5 semantic retrieval quality remains blocked. Design short salient-term/phrase indexes and Russian morphological normalization, preserve on-device privacy and original audio/transcripts. Evaluate 3 positive user examples and at least 10 unrelated controls; reject or abstain on weak/ambiguous evidence.
- A single rare entity-to-class association ("эдельвейс" -> "цветок") may need offline concept knowledge enrichment, not sentence embedding alone. Do not hardcode the user's three examples as fake dictionary synonyms.
- Benchmark local prototypes on Mac mini first; ask before downloading any alternative third-party model to the iPhone.
- Keep strict Find notes regression "тест" != "текст", and source-linked Ask memory as experimental.

## Public sources
- Apple Natural Language: https://developer.apple.com/documentation/naturallanguage/nlcontextualembedding
- Apple similarity embeddings: https://developer.apple.com/documentation/naturallanguage/nlembedding
- https://huggingface.co/Xenova/multilingual-e5-small
- https://huggingface.co/Xenova/paraphrase-multilingual-MiniLM-L12-v2
- https://huggingface.co/n24q02m/Qwen3-Embedding-0.6B-GGUF
