#!/usr/bin/env python3
"""Upload signed-off localization screenshots to the *draft* C17 version only."""
import hashlib, json,sys,time,urllib.request,urllib.error
from pathlib import Path
import asc_c17_release as asc
ROOT=asc.ROOT; ASO=asc.ASO
manifest=json.loads((ASO/'screenshot_manifest.json').read_text())
marketing=json.loads((ASO/'editorial/c15-ipad-marketing-manifest.json').read_text())
KIND={'iphone-6.9':'APP_IPHONE_67','ipad-13':'APP_IPAD_PRO_3GEN_129'}
def one_set(app,locale,device,shots,lid,vid):
  display=KIND[device]
  q=asc.must('GET',f'/appStoreVersionLocalizations/{lid}/appScreenshotSets?limit=20')
  candidates=[s for s in q.get('data',[]) if s['attributes'].get('screenshotDisplayType')==display]
  if candidates:setid=candidates[0]['id']
  else:
    body={'data':{'type':'appScreenshotSets','attributes':{'screenshotDisplayType':display},
          'relationships':{'appStoreVersionLocalization':{'data':{'type':'appStoreVersionLocalizations','id':lid}}}}}
    setid=asc.must('POST','/appScreenshotSets',body,ok=(201,))['data']['id']
  existing=asc.must('GET',f'/appScreenshotSets/{setid}/appScreenshots?limit=50').get('data',[])
  # Safety: never remove assets that belong to the published version.
  published=asc.attrs(asc.must('GET',f'/apps/{asc.APPS[app]}/appStoreVersions?limit=15'))
  prior=next((x for x in published if x.get('appStoreState')=='READY_FOR_SALE'),None)
  if prior:
    local=asc.attrs(asc.must('GET',f'/appStoreVersions/{prior["id"]}/appStoreVersionLocalizations?limit=50'))
    oldlid=next((x['id'] for x in local if x['locale']==locale),None)
    if oldlid:
      oldsets=asc.must('GET',f'/appStoreVersionLocalizations/{oldlid}/appScreenshotSets?limit=20').get('data',[])
      if any(s['id']==setid for s in oldsets):raise RuntimeError(f'Refusing to modify shared LIVE screenshot set {app}/{locale}')
  # If version-created images were auto-copied, remove those only after safety check.
  # Then add exact staged images in release-relevant order.
  for s in existing:
    asc.must('DELETE',f'/appScreenshots/{s["id"]}')
  for shot in sorted(shots,key=lambda x:x['position']):
    path=ROOT/shot['path']
    raw=path.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=shot['sha256']:
      raise RuntimeError(f'SHA mismatch {path}')
    d=asc.must('POST','/appScreenshots',{'data':{'type':'appScreenshots','attributes':{
       'fileSize':len(raw),'fileName':path.name},
       'relationships':{'appScreenshotSet':{'data':{'type':'appScreenshotSets','id':setid}}}}},ok=(201,))
    aid=d['data']['id']
    ops=d['data']['attributes'].get('uploadOperations') or []
    if not ops:raise RuntimeError(f'Apple did not give upload operations {path}')
    for op in ops:
      offset=int(op.get('offset',0));part=raw[offset:offset+int(op.get('length',len(raw)-offset))]
      req=urllib.request.Request(op['url'],data=part,method=op.get('method','PUT'))
      for h in op.get('requestHeaders') or []:
        if h.get('name') and h.get('value') is not None:req.add_header(h['name'],str(h['value']))
      with urllib.request.urlopen(req,timeout=120) as response:
        if response.status not in (200,201,202,204):raise RuntimeError('binary transfer rejected')
        response.read()
    asc.must('PATCH',f'/appScreenshots/{aid}',{'data':{'type':'appScreenshots','id':aid,
       'attributes':{'uploaded':True,'sourceFileChecksum':hashlib.md5(raw).hexdigest()}}})
    for poll in range(15):
      data=asc.must('GET',f'/appScreenshots/{aid}')['data']['attributes']
      delivery=data.get('assetDeliveryState') or {}
      name=delivery.get('state',delivery.get('status','')) if isinstance(delivery,dict) else str(delivery)
      if name in ('COMPLETE','UPLOAD_COMPLETE','SUCCEEDED','SUCCESS'):break
      if 'FAIL' in name or 'ERROR' in name:raise RuntimeError(f'Apple screenshot rejected {app}/{locale}/{device}: {delivery}')
      time.sleep(2)
    else:raise RuntimeError(f'Apple screenshot processing timed out {app}/{locale}/{device}')
    print('SHOT_OK',app,locale,device,shot['position'],flush=True)
  asc.state['apps'][app].setdefault('screenshotsComplete',{}).setdefault(locale,[]).append(device)
  asc.save()
  print('SET_OK',app,locale,device,len(shots),flush=True)
def run(app):
  v=asc.version(app)
  if v['appStoreState']!='PREPARE_FOR_SUBMISSION':
    raise RuntimeError('Cannot modify a published/review version')
  vid=v['id']
  data=json.loads((ASO/(app+'.json')).read_text())['localeData']
  locales=asc.attrs(asc.must('GET',f'/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=50'))
  available={x['locale']:x['id'] for x in locales}
  for locale in data:
    if len(sys.argv)>2 and locale!=sys.argv[2]:continue
    if locale not in available:raise RuntimeError(f'Missing Apple metadata locale {app}/{locale}')
    tasks=[dict(x) for x in manifest['apps'][app]['slots'] if x['locale']==locale]
    groups={}
    for s in tasks:
      if s['device']=='ipad-13':
        m=next((x for x in marketing['apps'].get(app,[]) if x['locale']==locale and x['position']==s['position']),None)
        if m:s['path']=m['marketingPath'];s['sha256']=m['sha256']
      groups.setdefault(s['device'],[]).append(s)
    done=asc.state['apps'][app].get('screenshotsComplete',{}).get(locale,[])
    for device,shots in groups.items():
      if device in done:continue
      # Resume interrupted uploads safely: compare actual draft screenshot
      # filenames + complete delivery status, never blindly delete a set.
      sets=asc.must('GET',f'/appStoreVersionLocalizations/{available[locale]}/appScreenshotSets?limit=20')['data']
      found=next((x for x in sets if x['attributes'].get('screenshotDisplayType')==KIND[device]),None)
      if found:
        current=asc.must('GET',f'/appScreenshotSets/{found["id"]}/appScreenshots?limit=50')['data']
        expected=sorted(Path(s['path']).name for s in shots)
        actual=sorted(s.get('attributes',{}).get('fileName','') for s in current)
        if actual==expected and all((s.get('attributes',{}).get('assetDeliveryState') or {}).get('state')=='COMPLETE' for s in current):
          print('REMOTE_SET_ALREADY_COMPLETE',app,locale,device,len(current),flush=True)
          asc.state['apps'][app].setdefault('screenshotsComplete',{}).setdefault(locale,[]).append(device)
          asc.save()
          continue
      one_set(app,locale,device,shots,available[locale],vid)
if __name__=='__main__':run(sys.argv[1])
