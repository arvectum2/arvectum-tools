#!/usr/bin/env python3
import json, os, re, subprocess, urllib.request, urllib.error
from pathlib import Path

APP_ID="6816346084"
VERSION_ID="e0d324d2-1af2-441f-9f6c-5c80dba39f1b"
API="https://api.appstoreconnect.apple.com/v1"
CONFIG=Path.home()/".config/arvectum/appstore-connect.env"
ALTOOL="/Applications/Xcode-26.6.0.app/Contents/SharedFrameworks/ContentDelivery.framework/Versions/A/Resources/altool"

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
m=re.search(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+",p.stderr+p.stdout)
if not m: raise SystemExit("JWT generation failed")
TOKEN=m.group(0)

def api(method,path,payload=None):
    data=None if payload is None else json.dumps(payload).encode()
    req=urllib.request.Request(API+path,data=data,method=method,headers={
        "Authorization":"Bearer "+TOKEN,"Content-Type":"application/json"})
    try:
        with urllib.request.urlopen(req,timeout=60) as r:
            raw=r.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        body=e.read().decode(errors="replace")
        print("HTTP_ERROR",method,path,e.code,body)
        return None

v=api("GET",f"/appStoreVersions/{VERSION_ID}?include=build")
if v:
    a=v["data"]["attributes"]
    print("VERSION",a.get("versionString"),a.get("appStoreState") or a.get("appVersionState"))
    for x in v.get("included",[]):
        if x.get("type")=="builds":
            print("ATTACHED_BUILD",x["id"],x["attributes"].get("version"),x["attributes"].get("processingState"))

d=api("GET",f"/appStoreVersions/{VERSION_ID}/appStoreReviewDetail")
if d and d.get("data"):
    x=d["data"]; print("REVIEW_DETAIL",x["id"],"notes_chars",len(x["attributes"].get("notes") or ""))

s=api("GET",f"/apps/{APP_ID}/reviewSubmissions?limit=50")
if s:
    for x in s.get("data",[]):
        print("SUBMISSION",x["id"],x["attributes"].get("state"),x["attributes"].get("submittedDate"))
        items=api("GET",f"/reviewSubmissions/{x['id']}/items?include=appStoreVersion&limit=50")
        if items:
            for it in items.get("data",[]):
                rel=(it.get("relationships") or {}).get("appStoreVersion",{}).get("data")
                print(" ITEM",it["id"],it["attributes"].get("state"),"version",rel.get("id") if rel else None)
