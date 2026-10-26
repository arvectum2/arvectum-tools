#!/usr/bin/env python3
"""Heuristic back-translation risk scan, NOT native-speaker proofreading."""
import concurrent.futures,json,urllib.parse,urllib.request
from pathlib import Path
BASE=Path(__file__).resolve().parents[2]/'core/appstore/staged-2026-10-26'
LANG={'es-ES':'es','es-MX':'es','fr-FR':'fr','de-DE':'de','it':'it','ja':'ja','ko':'ko','pt-BR':'pt','pt-PT':'pt','zh-Hans':'zh-CN','zh-Hant':'zh-TW'}
EXPECT={'photo':['ad','file'],'pushkin':['not','notification'],'what':['recognition','language'],'chickmark':['ad','apple']}
checks=[]
for app in EXPECT:
 d=json.load(open(BASE/(app+'.json')))['localeData']
 for loc,lang in LANG.items():
  paragraphs=d[loc]['description'].split('\n\n')
  checks.append((app,loc,lang,' '.join(paragraphs[-2:])))
def back(q):
 app,loc,lang,s=q
 try:
  url='https://translate.googleapis.com/translate_a/single?'+urllib.parse.urlencode({'client':'gtx','sl':lang,'tl':'en','dt':'t','q':s})
  v=json.load(urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=12))
  output=''.join(z[0] for z in v[0] if z and z[0])
  missing=[x for x in EXPECT[app] if x not in output.lower()]
  return {'app':app,'locale':loc,'backTranslation':output,'missingAnchors':missing,'status':'FLAG_FOR_EDITOR' if missing else 'HEURISTIC_OK'}
 except Exception as e:return {'app':app,'locale':loc,'error':str(e),'status':'FAILED_TO_CHECK'}
with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:rows=list(pool.map(back,checks))
(BASE/'editorial'/'marketing_backtranslation.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
for app in EXPECT:
 found=[x for x in rows if x['app']==app]
 flags=[(x['locale'],x.get('missingAnchors',x.get('error'))) for x in found if x['status']!='HEURISTIC_OK']
 print(app,'checked',len(found),'flags',flags)
print('Heuristics do not constitute linguistic acceptance.')
