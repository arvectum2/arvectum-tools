# What? Offline Russian semantic search research

The prototype is concept_search.py and the compiled native implementation is in ios/WhatIOS/RussianConceptSearch.swift.

Verified on 15 actual saved transcripts, without sending them anywhere:
- цветок -> note mentioning эдельвейс: rank 1
- журнал -> note mentioning дневник: rank 2
- красота -> note about красоту and эстетику: rank 1
- 20 unrelated queries: zero false results
- six additional Python graph tests and all iOS simulator tests passed.

Generate private developer-only resource, not included in Git:

    python3 what/research/generate_concept_graph.py --database /path/to/ruwordnet.db --output what/ios/WhatIOS/Resources/RussianConceptGraph.json.zlib
    cd what/ios && xcodegen generate

Requires Python pymorphy3 and a separately obtained RuWordNet database.
The 2.4 MiB graph uses raw DEFLATE (Apple Foundation NSData .zlib).
Without the local resource, code still compiles and falls back to existing search; graph integration tests require the asset.

Run prototype tests:

    cd what/research
    python -m unittest -v test_concept_search

LICENSING: The RuWordNet website https://www.ruwordnet.ru/en/ states noncommercial use and CC BY-SA 4.0. The MIT license for the Python wrapper is not the same as the dataset license. Do not redistribute the derived dictionary or ship it in App Store without explicit confirmation of commercial rights or a compatible alternative ontology. This is a private experimental device build only.
