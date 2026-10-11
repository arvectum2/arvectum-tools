#!/usr/bin/env python3
import json, os, pathlib, re, subprocess, urllib.request, urllib.error

APP_ID="6817847111"
VERSION_ID="87056df5-93c9-411f-b44c-2e3ea5cae5bf"
BUILD_ID="66835792-b1d8-4bb4-abad-1313fe14a445"
SOURCE_APP_ID="6816346084"  # existing Arvectum app; reuse the owner's review contact without storing PII in this repo
NOTES="""PUSHKIN is a local notification-history utility for iPhone.

ACCESS / SETUP
No registration, login, subscription, purchase, or reviewer account is required.

1. Launch PUSHKIN.
2. On History, tap “Set up PUSHKIN”.
3. iOS opens the signed PUSHKIN configuration in Shortcuts.
4. Add the configuration and enable the PUSHKIN Notification automation if iOS imports it disabled.
5. Allow it to run automatically / while locked if iOS asks.
6. Send a real notification from a configured source app. It will appear in PUSHKIN History.

APP COVERAGE
The bundled configuration contains a maintained catalog of explicit source-app descriptors. PUSHKIN does not claim wildcard access to every installed app. A newly installed supported app can be added with “+ App”. If an app is outside the bundled catalog, PUSHKIN provides a manual Shortcuts setup guide.

DATA / EXTERNAL SERVICES
Notification content is stored only in the app’s local SwiftData database. Version 1.0 has no account system, backend, cloud sync, analytics SDK, advertising SDK, tracking, or runtime App Store lookup. The app opens Apple’s Shortcuts app for setup.

REGIONAL DIFFERENCES
Core functionality is the same in all regions. The app catalog is bundled with the app; uncommon apps can be configured manually.

Suggested reviewer test sources: Messages, Mail, Telegram, or another installed catalog app."""

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
token=m.group(0); BASE="https://api.appstoreconnect.apple.com"

def api(method,path,body=None):
    data=None if body is None else json.dumps(body,separators=(",",":")).encode()
    req=urllib.request.Request(BASE+path,data=data,method=method)
    req.add_header("Authorization","Bearer "+token)
    if body is not None: req.add_header("Content-Type","application/json")
    try:
        with urllib.request.urlopen(req,timeout=45) as r:
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
    print("OK",method,path,status)
    return payload

# 1) Final release attributes: fastest publication after approval.
must("PATCH",f"/v1/appStoreVersions/{VERSION_ID}",{
  "data":{"type":"appStoreVersions","id":VERSION_ID,"attributes":{
    "copyright":"© 2026 LLC ARVECTUM",
    "releaseType":"AFTER_APPROVAL",
    "usesIdfa":False
  }}
})

# 2) Attach the validated build 1.
must("PATCH",f"/v1/appStoreVersions/{VERSION_ID}/relationships/build",{
  "data":{"type":"builds","id":BUILD_ID}
})

# 3) Reuse App Review contact information from an existing Arvectum iOS app,
# without copying personal contact data into source control.
status,versions=api("GET",f"/v1/apps/{SOURCE_APP_ID}/appStoreVersions?limit=20")
source_contact=None
for v in versions.get("data",[]):
    status,review=api("GET",f"/v1/appStoreVersions/{v['id']}/appStoreReviewDetail")
    if status==200:
        a=review.get("data",{}).get("attributes",{})
        if all(a.get(k) for k in ("contactFirstName","contactLastName","contactPhone","contactEmail")):
            source_contact={k:a[k] for k in ("contactFirstName","contactLastName","contactPhone","contactEmail")}
            break
if not source_contact:
    raise SystemExit("Could not retrieve reusable App Review contact from existing Arvectum app")

review_attrs={**source_contact,
    "demoAccountRequired":False,
    "demoAccountName":None,
    "demoAccountPassword":None,
    "notes":NOTES
}
status,current=api("GET",f"/v1/appStoreVersions/{VERSION_ID}/appStoreReviewDetail")
current_data=current.get("data") if isinstance(current,dict) else None
if status==200 and isinstance(current_data,dict) and current_data.get("id"):
    rid=current_data["id"]
    must("PATCH",f"/v1/appStoreReviewDetails/{rid}",{
      "data":{"type":"appStoreReviewDetails","id":rid,"attributes":review_attrs}
    })
else:
    must("POST","/v1/appStoreReviewDetails",{
      "data":{"type":"appStoreReviewDetails","attributes":review_attrs,
              "relationships":{"appStoreVersion":{"data":{"type":"appStoreVersions","id":VERSION_ID}}}}
    })

print("VERSION_FINALIZED")
