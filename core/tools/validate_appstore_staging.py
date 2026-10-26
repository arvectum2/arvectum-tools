#!/usr/bin/env python3
"""Offline staging checks only; passing does NOT mean App Review approval."""
import json
import re
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
STAGE=ROOT/'core/appstore/staged-2026-10-26'
LOCALES={'ru','en-US','en-GB','en-AU','en-CA','es-ES','es-MX','fr-FR','de-DE','it','ja','ko','pt-BR','pt-PT','zh-Hans','zh-Hant'}
BRANDS={'pushkin':'PUSHKIN','what':'UhWhat?','chickmark':'ChickMark'}
APP_ID={'pushkin':'6817847111','what':'6822476399','chickmark':'6818711298','photo':'6816346084'}
URLS={'photo':'https://arvectum.com/photo-pod-razmer-privacy.html','pushkin':'https://arvectum.com/privacy.html','what':'https://arvectum.com/privacy.html','chickmark':'https://arvectum.com/privacy.html'}
errors=[]
for app in APP_ID:
 p=STAGE/(app+'.json')
 doc=json.loads(p.read_text());locs=doc['localeData']
 if set(locs)!=LOCALES:errors.append((app,'locale mismatch',sorted(LOCALES-set(locs)),sorted(set(locs)-LOCALES)))
 if doc['appId']!=APP_ID[app] or doc['stage']!='DRAFT_NOT_UPLOADED':errors.append((app,'bad identity or live mutation risk'))
 for loc,v in locs.items():
  for f,maximum in [('name',30),('subtitle',30),('promotionalText',170),('description',4000),('whatsNew',4000)]:
   s=v.get(f,'');
   if not s.strip() or len(s)>maximum:errors.append((app,loc,f,len(s),maximum))
  keys=v.get('keywords','');n=len(keys.encode('utf-8'))
  if not 1<=n<=100:errors.append((app,loc,'keyword bytes',n))
  terms=[x.strip() for x in keys.split(',')]
  if any(not x for x in terms) or len(set(x.casefold() for x in terms))!=len(terms):errors.append((app,loc,'keyword shape'))
  if len(v.get('screenshots',[]))!=4 or any(not h.strip() or len(h)>80 for h in v.get('screenshots',[])):errors.append((app,loc,'screenshot headings'))
  if v.get('privacyPolicyUrl')!=URLS[app]:errors.append((app,loc,'privacy url'))
  if app in BRANDS and loc!='ru' and BRANDS[app] not in v['description']:errors.append((app,loc,'brand corrupted in description'))
  if app=='pushkin' and not ('iOS' in v['description'] or 'Shortcuts' in v['description']):errors.append((app,loc,'missing honest setup caveat'))
  if app=='chickmark' and 'apple' not in v['description'].casefold():errors.append((app,loc,'missing Health disclosure'))
  if app in ('what','chickmark') and 'apple watch' not in v['description'].casefold():errors.append((app,loc,'missing Watch label'))
  if loc=='ko' and '시청' in keys:errors.append((app,loc,'Watch translated as viewing'))
  if app=='photo' and ('PDF' not in v['description'] and 'pdf' not in v['description']):errors.append((app,loc,'missing product domain'))
 print(f'{app:10} {len(locs):2} locales; fields verified {len(locs)*9}',flush=True)
if errors:
 for e in errors: print('ERROR',e,file=sys.stderr)
 raise SystemExit(1)
# Validate every screenshot slot, but never call a missing file a finished image.
manifest=json.loads((STAGE/'screenshot_manifest.json').read_text())
seen=set();slots=0;captured=0
for app,item in manifest['apps'].items():
 for shot in item['slots']:
  slots+=1
  key=(app,shot['locale'],shot['device'],shot['position'])
  if key in seen:errors.append(('duplicate screenshot slot',key))
  seen.add(key)
  target=json.loads((STAGE/(app+'.json')).read_text())['localeData'][shot['locale']]['screenshots'][shot['position']-1]
  if target!=shot['headline']:errors.append(('screenshot headline drift',key))
  if shot.get('path'):
   import hashlib
   f=ROOT/shot['path']
   if not f.exists() or hashlib.sha256(f.read_bytes()).hexdigest()!=shot['sha256']:
    errors.append(('stale screenshot hash',key))
   else:captured+=1
if slots!=448:errors.append(('screenshot slots expected 448',slots))
if errors:
 for e in errors: print('ERROR',e,file=sys.stderr)
 raise SystemExit(1)
print(f'Screenshot slots structurally checked: {slots}; existing staged drafts: {captured} (not final release images)')
print('ASO draft structure PASS (64 records, no App Store writes; linguistic signoff NOT included)')
