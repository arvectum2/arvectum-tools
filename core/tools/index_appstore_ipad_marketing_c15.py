#!/usr/bin/env python3
"""Index truthful composite marketing JPGs from real iPad XCUITest source screens."""
import hashlib,json,struct,subprocess
from pathlib import Path
R=Path(__file__).resolve().parents[2]
S=R/'core/appstore/staged-2026-10-26'
SOURCE=json.loads((S/'screenshot_manifest.json').read_text())['apps']
REGION={'ru':'ru','en-US':'en','en-GB':'en','en-AU':'en','en-CA':'en','es-ES':'es','es-MX':'es','fr-FR':'fr','de-DE':'de','it':'it','ja':'ja','ko':'ko','pt-BR':'pt-BR','pt-PT':'pt-PT','zh-Hans':'zh-Hans','zh-Hant':'zh-Hant'}
folders={'photo':'photo-pdf-to-size','what':'what','chickmark':'chickmark'}
data={'stage':'DRAFT_NOT_UPLOADED','render':'c15-read-only-repackaging-of-two_real_native_screens','apps':{}}
for app,folder in folders.items():
 listing=json.loads((S/(app+'.json')).read_text())['localeData']
 group=[]
 for loc,language in REGION.items():
  for position in range(1,5):
   p=R/folder/'store-assets/appstore/marketing-20261027'/language/'ipad-13'/f'{position:02d}-hero.jpg'
   if not p.is_file():raise RuntimeError(str(p))
   dimensions=subprocess.check_output(['sips','-g','pixelWidth','-g','pixelHeight',str(p)],text=True)
   if 'pixelWidth: 2064' not in dimensions or 'pixelHeight: 2752' not in dimensions:raise ValueError(p)
   with p.open('rb') as f:
    if f.read(3)!=b'\xff\xd8\xff':raise ValueError('Not opaque JPEG '+str(p))
   native=[next(x for x in SOURCE[app]['slots'] if x['locale']==loc and x['device']=='ipad-13' and x['position']==n) for n in (position,position%4+1)]
   for s in native:
    if hashlib.sha256((R/s['path']).read_bytes()).hexdigest()!=s['sha256']:raise ValueError(('source changed',s['path']))
   group.append({'locale':loc,'uiLanguage':language,'marketingPath':str(p.relative_to(R)),
     'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'sources':[{'path':x['path'],'sha256':x['sha256']} for x in native],
     'caption':listing[loc]['screenshots'][position-1],'position':position,'stage':'SIMULATOR_MARKETING_DRAFT'})
 data['apps'][app]=group
out=S/'editorial/c15-ipad-marketing-manifest.json'
out.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print('C15 marketing indexed 144 unique JPEGs / 192 regional records (3 apps × 16 regions × 4 positions)')
