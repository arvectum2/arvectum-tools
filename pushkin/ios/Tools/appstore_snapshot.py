#!/usr/bin/env python3
import json, os, pathlib, re, subprocess, sys, urllib.request, urllib.error, urllib.parse, time

APP_ID=sys.argv[1] if len(sys.argv)>1 else "6817847111"
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
def get(path):
    req=urllib.request.Request("https://api.appstoreconnect.apple.com"+path)
    req.add_header("Authorization","Bearer "+token)
    try:
        with urllib.request.urlopen(req,timeout=30) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return {"http_error":e.code,"body":e.read().decode()}
def attrs(items):
    return [{"id":x.get("id"), **x.get("attributes",{})} for x in items.get("data",[])]
out={}
out["app"]=get(f"/v1/apps/{APP_ID}").get("data",{})
out["versions"]=attrs(get(f"/v1/apps/{APP_ID}/appStoreVersions?limit=20"))
out["builds"]=attrs(get(f"/v1/builds?filter%5Bapp%5D={APP_ID}&include=preReleaseVersion&limit=20"))
out["infos"]=attrs(get(f"/v1/apps/{APP_ID}/appInfos?limit=20"))
for v in out["versions"]:
    v["localizations"]=attrs(get(f"/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations?limit=50"))
    review=get(f"/v1/appStoreVersions/{v['id']}/appStoreReviewDetail")
    v["reviewDetail"]=review.get("data",{}) if isinstance(review,dict) else {}
for info in out["infos"]:
    info["localizations"]=attrs(get(f"/v1/appInfos/{info['id']}/appInfoLocalizations?limit=50"))
    info["ageRatingDeclaration"]=get(f"/v1/appInfos/{info['id']}/ageRatingDeclaration").get("data",{})
out["priceSchedule"]=get(f"/v1/apps/{APP_ID}/appPriceSchedule")
out["availability"]=get(f"/v1/apps/{APP_ID}/appAvailabilityV2")
print(json.dumps(out,ensure_ascii=False,indent=2))
