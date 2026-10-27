#!/usr/bin/env python3
"""Apply hand-edited ASO language review over reproducible translation drafts.

Never rewrites base machine translation cache or publishes anything.
Source of truth: editorial/c13-overrides.json (not generated translation).
"""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]/"core/appstore/staged-2026-10-26"
overrides=json.loads((ROOT/"editorial/c13-overrides.json").read_text())
allowed={"name","subtitle","keywords","promotionalText","description","whatsNew","screenshots"}
count=0
for app,locales in overrides.items():
    path=ROOT/f"{app}.json"
    data=json.loads(path.read_text())
    for loc,patch in locales.items():
        assert loc in data["localeData"],(app,loc)
        assert set(patch)<=allowed, (app,loc,set(patch)-allowed)
        assert not set(patch)&{"appId","bundleId","privacyPolicyUrl"}
        if "screenshots" in patch:assert len(patch["screenshots"])==4,(app,loc)
        data["localeData"][loc].update(patch)
        count+=1
    data["source"]="curated EN/RU seeds, translation draft and C13 AI linguistic editorial overrides; not independently native-speaker approved"
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n")
    print(app,len(locales),"reviewed")
# Updating localized captions must not discard previously verified native PNGs.
# Keep the file, status and SHA; only the caption associated with each slot changes.
import hashlib
manifest_path=ROOT/"screenshot_manifest.json"
manifest=json.loads(manifest_path.read_text())
updated=0
for app, group in manifest["apps"].items():
    entries=json.loads((ROOT/f"{app}.json").read_text())["localeData"]
    for shot in group["slots"]:
        desired=entries[shot["locale"]]["screenshots"][shot["position"]-1]
        if desired==shot["headline"]:
            continue
        if shot.get("path"):
            file=ROOT.parents[2]/shot["path"]
            assert file.is_file(), file
            assert hashlib.sha256(file.read_bytes()).hexdigest()==shot["sha256"],file
        shot["headline"]=desired
        updated+=1
if updated:
    manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
print("Applied",count,"regional overrides;",updated,
      "captions synchronized to existing native files (no ASC writes)")
# C14 keyword overlay: exact title/subtitle duplicates replaced, original preserved.
kw=json.loads((ROOT/'editorial/c14-keyword-overrides.json').read_text())
for app,locales in kw.items():
 p=ROOT/f'{app}.json';d=json.loads(p.read_text())
 for loc,rec in locales.items():
  assert d['localeData'][loc]['keywords'] in (rec['before'],rec['after'])
  d['localeData'][loc]['keywords']=rec['after']
 p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
print('C14 keyword changes',sum(len(v) for v in kw.values()))

# C17 IndieAppCircle feedback What's New copy (curated, not live ASC).
notes=json.loads((ROOT/'editorial/c17-feedback-whatsnew-overrides.json').read_text())
for app,locales in notes.items():
    path=ROOT/f'{app}.json'
    metadata=json.loads(path.read_text())
    for locale,record in locales.items():
        current=metadata['localeData'][locale]['whatsNew']
        assert current in (record['before'],record['after']), (app,locale,'unexpected release-note source')
        metadata['localeData'][locale]['whatsNew']=record['after']
    path.write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n')
print('C17 release notes applied:',sum(len(v) for v in notes.values()))
