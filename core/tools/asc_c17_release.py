#!/usr/bin/env python3
"""Exact-approved C17 Apple App Store Connect release runner; resumable, no secrets in repo."""
import os,json,re,subprocess,time,urllib.request,urllib.error
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
QA=Path('/Volumes/ArvectumSSD/Arvectum/qa/indieappcircle-release-candidates-20261027')
ASO=ROOT/'core/appstore/staged-2026-10-26'
RELEASE=json.loads((ROOT/'core/docs/INDIEAPPCIRCLE_C17_SIGNED_RELEASE_MANIFEST.json').read_text())['apps']
APPS={'photo':'6816346084','pushkin':'6817847111','what':'6822476399','chickmark':'6818711298'}
STATE=QA/'asc-c17-state.json'
state=json.loads(STATE.read_text()) if STATE.exists() else {'apps':{}}
for a in APPS:state['apps'].setdefault(a,{})
def save():STATE.write_text(json.dumps(state,ensure_ascii=False,indent=2)+'\n')
def token():
 cfg={}
 for raw in (Path.home()/'.config/arvectum/appstore-connect.env').read_text().splitlines():
  if '=' in raw and not raw.lstrip().startswith('#'):
   k,v=raw.split('=',1);cfg[k.strip().removeprefix('export ')]=v.strip().strip('"').strip("'")
 env=os.environ.copy();env['API_PRIVATE_KEYS_DIR']=cfg.get('ASC_KEY_DIR',str(Path.home()/'.appstoreconnect/private_keys'))
 altool=subprocess.check_output(['xcrun','--find','altool'],text=True).strip()
 p=subprocess.run([altool,'--generate-jwt','--apiKey',cfg['ASC_KEY_ID'],'--apiIssuer',cfg['ASC_ISSUER_ID']],env=env,capture_output=True,text=True,timeout=45)
 m=re.search(r'eyJ[\w-]+\.[\w-]+\.[\w-]+',p.stdout+p.stderr)
 if not m:raise RuntimeError('Cannot authenticate to ASC')
 return m.group(0)
JWT=token()
def call(method,path,body=None):
 global JWT
 req=urllib.request.Request('https://api.appstoreconnect.apple.com/v1'+path,
  data=json.dumps(body,ensure_ascii=False).encode() if body is not None else None,
  method=method,headers={'Authorization':'Bearer '+JWT,'Content-Type':'application/json'})
 for n in range(3):
  try:
   with urllib.request.urlopen(req,timeout=50) as r:
    b=r.read();return r.status,json.loads(b) if b else {}
  except urllib.error.HTTPError as e:
   b=e.read().decode(errors='replace')
   if e.code==401 and n<2:
    # altool-generated App Store Connect JWTs expire during multi-locale image uploads.
    JWT=token()
    req.add_header('Authorization','Bearer '+JWT)
    continue
   if e.code in [429,502,503] and n<2:time.sleep(5*(n+1));continue
   try:err=[x.get('detail',x.get('title')) for x in json.loads(b).get('errors',[])]
   except:err=[b[:350]]
   return e.code,{'errors':err[:3]}
def must(method,path,body=None,ok=(200,201,204)):
 code,doc=call(method,path,body)
 if code not in ok:raise RuntimeError(f'{method} {path} HTTP {code}: {doc.get("errors")}')
 return doc
def attrs(d):return [{**x.get('attributes',{}),'id':x['id']} for x in d.get('data',[])]
def version(app):
 all=attrs(must('GET',f'/apps/{APPS[app]}/appStoreVersions?limit=25'))
 return next((x for x in all if x.get('versionString')==RELEASE[app]['version'] and x.get('platform')=='IOS'),None)
def inspect():
 for app in APPS:
  v=version(app)
  builds=attrs(must('GET',f'/builds?filter%5Bapp%5D={APPS[app]}&limit=40'))
  b=next((x for x in builds if str(x.get('version'))==str(RELEASE[app]['build'])),None)
  state['apps'][app]['versionId']=v['id'] if v else None
  state['apps'][app]['buildId']=b['id'] if b else None
  print('INSPECT',app,'candidate',v['appStoreState'] if v else None,'build',b.get('processingState') if b else None)
 save()
def versions():
 for app,aid in APPS.items():
  v=version(app)
  if not v:
   p={'data':{'type':'appStoreVersions','attributes':{'platform':'IOS',
    'versionString':RELEASE[app]['version'],'copyright':'© 2026 LLC ARVECTUM',
    'releaseType':'AFTER_APPROVAL','usesIdfa':app in ('photo','chickmark')},
    'relationships':{'app':{'data':{'type':'apps','id':aid}}}}}
   d=must('POST','/appStoreVersions',p,ok=(201,))
   v={**d['data']['attributes'],'id':d['data']['id']}
  print('VERSION',app,RELEASE[app]['version'],v['appStoreState'],v['id'],flush=True)
  state['apps'][app]['versionId']=v['id'];save()
