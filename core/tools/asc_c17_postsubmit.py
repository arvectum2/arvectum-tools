#!/usr/bin/env python3
"""Read-only exact C17 App Review and publication status verification."""
import json
from pathlib import Path
import asc_c17_release as asc
results={}
for app,appid in asc.APPS.items():
    v=asc.version(app)
    if not v:raise RuntimeError(f'Missing C17 app version for {app}')
    submissions=asc.attrs(asc.must('GET',f'/apps/{appid}/reviewSubmissions?limit=50'))
    matching=[]
    for submission in submissions:
        if submission.get('platform') not in ('IOS',None):continue
        items=asc.must('GET',f'/reviewSubmissions/{submission["id"]}/items?limit=200')['data']
        if any((i.get('relationships',{}).get('appStoreVersion',{}).get('data') or {}).get('id')==v['id'] for i in items):
            matching.append({'id':submission['id'],'state':submission.get('state'),
                            'submittedDate':submission.get('submittedDate')})
    entry={'appleAppID':appid,'candidate':asc.RELEASE[app]['version'],
        'versionID':v['id'],'appStoreState':v['appStoreState'],
        'releaseType':v.get('releaseType'),'reviewSubmissions':matching}
    results[app]=entry
    print('APP_REVIEW_STATUS',app,entry['candidate'],entry['appStoreState'],
          entry['releaseType'],[s['state'] for s in matching],flush=True)
out=asc.QA/'c17-review-status.json'
out.write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
print('ASC_READBACK_SAVED',out)
