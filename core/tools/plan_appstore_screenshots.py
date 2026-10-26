#!/usr/bin/env python3
"""Create exact per-locale capture slots; never forge or upload screenshot content."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
STAGE=ROOT/'core/appstore/staged-2026-10-26'
SRC=ROOT/'photo-pdf-to-size'
manifest={'status':'STAGED_ONLY_NOT_UPLOADED','scope':'Native iPhone/iPad actual UI captures; no synthetic text overlays over the wrong UI','date':'2026-10-26','apps':{}}
for app in ('photo','pushkin','what','chickmark'):
 d=json.loads((STAGE/f'{app}.json').read_text())['localeData']
 record={'locales':len(d),'slots':[]}
 for loc,v in d.items():
  devices=['iphone-6.9']+(['ipad-13'] if app in ('photo','what','chickmark') else [])
  for device in devices:
   for pos,headline in enumerate(v['screenshots'],1):
    r={'locale':loc,'device':device,'position':pos,'headline':headline,
       'requiredNativeLocale':{'en-AU':'en','en-CA':'en','en-GB':'en','en-US':'en','es-ES':'es','es-MX':'es','fr-FR':'fr','de-DE':'de'}.get(loc,loc),
       'status':'PENDING_REAL_NATIVE_CAPTURE', 'path':None}
    if app=='photo' and loc in ('ru','en-US','en-GB') and device=='iphone-6.9':
     photos=['01-photo-kb.jpg','02-pixel-dimensions.jpg','03-visa-presets.jpg','04-pdf-kb.jpg']
     p=SRC/'store-assets/appstore/review-20261026'/loc/device/photos[pos-1]
     if p.is_file():
      r['status']='DRAFT_CAPTURE_REQUIRES_FINAL_RC_REFRESH'
      r['path']=str(p.relative_to(ROOT))
      r['sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
    if app=='pushkin' and loc=='ru' and device=='iphone-6.9':
     p=ROOT/'pushkin/store-assets/appstore/editorial-20261026/ru/iphone-6.9'/f"{pos:02d}-{['history.png','sources.png','settings.png','none.png'][pos-1]}"
     if p.is_file():
      r['status']='NATIVE_SCREENSHOT_DRAFT_REQUIRES_FINAL_RC_REFRESH'
      r['path']=str(p.relative_to(ROOT));r['sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
    record['slots'].append(r)
 manifest['apps'][app]=record
(STAGE/'screenshot_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
for app,record in manifest['apps'].items():
 from collections import Counter
 print(app,'slots',len(record['slots']),dict(Counter(r['status'] for r in record['slots'])))
