#!/usr/bin/env python3
"""Inspect C17 ASC completeness remotely and rebuild QA status from Apple; never modifies listings."""
import json,sys
import asc_c17_release as a
DEVICE={'iphone-6.9':'APP_IPHONE_67','ipad-13':'APP_IPAD_PRO_3GEN_129'}
def inspect():
 complete=True
 for app,aid in a.APPS.items():
  v=a.version(app)
  if not v:raise RuntimeError('No candidate '+app)
  existing=a.attrs(a.must('GET',f'/appStoreVersions/{v["id"]}/appStoreVersionLocalizations?limit=50'))
  infos=a.attrs(a.must('GET',f'/apps/{aid}/appInfos?limit=20'))
  pending=next((i for i in infos if i.get('state')=='PREPARE_FOR_SUBMISSION'),None)
  if not pending:raise RuntimeError('No pending app info '+app)
  il=a.attrs(a.must('GET',f'/appInfos/{pending["id"]}/appInfoLocalizations?limit=50'))
  locs={x['locale']:x['id'] for x in existing}
  desired=json.loads((a.ASO/(app+'.json')).read_text())['localeData']
  expected_devices={'iphone-6.9':4} if app=='pushkin' else {'iphone-6.9':4,'ipad-13':4}
  snap={}
  for locale in desired:
   if locale not in locs:
    print('MISSING_LOCALE',app,locale);complete=False;continue
   sets=a.must('GET',f'/appStoreVersionLocalizations/{locs[locale]}/appScreenshotSets?limit=20')['data']
   devices=[]
   for device,count in expected_devices.items():
    typ=DEVICE[device]
    ss=next((s for s in sets if s['attributes'].get('screenshotDisplayType')==typ),None)
    if not ss:
     print('MISSING_SCREEN_SET',app,locale,device);complete=False;continue
    shots=a.must('GET',f'/appScreenshotSets/{ss["id"]}/appScreenshots?limit=50')['data']
    if len(shots)!=count:
     print('WRONG_SHOT_COUNT',app,locale,device,len(shots),count);complete=False;continue
    if any((s.get('attributes',{}).get('assetDeliveryState') or {}).get('state')!='COMPLETE' for s in shots):
     print('IMAGE_PROCESSING',app,locale,device);complete=False;continue
    devices.append(device)
   if len(devices)==len(expected_devices):snap[locale]=devices
  validversion=len(locs)==16 and len(il)==16 and len(snap)==16
  print('VERIFIED',app,'version_locales',len(locs),'appInfoLocales',len(il),
        'completeImageLocales',len(snap),'releaseType',v.get('releaseType'),flush=True)
  if not validversion:complete=False
  d=a.state['apps'][app]
  if validversion:
   d['locales']=locs;d['metadataComplete']=True;d['screenshotsComplete']=snap
  # Refresh original build assignment regardless of stale concurrent local checkpoints.
  build=a.must('GET',f'/appStoreVersions/{v["id"]}/relationships/build').get('data')
  if build:
   b=a.must('GET',f'/builds/{build["id"]}')['data']
   if b.get('attributes',{}).get('processingState')=='VALID':
    d['buildId']=build['id'];d['buildAttached']=True
  if not d.get('buildAttached'):complete=False
 a.save()
 print('FULL_ASC_PREFLIGHT', 'PASS' if complete else 'INCOMPLETE',flush=True)
 return complete
if __name__=='__main__':
 ok=inspect()
 if not ok:sys.exit(2)
