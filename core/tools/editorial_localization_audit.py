#!/usr/bin/env python3
"""Conservative localization editorial triage; does not certify native fluency."""
from __future__ import annotations
from collections import Counter
from pathlib import Path
import json
import re
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
import localization_portfolio as lp

ROOT=lp.ROOT
HIGH_RISK=re.compile(r'privacy|permission|consent|tracking|health|shortcuts|automati|delete|remov|erase|location|advertis|notification|audio|microphone|speech|icloud|backup|sync|export|import|gps|photo|pdf|metadata|скры|удал|данн|соглас|разреш|уведом',re.I)
PTPT=re.compile(r'\bvoc[eê]\b|\bseu aparelho\b|\bnos ajustes\b|\bno atalhos\b|\bapps\b|\barquivo\b|\bconfira\b|\bgerenciar\b|\bApple Saúde\b|\bregistros?\b|\bsomente\b|\bem um\b|\bem uma\b|\bos aplicações\b',re.I)

def audit():
    entries=[];counts=Counter();issues=[]
    for app,config in lp.config()['apps'].items():
        for bundle in config['bundles']:
            base=ROOT/bundle
            english=lp.read_strings(base/'en.lproj/Localizable.strings',[])
            for file in sorted(base.glob('*.lproj/*.strings')):
                loc=file.parent.name.removesuffix('.lproj')
                if loc=='en':continue
                source=base/'en.lproj'/file.name
                if not source.exists():continue
                en=lp.read_strings(source,[])
                tr=lp.read_strings(file,[])
                missing=sorted(set(en)-set(tr));extra=sorted(set(tr)-set(en))
                identical=sorted(k for k in en.keys()&tr.keys() if en[k]==tr[k] and len(en[k])>8 and not en[k].startswith('%'))
                fmt=sorted(k for k in en.keys()&tr.keys() if lp.placeholders(en[k])!=lp.placeholders(tr[k]))
                pt=sorted(k for k,v in tr.items() if loc=='pt-PT' and PTPT.search(v))
                high=[k for k in tr if HIGH_RISK.search(k) or HIGH_RISK.search(en.get(k,''))]
                counts[loc]+=len(tr)
                item={'app':app,'bundle':bundle,'file':str(file.relative_to(ROOT)),'locale':loc,'entries':len(tr),'missing':len(missing),'extra':len(extra),'format_mismatch':len(fmt),'english_identical':len(identical),'high_risk_review':len(high),'pt_pt_brazilian_flags':len(pt)}
                entries.append(item)
                for category,keys in [('missing',missing),('extra',extra),('format_mismatch',fmt),('english_identical',identical),('pt_pt_brazilian_flags',pt)]:
                    for key in keys:
                        issues.append({'app':app,'locale':loc,'file':item['file'],'kind':category,'key':key,'value':tr.get(key,'')[:240]})
    # Legitimate cross-language identical strings are tracked explicitly. This
    # lexical classification is NOT proof of editorial correctness.
    whitelist = json.loads((ROOT/'core/localization/english-identical-exceptions.json').read_text(encoding='utf-8'))['entries']
    approved = {(item['file'],item['key'],item['value']) for item in whitelist}
    observed = {(item['file'],item['key'],item['value']) for item in issues if item['kind']=='english_identical'}
    identical_untriaged = sorted(observed-approved)
    identical_stale_exceptions = sorted(approved-observed)
    return {'scope':'source catalogs only; no native-speaker signoff or Apple approval','files':len(entries),'entries':sum(i['entries'] for i in entries),'locales':dict(sorted(counts.items())),'catalogs':entries,'findings':issues,'english_identical_triaged':len(observed & approved),'english_identical_untriaged':identical_untriaged,'english_identical_stale_exceptions':identical_stale_exceptions}

if __name__=='__main__':
    result=audit()
    output=ROOT/'core/docs/EDITORIAL_LOCALE_AUDIT_2026-10-25.json'
    output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print('files',result['files'],'entries',result['entries'],'flags',len(result['findings']))
    print('types',dict(Counter(i['kind'] for i in result['findings'])))
    print('pt-PT flags:')
    for issue in result['findings']:
        if issue['kind']=='pt_pt_brazilian_flags':print(issue['file'],issue['key'],issue['value'][:95])
