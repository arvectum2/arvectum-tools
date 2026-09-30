#!/usr/bin/env python3
import hashlib, json, os, pathlib, re, subprocess, sys, time, urllib.parse, urllib.request, urllib.error

APP_ID="6817847111"
VERSION_ID="87056df5-93c9-411f-b44c-2e3ea5cae5bf"
LOCALIZATIONS={
    "en-US":"0a199bb5-0204-4f8a-ab14-89118afb55f1",
    "ru":"c43539e8-325c-4307-b479-20816615b9fa",
}
DISPLAY_TYPE="APP_IPHONE_67"
ROOT=pathlib.Path("/Users/master/arvectum-tools/apps/pushkin/store-assets/appstore/iphone-6.9")
FILES=[ROOT/"01-history.png",ROOT/"02-apps.png",ROOT/"03-privacy.png"]

CONFIG=pathlib.Path.home()/".config/arvectum/appstore-connect.env"
vals={}
for raw in CONFIG.read_text().splitlines():
    line=raw.strip()
    if line and not line.startswith("#") and "=" in line:
        k,v=line.split("=",1); vals[k.strip()]=v.strip().strip('"').strip("'")
key_id=vals["ASC_KEY_ID"]; issuer=vals["ASC_ISSUER_ID"]
key_dir=pathlib.Path(vals.get("ASC_KEY_DIR", str(pathlib.Path.home()/".appstoreconnect/private_keys")))
altool="/Applications/Xcode-27.0.0.app/Contents/SharedFrameworks/ContentDelivery.framework/Versions/A/Resources/altool"
env=os.environ.copy(); env["API_PRIVATE_KEYS_DIR"]=str(key_dir)
p=subprocess.run([altool,"--generate-jwt","--apiKey",key_id,"--apiIssuer",issuer],text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=env)
m=re.search(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+",p.stdout+"\n"+p.stderr)
if not m: raise SystemExit("JWT generation failed")
token=m.group(0)
BASE="https://api.appstoreconnect.apple.com"

def api(method,path,body=None):
    data=None if body is None else json.dumps(body,separators=(",",":")).encode()
    req=urllib.request.Request(BASE+path,data=data,method=method)
    req.add_header("Authorization","Bearer "+token)
    if body is not None: req.add_header("Content-Type","application/json")
    try:
        with urllib.request.urlopen(req,timeout=60) as r:
            raw=r.read().decode()
            return r.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw=e.read().decode()
        try: payload=json.loads(raw)
        except Exception: payload={"raw":raw}
        return e.code,payload

def must(method,path,body=None,ok=(200,201,204)):
    status,payload=api(method,path,body)
    if status not in ok:
        print("FAILED",method,path,status,json.dumps(payload,ensure_ascii=False))
        raise SystemExit(2)
    return payload

def get_or_create_set(localization_id):
    q=urllib.parse.urlencode({"filter[screenshotDisplayType]":DISPLAY_TYPE})
    p=must("GET",f"/v1/appStoreVersionLocalizations/{localization_id}/appScreenshotSets?{q}")
    sets=p.get("data",[])
    if sets:
        return sets[0]["id"]
    body={"data":{"type":"appScreenshotSets","attributes":{"screenshotDisplayType":DISPLAY_TYPE},
          "relationships":{"appStoreVersionLocalization":{"data":{"type":"appStoreVersionLocalizations","id":localization_id}}}}}
    p=must("POST","/v1/appScreenshotSets",body)
    return p["data"]["id"]

def list_shots(set_id):
    return must("GET",f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=200").get("data",[])

def state_name(shot):
    s=shot.get("attributes",{}).get("assetDeliveryState")
    if isinstance(s,dict):
        return s.get("state") or s.get("status") or json.dumps(s,sort_keys=True)
    return str(s)

def upload_part(op, data):
    offset=int(op.get("offset",0))
    length=int(op.get("length",len(data)-offset))
    part=data[offset:offset+length]
    req=urllib.request.Request(op["url"],data=part,method=op.get("method","PUT"))
    for h in op.get("requestHeaders") or []:
        name=h.get("name"); value=h.get("value")
        if name and value is not None:
            req.add_header(name,str(value))
    if not any((h.get("name","").lower()=="content-length") for h in (op.get("requestHeaders") or [])):
        req.add_header("Content-Length",str(len(part)))
    try:
        with urllib.request.urlopen(req,timeout=120) as r:
            r.read()
            if r.status not in (200,201,202,204):
                raise RuntimeError(f"upload status {r.status}")
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"asset upload HTTP {e.code}: {e.read().decode(errors='replace')[:1000]}")

def upload_file(set_id,path):
    blob=path.read_bytes()
    body={"data":{"type":"appScreenshots","attributes":{"fileSize":len(blob),"fileName":path.name},
          "relationships":{"appScreenshotSet":{"data":{"type":"appScreenshotSets","id":set_id}}}}}
    p=must("POST","/v1/appScreenshots",body)
    shot=p["data"]; shot_id=shot["id"]
    ops=shot.get("attributes",{}).get("uploadOperations") or []
    if not ops:
        raise RuntimeError(f"No upload operations for {path.name}")
    for op in ops:
        upload_part(op,blob)
    checksum=hashlib.md5(blob).hexdigest()
    must("PATCH",f"/v1/appScreenshots/{shot_id}",{
        "data":{"type":"appScreenshots","id":shot_id,
                "attributes":{"uploaded":True,"sourceFileChecksum":checksum}}
    })
    deadline=time.time()+180
    while time.time()<deadline:
        p=must("GET",f"/v1/appScreenshots/{shot_id}")
        data=p["data"]; state=state_name(data)
        attrs=data.get("attributes",{})
        if state in ("COMPLETE","UPLOAD_COMPLETE","SUCCEEDED","SUCCESS"):
            print("READY",path.name,shot_id,state)
            return shot_id
        if "FAIL" in state or "ERROR" in state:
            raise RuntimeError(f"{path.name} delivery failed: {attrs.get('assetDeliveryState')}")
        time.sleep(3)
    raise TimeoutError(f"Timed out processing {path.name}")

for p in FILES:
    if not p.is_file():
        raise SystemExit(f"Missing {p}")

for locale,loc_id in LOCALIZATIONS.items():
    set_id=get_or_create_set(loc_id)
    existing=list_shots(set_id)
    if existing:
        # This release owns this newly-created set; clear stale/incomplete attempts.
        for s in existing:
            must("DELETE",f"/v1/appScreenshots/{s['id']}")
    print("SET",locale,set_id)
    ids=[]
    for path in FILES:
        ids.append(upload_file(set_id,path))
    print("DONE",locale,",".join(ids))
print("SCREENSHOTS_UPLOADED")
