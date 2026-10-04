#!/usr/bin/env python3
import json, os, re, subprocess, urllib.request, urllib.error
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
APP_ID="6816346084"
VERSION_ID="e0d324d2-1af2-441f-9f6c-5c80dba39f1b"
APP_INFO_ID="b031f76b-cd3f-48a5-9aaa-9f07239d8144"
API="https://api.appstoreconnect.apple.com/v1"
CONFIG=Path.home()/".config/arvectum/appstore-connect.env"
ALTOOL=subprocess.run(["xcrun","--find","altool"],text=True,capture_output=True,check=True).stdout.strip()

cfg={}
for raw in CONFIG.read_text().splitlines():
    line=raw.strip()
    if not line or line.startswith("#") or "=" not in line: continue
    if line.startswith("export "): line=line[7:]
    k,v=line.split("=",1); cfg[k.strip()]=v.strip().strip("'").strip('"')
env=os.environ.copy()
env["API_PRIVATE_KEYS_DIR"]=cfg.get("ASC_KEY_DIR",str(Path.home()/".appstoreconnect/private_keys"))
p=subprocess.run([ALTOOL,"--generate-jwt","--apiKey",cfg["ASC_KEY_ID"],"--apiIssuer",cfg["ASC_ISSUER_ID"]],
                 env=env,text=True,capture_output=True,check=True)
TOKEN=re.search(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+",p.stderr).group(0)

def api(method,path,payload=None):
    data=None if payload is None else json.dumps(payload,ensure_ascii=False).encode()
    req=urllib.request.Request(API+path,data=data,method=method,headers={
        "Authorization":"Bearer "+TOKEN,"Content-Type":"application/json"})
    try:
        with urllib.request.urlopen(req,timeout=60) as r:
            raw=r.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        body=e.read().decode(errors="replace")
        raise RuntimeError(f"{method} {path} HTTP {e.code}: {body}") from e

locs=api("GET",f"/appInfos/{APP_INFO_ID}/appInfoLocalizations?limit=20")["data"]
loc=next(x for x in locs if x["attributes"].get("locale")=="ru")
api("PATCH",f"/appInfoLocalizations/{loc['id']}",{
    "data":{"type":"appInfoLocalizations","id":loc["id"],"attributes":{
        "subtitle":"Сжатие и размер фото",
        "privacyPolicyUrl":"https://github.com/arvectum2/arvectum-tools/blob/main/PRIVACY.md"
    }}
})
print("APP_INFO_LOCALIZATION_UPDATED",loc["id"])

review=api("GET",f"/appStoreVersions/{VERSION_ID}/appStoreReviewDetail").get("data")
notes=(ROOT/"docs"/"appstore"/"REVIEW_NOTES_TEXT_2026-09-27.txt").read_text()
review_attrs={
    "contactFirstName":cfg["ASC_REVIEW_FIRST_NAME"],
    "contactLastName":cfg["ASC_REVIEW_LAST_NAME"],
    "contactPhone":cfg["ASC_REVIEW_PHONE"],
    "contactEmail":cfg["ASC_REVIEW_EMAIL"],
    "demoAccountRequired":False,
    "notes":notes
}
if review is None:
    review=api("POST","/appStoreReviewDetails",{
        "data":{"type":"appStoreReviewDetails","attributes":review_attrs,
                "relationships":{"appStoreVersion":{"data":{
                    "type":"appStoreVersions","id":VERSION_ID
                }}}}
    })["data"]
else:
    api("PATCH",f"/appStoreReviewDetails/{review['id']}",{
        "data":{"type":"appStoreReviewDetails","id":review["id"],"attributes":review_attrs}
    })
print("REVIEW_DETAIL_UPDATED",review["id"])

api("PATCH",f"/apps/{APP_ID}",{
    "data":{"type":"apps","id":APP_ID,"attributes":{
        "contentRightsDeclaration":"DOES_NOT_USE_THIRD_PARTY_CONTENT"
    }}
})
print("CONTENT_RIGHTS_UPDATED")
