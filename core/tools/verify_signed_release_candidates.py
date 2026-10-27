#!/usr/bin/env python3
"""Read-only local verification for exactly four signed IPA release candidates.

No Apple network access, no build/upload/submission, no secrets in committed manifest.
"""
import hashlib, json, plistlib, subprocess, zipfile, tempfile
from pathlib import Path

QA=Path('/Volumes/ArvectumSSD/Arvectum/qa/indieappcircle-release-candidates-20261027')
ROOT=Path(__file__).resolve().parents[2]
RELEASES={
 'photo':('1.0.4','16'),
 'pushkin':('1.0.3','7'),
 'what':('1.1.2','10'),
 'chickmark':('1.5.3','21')
}
manifest={'stage':'SIGNED_QA_NOT_UPLOADED','date':'2026-10-27','apps':{}}
for name,(expectedVersion,expectedBuild) in RELEASES.items():
  ipas=list((QA/f'export-{name}').glob('*.ipa'))
  if len(ipas)!=1:raise SystemExit(f'Missing/ambiguous IPA for {name}: {ipas}')
  ipa=ipas[0]
  with tempfile.TemporaryDirectory(prefix='arvectum-signed-review-') as work:
    # Python zipfile.extractall drops Unix executable bits from nested
    # signed Shortcuts/tool resources; ditto preserves Apple's IPA metadata.
    extracted=subprocess.run(['/usr/bin/ditto','-x','-k',str(ipa),work],
                              capture_output=True,text=True)
    if extracted.returncode:
      raise SystemExit(f'{name}: ditto failed: {extracted.stderr[-500:]}')
    apps=list((Path(work)/'Payload').glob('*.app'))
    if len(apps)!=1:raise SystemExit(f'{name}: application bundle count != 1')
    bundle=apps[0]
    main=plistlib.loads((bundle/'Info.plist').read_bytes())
    v,b=main.get('CFBundleShortVersionString'),str(main.get('CFBundleVersion'))
    if (v,b)!=(expectedVersion,expectedBuild):
      raise SystemExit(f'{name}: expected {expectedVersion} ({expectedBuild}) got {v} ({b})')
    if not (bundle/'PrivacyInfo.xcprivacy').is_file():
      raise SystemExit(f'{name}: main privacy manifest missing')
    codesign=subprocess.run(['codesign','--verify','--deep','--strict',str(bundle)],
       capture_output=True,text=True)
    if codesign.returncode:
      raise SystemExit(f'{name}: code signing invalid: {codesign.stderr[-1200:]}')
    info=subprocess.run(['codesign','-dv','--verbose=2',str(bundle)],capture_output=True,text=True)
    signed=info.stderr+info.stdout
    if 'Authority=Apple Distribution: LLC ARVECTUM (VML75VY94V)' not in signed:
      raise SystemExit(f'{name}: distribution identity is not expected LLC ARVECTUM')
    children=[]
    for child in bundle.rglob('*.appex'):
      p=plistlib.loads((child/'Info.plist').read_bytes())
      cv,cb=p.get('CFBundleShortVersionString'),str(p.get('CFBundleVersion'))
      if (cv,cb)!=(v,b):raise SystemExit(f'{name}: extension mismatch: {child}')
      if not (child/'PrivacyInfo.xcprivacy').exists():
        raise SystemExit(f'{name}: extension privacy manifest missing: {child}')
      children.append({'type':'appex','version':cv,'build':cb})
    for child in bundle.rglob('*.app'):
      if child==bundle:continue
      p=plistlib.loads((child/'Info.plist').read_bytes())
      cv,cb=p.get('CFBundleShortVersionString'),str(p.get('CFBundleVersion'))
      if (cv,cb)!=(v,b):raise SystemExit(f'{name}: watch extension mismatch: {child}')
      if not (child/'PrivacyInfo.xcprivacy').exists():
        raise SystemExit(f'{name}: embedded app privacy manifest missing: {child}')
      children.append({'type':'embeddedApp','version':cv,'build':cb})
  digest=hashlib.sha256(ipa.read_bytes()).hexdigest()
  manifest['apps'][name]={
   'version':v,'build':b,'sha256':digest,'sizeBytes':ipa.stat().st_size,
   'signedBy':'Apple Distribution: LLC ARVECTUM (VML75VY94V)',
   'codesignVerified':True,'mainPrivacyManifest':True,
   'embeddedBundleCount':len(children),'embeddedBundles':children}
  print(f'VALID {name} {v}({b}) sha256={digest} bytes={ipa.stat().st_size} embedded={len(children)}')
out=ROOT/'core/docs/INDIEAPPCIRCLE_C17_SIGNED_RELEASE_MANIFEST.json'
out.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('LOCAL_SIGNED_QA_ALL_PASS; NO_APPLE_UPLOAD')
