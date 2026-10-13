#!/usr/bin/env python3
"""Offline, experimental Russian concept retrieval. No audio or transcript writes.

Research-only: ruwordnet package's code license does NOT automatically cover
its separate CC BY-SA 4.0 thesaurus database. Respect attribution/share-alike
requirements before incorporating a derived database into a commercial app.

Dependencies: pip install pymorphy3 pymorphy3-dicts-ru ruwordnet
              ruwordnet download  # only during INITIAL research setup
After downloading RuWordNet, all queries run with no network connection.
"""
from __future__ import annotations
import argparse
from dataclasses import dataclass
from functools import lru_cache
import json
from pathlib import Path
import re
from typing import Mapping, Sequence

# Generic stop-words; NEVER manually add a mapping for evaluation word pairs.
STOP = frozenset((
    "раз два три четыре пять шесть семь восемь девять десять "
    "сейчас потом просто этот весь какой что который быть это один свой "
    "мой мне себя уже делать сделать нужно такой где вот там все очень "
    "на по тут как этого когда если для здесь тоже какой-то сначала тогда "
    "пожалуйста про об его её они мы вы наше ваш к от до как-то"
).split())
WORDS = re.compile(r"[а-яёa-z]+", re.IGNORECASE)
ACCEPT_POS = frozenset(("NOUN", "ADJF", "ADJS", "VERB", "INFN"))

@dataclass(frozen=True)
class Evidence:
    note_id: str
    score: float
    relation: str

class ConceptSearch:
    def __init__(self, wn=None, morph=None):
        if wn is None:
            from ruwordnet import RuWordNet
            wn = RuWordNet()
        if morph is None:
            import pymorphy3
            morph = pymorphy3.MorphAnalyzer()
        self.wn = wn
        self.morph = morph
        self.notes: dict[str, tuple[tuple[str,str],...]] = {}

    @lru_cache(maxsize=32768)
    def lemma(self, token: str) -> tuple[str, str | None]:
        p=self.morph.parse(token.casefold().replace("ё","е"))[0]
        return p.normal_form,p.tag.POS

    def terms(self, text: str) -> tuple[tuple[str,str], ...]:
        tokens=[self.lemma(t) for t in
                WORDS.findall(text.casefold().replace("ё","е"))]
        result=[]
        for lemma,pos in tokens:
            if pos in ACCEPT_POS and len(lemma)>=3 and lemma not in STOP:
                result.append((lemma,pos))
        # Preserve known 2-3-word ontology terms such as
        # "музыкальный инструмент": search vocab, not a manual synonym list.
        for start in range(len(tokens)):
            for length in (2,3):
                group=tokens[start:start+length]
                if len(group)!=length or group[-1][1]!="NOUN":
                    continue
                if any(pos not in ACCEPT_POS or token in STOP
                       for token,pos in group):
                    continue
                phrase=" ".join(token for token,_ in group)
                if self.wn.get_synsets(phrase):
                    result.append((phrase,"NOUN"))
        return tuple(dict.fromkeys(result))

    def add(self, note_id: str, transcript: str):
        """Only keep lemmata as derived, disposable index; never modify source."""
        self.notes[note_id]=self.terms(transcript)

    @lru_cache(maxsize=32768)
    def senses(self, lemma: str) -> Mapping[str,int]:
        """All senses; hypernyms up to depth 2. Avoid hardcoded synonyms."""
        result={}
        for root in self.wn.get_synsets(lemma):
            queue=[(root,0)]
            while queue:
                synset, depth=queue.pop(0)
                if synset.id in result and result[synset.id]<=depth:
                    continue
                result[synset.id]=depth
                if depth<3:
                    queue.extend((p,depth+1) for p in synset.hypernyms)
        return result

    @lru_cache(maxsize=32768)
    def related(self, query: str, candidate: str) -> tuple[float,str]:
        qa,ca=self.senses(query),self.senses(candidate)
        best=(0.0,"")
        for synset_id in qa.keys() & ca.keys():
            qdepth,cdepth=qa[synset_id],ca[synset_id]
            distance=qdepth+cdepth
            if distance>3:continue
            # If the common class is several hops away from both terms
            # and very broad, it carries no useful semantic evidence.
            # This rule excludes e.g. 'parachute' -> 'notebook' through
            # the useless 'physical object' common ancestor.
            if qdepth>0 and cdepth>0:
                if len(self.wn[synset_id].hyponyms)>10:
                    continue
            strength={0:3.6,1:2.8,2:1.95,3:1.3}[distance]
            if strength>best[0]:
                best=(strength,synset_id)
        return best

    def search(self, query: str, limit: int=10) -> list[Evidence]:
        qtokens=self.terms(query)
        result=[]
        for note_id,doc_tokens in self.notes.items():
            best=0.0
            relation=""
            for q,pos in qtokens:
                for candidate,cpos in doc_tokens:
                    if q==candidate:
                        score=5.0
                        why="exact-lemma"
                    elif pos=="NOUN" and cpos=="NOUN":
                        score,shared=self.related(q,candidate)
                        why="wordnet:" + shared
                    else:
                        continue
                    if score>best:
                        best=score
                        relation=why
            if best>=1.3:
                result.append(Evidence(note_id, best,relation))
        return sorted(result,key=lambda x:(-x.score,x.note_id))[:limit]

def benchmark(path: Path):
    """Report only retrieval rank/count. Do not print private note text."""
    all_notes=json.loads(path.read_text())
    index=ConceptSearch()
    for key,text in all_notes.items():
        index.add(key,text)
    positives=(
        ("цветок","эдельвейс"),
        ("журнал","дневник"),
        ("красота","красоту"),
    )
    controls=(
        "извержение","атом","корабль","бензин","рептилия",
        "землетрясение","кукуруза","ракета","динозавр","метеорит",
        "эскулап","экскаватор","пингвин","парашют","теорема",
        "математика","картофель","зубочистка","мотоцикл","вагон",
    )
    print("INDEX",len(all_notes),"notes")
    for query,needle in positives:
        matches=[k for k,v in all_notes.items() if needle in v.casefold()]
        result=index.search(query)
        ranks=[next((i+1 for i,x in enumerate(result) if x.note_id==k),None)
               for k in matches]
        print("POSITIVE",query,"EXPECTED",len(matches),
              "RANKS",ranks,"TOTAL_RESULTS",len(result))
    stray={query:len(index.search(query)) for query in controls
           if index.search(query)}
    print("NEGATIVE_CONTROLS",len(controls),"FALSE_CANDIDATES",stray)
    return index

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--transcripts",type=Path,help="existing local transcripts.json")
    args=parser.parse_args()
    if args.transcripts:
        benchmark(args.transcripts)
    else:
        print("Provide --transcripts pointing at an existing local read-only backup.")

if __name__=="__main__":
    main()