def metadata():
 for app,aid in APPS.items():
  v=version(app)
  if not v or v['appStoreState']!='PREPARE_FOR_SUBMISSION':
   raise RuntimeError(f'Cannot modify non-editable version for {app}: {v}')
  vid=v['id']
  locs={x['locale']:x for x in attrs(must('GET',f'/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=50'))}
  infos=attrs(must('GET',f'/apps/{aid}/appInfos?limit=10'))
  info=next((i for i in infos if i.get('state')=='PREPARE_FOR_SUBMISSION'),None)
  if info is None:raise RuntimeError(f'No editable appInfo for {app}; refuse editing live app info')
  infolocs={x['locale']:x for x in attrs(must('GET',f'/appInfos/{info["id"]}/appInfoLocalizations?limit=50'))}
  data=json.loads((ASO/(app+'.json')).read_text())['localeData']
  for locale,rec in data.items():
   vattrs={k:rec[k] for k in ['description','keywords','promotionalText','whatsNew']}
   vattrs['supportUrl']='https://arvectum.com'
   if locale in locs:
    lid=locs[locale]['id']
    if any(locs[locale].get(k)!=value for k,value in vattrs.items()):
     must('PATCH',f'/appStoreVersionLocalizations/{lid}',{'data':{'type':'appStoreVersionLocalizations','id':lid,'attributes':vattrs}})
   else:
    p={'data':{'type':'appStoreVersionLocalizations','attributes':{'locale':locale,**vattrs},
      'relationships':{'appStoreVersion':{'data':{'type':'appStoreVersions','id':vid}}}}}
    d=must('POST','/appStoreVersionLocalizations',p,ok=(201,));lid=d['data']['id']
   state['apps'][app].setdefault('locales',{})[locale]=lid;save()
   iattrs={k:rec[k] for k in ['name','subtitle','privacyPolicyUrl']}
   # Apple sometimes creates matching appInfo localization automatically when
   # the new appStoreVersionLocalization is added. Refresh before POST.
   if locale not in infolocs:
    infolocs={x['locale']:x for x in attrs(must('GET',f'/appInfos/{info["id"]}/appInfoLocalizations?limit=50'))}
   if locale in infolocs:
    id= infolocs[locale]['id']
    delta={k:value for k,value in iattrs.items() if infolocs[locale].get(k)!=value}
    if delta:must('PATCH',f'/appInfoLocalizations/{id}',{'data':{'type':'appInfoLocalizations','id':id,'attributes':delta}})
   else:
    p={'data':{'type':'appInfoLocalizations','attributes':{'locale':locale,**iattrs},
     'relationships':{'appInfo':{'data':{'type':'appInfos','id':info['id']}}}}}
    must('POST','/appInfoLocalizations',p,ok=(201,))
   print('LOCALE_OK',app,locale,flush=True)
  state['apps'][app]['metadataComplete']=True;save()
  print('METADATA_DONE',app,flush=True)
def attach():
 for app,aid in APPS.items():
  v=version(app)
  if not v or v['appStoreState']!='PREPARE_FOR_SUBMISSION':raise RuntimeError('Invalid version stage '+app)
  builds=attrs(must('GET',f'/builds?filter%5Bapp%5D={aid}&limit=50'))
  b=next((x for x in builds if str(x.get('version'))==str(RELEASE[app]['build'])),None)
  if not b or b.get('processingState')!='VALID':
   print('BUILD_WAIT',app,b.get('processingState') if b else None,flush=True)
   continue
  # This API may return 200 or 204 for the relationship update.
  must('PATCH',f'/appStoreVersions/{v["id"]}/relationships/build',{'data':{'type':'builds','id':b['id']}})
  must('PATCH',f'/appStoreVersions/{v["id"]}',{'data':{'type':'appStoreVersions','id':v['id'],
    'attributes':{'releaseType':'AFTER_APPROVAL','usesIdfa':app in ('photo','chickmark')}}})
  state['apps'][app]['buildId']=b['id'];state['apps'][app]['buildAttached']=True;save()
  print('BUILD_ATTACHED',app,RELEASE[app]['version'],RELEASE[app]['build'],flush=True)
if __name__=='__main__':
 import sys
 globals()[sys.argv[1] if len(sys.argv)>1 else 'inspect']()
