#!/usr/bin/env python3
"""Prepare an OFFLINE developer-only Russian concept graph.

WARNING: The RuWordNet website states both CC BY-SA 4.0 and noncommercial
distribution language. Do NOT commit or redistribute the generated corpus or
ship it in an App Store app until distribution rights are clarified.

This program has NO network calls and never reads any private user notes.
Usage:
 python what/research/generate_concept_graph.py --database /path/ruwordnet.db \
       --output what/ios/WhatIOS/Resources/RussianConceptGraph.json.zlib
"""
import argparse
from collections import defaultdict
from pathlib import Path
import json
import sqlite3
import zlib

def generate(database: Path, output: Path):
    import pymorphy3
    con = sqlite3.connect(f"file:{database}?mode=ro", uri=True)
    nouns = {
        k for k, pos in con.execute(
            "SELECT id,part_of_speech FROM synset"
        ) if pos == "N"
    }
    ordered = sorted(nouns)
    IDs = {name:idx for idx,name in enumerate(ordered)}
    parents = [[] for _ in ordered]
    for child,parent in con.execute(
        "SELECT hyponym_id,hypernym_id FROM hypernym_relation"
    ):
        if child in IDs and parent in IDs:
            parents[IDs[child]].append(IDs[parent])
    hyponyms = [0]*len(ordered)
    for lst in parents:
        for idx in lst:hyponyms[idx]+=1
    words:dict[str,set[int]] = defaultdict(set)
    for lemma,name,synset in con.execute(
        "SELECT lemma,name,synset_id FROM sense"
    ):
        if synset not in IDs:continue
        for label in (lemma,name):
            normalized=label.lower().replace("ё","е").strip()
            if len(normalized)>=3:words[normalized].add(IDs[synset])
    morph=pymorphy3.MorphAnalyzer()
    candidate_forms:dict[str,set[str]]=defaultdict(set)
    for lemma in words:
        if " " in lemma:continue
        parsed=morph.parse(lemma)[0]
        if parsed.tag.POS != "NOUN":continue
        if parsed.normal_form.replace("ё","е") != lemma:continue
        for form in parsed.lexeme:
            word=form.word.replace("ё","е")
            if word != lemma and word not in words and len(word)>=3:
                candidate_forms[word].add(lemma)
    # Ambiguous inflections MUST be omitted to avoid false synonym claims.
    forms={form:next(iter(targets)) for form,targets in candidate_forms.items()
           if len(targets)==1}
    graph={
        "rev":2,
        "source":"RuWordNet 2021; researcher-only derived graph; CC BY-SA 4.0; verify commercial rights",
        "terms":{key:sorted(ids) for key,ids in words.items()},
        "parents":parents,"hyponyms":hyponyms,"forms":forms
    }
    payload=json.dumps(
        graph,ensure_ascii=False,separators=(",",":")
    ).encode("utf-8")
    # Apple's NSData.zlib expects raw DEFLATE (wbits=-15), not
    # zlib-framed 0x78da. Regression-tested with Swift Foundation.
    compressor=zlib.compressobj(level=9,wbits=-15)
    zipped=compressor.compress(payload)+compressor.flush()
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_bytes(zipped)
    print(
        "Synsets:",len(ordered),"terms:",len(words),"forms:",len(forms),
        "raw_bytes:",len(payload),"bundle_bytes:",len(zipped)
    )

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--database",type=Path,required=True)
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    generate(args.database,args.output)
