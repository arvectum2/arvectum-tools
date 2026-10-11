#!/usr/bin/env python3
import json, os, pathlib, re, subprocess, sys, urllib.parse, urllib.request, urllib.error

CONFIG = pathlib.Path.home()/".config/arvectum/appstore-connect.env"
if not CONFIG.exists():
    raise SystemExit("Missing App Store Connect config")

vals={}
for raw in CONFIG.read_text().splitlines():
    line=raw.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    k,v=line.split("=",1)
    vals[k.strip()]=v.strip().strip('"').strip("'")

key_id=vals.get("ASC_KEY_ID")
issuer=vals.get("ASC_ISSUER_ID")
key_dir=pathlib.Path(vals.get("ASC_KEY_DIR", str(pathlib.Path.home()/".appstoreconnect/private_keys")))
if not key_id or not issuer:
    raise SystemExit("ASC_KEY_ID / ASC_ISSUER_ID missing")

xcode=os.environ.get("ASC_XCODE","/Applications/Xcode-27.0.0.app")
altool=f"{xcode}/Contents/SharedFrameworks/ContentDelivery.framework/Versions/A/Resources/altool"
env=os.environ.copy()
env["API_PRIVATE_KEYS_DIR"]=str(key_dir)
p=subprocess.run([altool,"--generate-jwt","--apiKey",key_id,"--apiIssuer",issuer],
                 text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=env,check=False)
blob=p.stdout+"\n"+p.stderr
m=re.search(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+",blob)
if not m:
    raise SystemExit("JWT generation failed")
token=m.group(0)

base="https://api.appstoreconnect.apple.com"
def api(method,path,body=None):
    data=None if body is None else json.dumps(body,separators=(",",":")).encode()
    req=urllib.request.Request(base+path,data=data,method=method)
    req.add_header("Authorization","Bearer "+token)
    req.add_header("Content-Type","application/json")
    try:
        with urllib.request.urlopen(req,timeout=30) as r:
            return r.status,json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        txt=e.read().decode()
        try: payload=json.loads(txt)
        except Exception: payload={"raw":txt}
        return e.code,payload

identifier=sys.argv[1] if len(sys.argv)>1 else "ru.arvectum.tools.notify"
name=sys.argv[2] if len(sys.argv)>2 else "PUSHKIN"
q=urllib.parse.quote(identifier,safe="")
status,payload=api("GET",f"/v1/bundleIds?filter%5Bidentifier%5D={q}")
items=payload.get("data",[])
if items:
    item=items[0]
    print("EXISTS",item["id"],item["attributes"].get("identifier"),item["attributes"].get("name"))
    raise SystemExit(0)

body={"data":{"type":"bundleIds","attributes":{"identifier":identifier,"name":name,"platform":"IOS"}}}
status,payload=api("POST","/v1/bundleIds",body)
if status not in (200,201):
    print("HTTP",status)
    print(json.dumps(payload,ensure_ascii=False,indent=2))
    raise SystemExit(2)
item=payload["data"]
print("CREATED",item["id"],item["attributes"].get("identifier"),item["attributes"].get("name"))
