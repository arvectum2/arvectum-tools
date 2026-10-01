#!/usr/bin/env python3
import json, os, pathlib, re, subprocess, urllib.request, urllib.error

APP_ID="6817847111"
VERSION_ID="87056df5-93c9-411f-b44c-2e3ea5cae5bf"
BUILD_ID="b6bc26a1-dfc5-4dd5-843c-cca530ddb95e"
SOURCE_APP_ID="6816346084"  # existing Arvectum app; reuse the owner's review contact without storing PII in this repo
NOTES="""PUSHKIN 1.0.0 (2) — response to Guideline 2.1 Information Needed

A physical-device demonstration video is attached to this App Review submission. It was recorded from an iPhone running iOS 27.0.1 using Apple's iPhone Mirroring so the reviewer can see the real-device UI clearly.

1. PURPOSE / AUDIENCE / PROBLEM / VALUE
PUSHKIN is a consumer utility for iPhone users who want a searchable local history of notifications they may otherwise dismiss or lose. It preserves selected notification content locally so users can find important alerts later.

2. ACCESS / SETUP
No registration, login, subscription, purchase, reviewer account, credentials, or sample files are required.
- Launch PUSHKIN.
- On History, tap Set up PUSHKIN.
- PUSHKIN opens Apple's Shortcuts app with the bundled signed configuration.
- Add the configuration and enable the PUSHKIN Notification automation if iOS imports it disabled.
- Allow it to run automatically / while locked if iOS asks.
- Send a notification from a configured source app. It appears in PUSHKIN History.
- For a supported app installed later, tap + on History or Add app in Settings.
- If an app is outside the bundled catalog, PUSHKIN provides a local manual Shortcuts setup guide.

3. EXTERNAL SERVICES / TOOLS / PLATFORMS
Core functionality uses only Apple platform technologies: Shortcuts / Automation, App Intents, SwiftData, and standard iOS APIs. PUSHKIN 1.0 has no backend, account service, cloud sync, payment processor, analytics SDK, advertising SDK, AI service, or third-party data provider. Notification content is not sent to Arvectum servers.

4. REGIONAL DIFFERENCES
Core functionality is the same in all App Store regions. The bundled app catalog is maintained across storefronts; uncommon apps can be configured manually.

5. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
PUSHKIN does not operate in a regulated industry and does not provide, resell, stream, or redistribute protected third-party content. App names are used only to identify user-selected notification sources.

6. REVIEW VIDEO
The attached physical-device video shows History, the merged Settings screen with build 1.0.0 (2), Add App, the manual Shortcuts fallback, and a return to History. The app contains no developer/debug UI in the submitted build.

Suggested reviewer test sources: Messages, Mail, Telegram, or another installed catalog app.
"""

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

# 2) Attach the validated build 2.
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
