#!/usr/bin/env python3
"""Publish the approved Photo & PDF Size 1.0.0 release through App Store Connect.

Modes are explicit and idempotent: inspect, prepare, screenshots, attach, submit.
Never prints tokens or the App Store reviewer contact details.
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

APP_ID = "6816346084"
APP_INFO_ID = "271cc548-f2a2-49de-8620-a38cd1d81e06"
VERSION = "1.0.0"
BUILD_NUMBER = "12"
API = "https://api.appstoreconnect.apple.com/v1"
ROOT = Path(__file__).resolve().parents[2]
METADATA = ROOT / "docs/aso/metadata-2026-10-10.json"
SHOTS = ROOT / "store-assets/appstore/aso"
CONFIG = Path.home() / ".config/arvectum/appstore-connect.env"
STATE = ROOT / "ios/build/release-1.0.0-appstore-state.json"
MAX_RETRIES = 5
cfg = {}
for row in CONFIG.read_text().splitlines():
    row=row.strip()
    if not row or row.startswith("#") or "=" not in row: continue
    if row.startswith("export "):row=row[7:]
    key,value=row.split("=",1)
    cfg[key.strip()]=value.strip().strip("'").strip('"')
env=os.environ.copy()
env["API_PRIVATE_KEYS_DIR"]=cfg.get("ASC_KEY_DIR",str(Path.home()/".appstoreconnect/private_keys"))
app = Path(subprocess.check_output(["xcode-select","-p"],text=True).strip()).parents[1]
altool = app/"Contents/SharedFrameworks/ContentDelivery.framework/Versions/A/Resources/altool"
p=subprocess.run([str(altool),"--generate-jwt","--apiKey",cfg["ASC_KEY_ID"],"--apiIssuer",cfg["ASC_ISSUER_ID"]],env=env,text=True,capture_output=True,check=True)
m=re.search(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+",p.stderr+p.stdout)
if not m: raise SystemExit("JWT generation failed")
token=m.group(0)
metadata=json.loads(METADATA.read_text())["localeData"]

def request(method,path,payload=None,timeout=90):
    url = path if path.startswith("https://") else API+path
    data=None if payload is None else json.dumps(payload,ensure_ascii=False).encode("utf-8")
    for attempt in range(MAX_RETRIES):
        req=urllib.request.Request(url,method=method,data=data,headers={
            "Authorization":"Bearer "+token,
            "Content-Type":"application/json"})
        try:
            with urllib.request.urlopen(req,timeout=timeout) as response:
                raw=response.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            err=e.read().decode("utf-8","replace")
            if e.code in (429,500,502,503,504) and attempt<MAX_RETRIES-1:
                time.sleep(2**attempt);continue
            raise RuntimeError(f"{method} {path} HTTP {e.code}: {err[:1000]}") from e
        except (TimeoutError,ConnectionError,urllib.error.URLError) as e:
            if attempt < MAX_RETRIES-1:
                time.sleep(2**attempt);continue
            raise RuntimeError(f"{method} {path}: {e}") from e

def paginate(path):
    results=[]
    while path:
        data=request("GET",path)
        results.extend(data.get("data",[]))
        path=data.get("links",{}).get("next")
    return results

def write_state(**kw):
    old=json.loads(STATE.read_text()) if STATE.exists() else {}
    old.update(kw)
    STATE.parent.mkdir(parents=True,exist_ok=True)
    STATE.write_text(json.dumps(old,indent=2)+"\n")
    return old

def find_version():
    entries=paginate(f"/apps/{APP_ID}/appStoreVersions?limit=50")
    return next((x for x in entries if x["attributes"]["versionString"]==VERSION and x["attributes"]["platform"]=="IOS"),None)

def ensure_version():
    found=find_version()
    if found is None:
        found=request("POST","/appStoreVersions",{"data":{
            "type":"appStoreVersions",
            "attributes":{"platform":"IOS","versionString":VERSION,"releaseType":"AFTER_APPROVAL"},
            "relationships":{"app":{"data":{"type":"apps","id":APP_ID}}}
        }})["data"]
        print("VERSION_CREATED",found["id"],flush=True)
    else:
        print("VERSION_FOUND",found["id"],found["attributes"].get("appStoreState"),flush=True)
    write_state(version_id=found["id"])
    return found

def prepare():
    version=ensure_version()
    version_id=version["id"]
    existing={x["attributes"]["locale"]:x for x in paginate(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=50")}
    app_locales={x["attributes"]["locale"]:x for x in paginate(f"/appInfos/{APP_INFO_ID}/appInfoLocalizations?limit=50")}
    print("EXISTING_LOCALES",sorted(existing),sorted(app_locales),flush=True)
    successes=[]
    failures=[]
    for loc,meta in metadata.items():
        try:
            a={key:meta[key] for key in ("description","keywords","promotionalText","whatsNew")}
            # Apple's supportURL is version-specific; preserve correct prior public URL if present.
            if loc in existing:
                attrs=existing[loc].get("attributes",{})
                for key in ("supportUrl","marketingUrl"):
                    if attrs.get(key):a[key]=attrs[key]
                record=request("PATCH",f"/appStoreVersionLocalizations/{existing[loc]['id']}",{
                    "data":{"type":"appStoreVersionLocalizations","id":existing[loc]["id"],"attributes":a}
                })["data"]
            else:
                # Default support URL is verified official site.
                a["supportUrl"]="https://arvectum.com/"
                record=request("POST","/appStoreVersionLocalizations",{"data":{
                    "type":"appStoreVersionLocalizations",
                    "attributes":dict(locale=loc,**a),
                    "relationships":{"appStoreVersion":{"data":{"type":"appStoreVersions","id":version_id}}}
                }})["data"]
            successes.append(loc)
            print("VERSION_LOCALE_OK",loc,record["id"],flush=True)
        except Exception as e:
            failures.append((loc,"version",str(e)[:450]))
            print("VERSION_LOCALE_FAILED",loc,str(e)[:450],flush=True)
        try:
            a={"name":meta["name"],"subtitle":meta["subtitle"],"privacyPolicyUrl":meta["privacyPolicyUrl"]}
            if loc in app_locales:
                record=request("PATCH",f"/appInfoLocalizations/{app_locales[loc]['id']}",{
                    "data":{"type":"appInfoLocalizations","id":app_locales[loc]["id"],"attributes":a}
                })["data"]
            else:
                record=request("POST","/appInfoLocalizations",{"data":{
                    "type":"appInfoLocalizations",
                    "attributes":dict(locale=loc,**a),
                    "relationships":{"appInfo":{"data":{"type":"appInfos","id":APP_INFO_ID}}}
                }})["data"]
            print("APP_INFO_LOCALE_OK",loc,record["id"],flush=True)
        except Exception as e:
            failures.append((loc,"appInfo",str(e)[:450]))
            print("APP_INFO_LOCALE_FAILED",loc,str(e)[:450],flush=True)
    write_state(prepared_locales=successes,prepare_failures=failures)
    print("PREPARE_SUMMARY",len(successes),len(failures),flush=True)
    if failures:sys.exit(2)

def put_operations(file,operations):
    with file.open("rb") as handle:
        for op in operations:
            handle.seek(op["offset"])
            data=handle.read(op["length"])
            headers={h["name"]:h["value"] for h in op.get("requestHeaders",[])}
            for attempt in range(MAX_RETRIES):
                try:
                    req=urllib.request.Request(op["url"],method=op["method"],data=data,headers=headers)
                    with urllib.request.urlopen(req,timeout=180) as r:r.read()
                    break
                except urllib.error.HTTPError as e:
                    error=e.read().decode("utf-8","replace")
                    if e.code in (429,500,502,503,504) and attempt<MAX_RETRIES-1:
                        time.sleep(2**attempt);continue
                    raise RuntimeError(f"UPLOAD HTTP {e.code} {error[:350]}") from e

def upload_shot(file,shot_set_id,existing=None):
    if existing and existing.get("attributes",{}).get("assetDeliveryState",{}).get("state") == "COMPLETE":
        return existing["id"]
    attr={"fileName":file.name,"fileSize":file.stat().st_size}
    resource=request("POST","/appScreenshots",{"data":{
        "type":"appScreenshots","attributes":attr,
        "relationships":{"appScreenshotSet":{"data":{"type":"appScreenshotSets","id":shot_set_id}}}
    }})["data"]
    sid=resource["id"]
    put_operations(file,resource["attributes"].get("uploadOperations",[]))
    checksum=hashlib.md5(file.read_bytes()).hexdigest()
    request("PATCH",f"/appScreenshots/{sid}",{"data":{
        "type":"appScreenshots","id":sid,
        "attributes":{"uploaded":True,"sourceFileChecksum":checksum}
    }})
    return sid

def locale_screenshots(locale,locale_id):
    directory=SHOTS/locale/"iphone-6.9"
    files=sorted(directory.glob("*.jpg"))
    if len(files)!=4:raise RuntimeError(f"{locale}: expected 4 screenshots, found {len(files)}")
    sets=paginate(f"/appStoreVersionLocalizations/{locale_id}/appScreenshotSets?limit=50")
    shot_set=next((x for x in sets if x["attributes"].get("screenshotDisplayType")=="APP_IPHONE_67"),None)
    if shot_set is None:
        shot_set=request("POST","/appScreenshotSets",{"data":{
            "type":"appScreenshotSets","attributes":{"screenshotDisplayType":"APP_IPHONE_67"},
            "relationships":{"appStoreVersionLocalization":{
                "data":{"type":"appStoreVersionLocalizations","id":locale_id}}}
        }})["data"]
    shot_set_id=shot_set["id"]
    existing={x["attributes"].get("fileName"):x for x in paginate(f"/appScreenshotSets/{shot_set_id}/appScreenshots?limit=50")}
    ids=[]
    for file in files:
        ids.append(upload_shot(file,shot_set_id,existing.get(file.name)))
        print("SCREENSHOT",locale,file.name,flush=True)
    request("PATCH",f"/appScreenshotSets/{shot_set_id}/relationships/appScreenshots",{
        "data":[{"type":"appScreenshots","id":sid} for sid in ids]})
    return locale,shot_set_id,ids

def screenshots(workers,selection):
    version=ensure_version()
    locs={x["attributes"]["locale"]:x["id"] for x in paginate(f"/appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=50")}
    wanted=selection or list(metadata)
    absent=[loc for loc in wanted if loc not in locs]
    if absent:raise RuntimeError(f"Missing version localizations: {absent}")
    errs=[]
    completed={}
    with ThreadPoolExecutor(max_workers=workers) as pool:
        future={pool.submit(locale_screenshots,loc,locs[loc]):loc for loc in wanted}
        for task in as_completed(future):
            loc=future[task]
            try:
                _,sid,ids=task.result()
                completed[loc]={"set_id":sid,"ids":ids}
                print("LOCALE_SCREENSHOTS_COMPLETE",loc,len(ids),flush=True)
            except Exception as e:
                errs.append((loc,str(e)[:900]))
                print("LOCALE_SCREENSHOTS_FAILED",loc,str(e)[:900],flush=True)
    write_state(screenshot_locales=completed,screenshot_failures=errs)
    print("SCREENSHOTS_SUMMARY",len(completed),len(errs),flush=True)
    if errs:sys.exit(2)

def attach():
    version=ensure_version()
    builds=paginate(f"/apps/{APP_ID}/builds?limit=100")
    matched=[b for b in builds if b["attributes"].get("version")==BUILD_NUMBER and b["attributes"].get("processingState")=="VALID"]
    if not matched:
        print("BUILD_NOT_YET_VALID",[(b["attributes"].get("version"),b["attributes"].get("processingState")) for b in builds[:8]],flush=True)
        sys.exit(3)
    matched.sort(key=lambda b:b["attributes"].get("uploadedDate",""),reverse=True)
    b=matched[0]
    api_build=b["id"]
    request("PATCH",f"/appStoreVersions/{version['id']}",{"data":{
        "type":"appStoreVersions","id":version["id"],
        "relationships":{"build":{"data":{"type":"builds","id":api_build}}}
    }})
    write_state(build_id=api_build)
    print("BUILD_ATTACHED",api_build,BUILD_NUMBER,flush=True)

def review():
    version=ensure_version()
    id=version["id"]
    rel=request("GET",f"/appStoreVersions/{id}/appStoreReviewDetail")
    existing=rel.get("data")
    old_notes=ROOT/"docs/appstore/REVIEW_NOTES_TEXT_2026-09-27.txt"
    text=old_notes.read_text() if old_notes.exists() else ""
    text=("Version 1.0.0: internal refactor and stability improvements. "
          "Photo resize, PDF compression, and document-size presets are on-device. "
          "High PDF compression may rasterize pages. Ads use Yandex Mobile Ads; "
          "privacy and ad consent can be accessed on the main screen.\n\n"+text)[:4000]
    attrs={
        "contactFirstName":cfg.get("ASC_REVIEW_FIRST_NAME",""),
        "contactLastName":cfg.get("ASC_REVIEW_LAST_NAME",""),
        "contactPhone":cfg.get("ASC_REVIEW_PHONE",""),
        "contactEmail":cfg.get("ASC_REVIEW_EMAIL",""),
        "demoAccountRequired":False,
        "notes":text
    }
    if existing:
        record=request("PATCH",f"/appStoreReviewDetails/{existing['id']}",{
            "data":{"type":"appStoreReviewDetails","id":existing["id"],"attributes":attrs}
        })["data"]
    else:
        record=request("POST","/appStoreReviewDetails",{"data":{
            "type":"appStoreReviewDetails","attributes":attrs,
            "relationships":{"appStoreVersion":{"data":{"type":"appStoreVersions","id":id}}}
        }})["data"]
    write_state(review_detail_id=record["id"])
    print("REVIEW_DETAILS_READY",record["id"],flush=True)

def inspect():
    ver=find_version()
    print("VERSION",ver["id"] if ver else None,ver["attributes"].get("appStoreState") if ver else None)
    if ver:
        locs=paginate(f"/appStoreVersions/{ver['id']}/appStoreVersionLocalizations?limit=50")
        print("VERSION_LOCALES",len(locs),[x["attributes"]["locale"] for x in locs])
        for x in locs:
            sets=paginate(f"/appStoreVersionLocalizations/{x['id']}/appScreenshotSets?limit=50")
            counts=[]
            for s in sets:
                shots=paginate(f"/appScreenshotSets/{s['id']}/appScreenshots?limit=50")
                counts.append((s["attributes"]["screenshotDisplayType"],len(shots),
                               {i["attributes"].get("assetDeliveryState",{}).get("state") for i in shots}))
            print("SHOTS",x["attributes"]["locale"],counts)
    infos=paginate(f"/appInfos/{APP_INFO_ID}/appInfoLocalizations?limit=50")
    print("APP_INFO_LOCALES",len(infos),[x["attributes"]["locale"] for x in infos])
    builds=paginate(f"/apps/{APP_ID}/builds?limit=100")
    print("BUILDS",[(x["attributes"].get("version"),x["attributes"].get("processingState")) for x in builds[:7]])

def prune_version_locales():
    # Apple requires exact parity of app-level and version-level locales at review.
    # The appInfo is READY_FOR_DISTRIBUTION and Apple API rejects edits with 409;
    # retain all 20 locale drafts locally and only ship locales Apple already permits.
    version=ensure_version()
    app_info={x["attributes"]["locale"] for x in paginate(f"/appInfos/{APP_INFO_ID}/appInfoLocalizations?limit=50")}
    version_records=paginate(f"/appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=50")
    removed=[]
    for loc in version_records:
        if loc["attributes"]["locale"] not in app_info:
            request("DELETE",f"/appStoreVersionLocalizations/{loc['id']}")
            removed.append(loc["attributes"]["locale"])
            print("PRUNED_VERSION_LOCALE",loc["attributes"]["locale"],flush=True)
    write_state(deferred_locales=removed)
    print("LOCALE_PARITY_READY",sorted(app_info),"DEFERRED",len(removed),flush=True)


def submission():
    version=ensure_version()
    version_id=version["id"]
    app_info={x["attributes"]["locale"] for x in paginate(f"/appInfos/{APP_INFO_ID}/appInfoLocalizations?limit=50")}
    locs=paginate(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=50")
    locales={x["attributes"]["locale"] for x in locs}
    if locales!=app_info:
        raise RuntimeError(f"Review locale parity is not satisfied: version={sorted(locales)}, app={sorted(app_info)}")
    attached=request("GET",f"/appStoreVersions/{version_id}?include=build")
    builds=[x for x in attached.get("included",[]) if x["type"]=="builds"]
    if not builds or builds[0]["attributes"].get("version")!=BUILD_NUMBER or builds[0]["attributes"].get("processingState")!="VALID":
        raise RuntimeError("Release build 11 must be attached and VALID")
    for loc in locs:
        locale=loc["attributes"]["locale"]
        sets=paginate(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=50")
        shots=[s for s in sets if s["attributes"]["screenshotDisplayType"]=="APP_IPHONE_67"]
        if not shots:raise RuntimeError(f"Missing 6.7 screenshot set for {locale}")
        images=paginate(f"/appScreenshotSets/{shots[0]['id']}/appScreenshots?limit=50")
        if len(images)<4:raise RuntimeError(f"Missing screenshots for {locale}: {len(images)}")
        states={img["attributes"].get("assetDeliveryState",{}).get("state") for img in images}
        print("REVIEW_SCREENSHOTS",locale,len(images),states,flush=True)
        if "FAILED" in states or "COMPLETE" not in states:
            raise RuntimeError(f"Screenshot processing incomplete for {locale}: {states}")
    review()
    # Reuse an open review submission only when it is about the exact version.
    submissions=paginate(f"/apps/{APP_ID}/reviewSubmissions?limit=50")
    eligible=[]
    for candidate in submissions:
        if candidate["attributes"].get("state") not in ("READY_FOR_REVIEW","WAITING_FOR_REVIEW","UNRESOLVED_ISSUES"):
            continue
        items=paginate(f"/reviewSubmissions/{candidate['id']}/items?limit=100")
        if any((x.get("relationships",{}).get("appStoreVersion",{}).get("data") or {}).get("id")==version_id for x in items):
            eligible.append((candidate,items))
    if eligible:
        sub,items=eligible[0]
        print("REVIEW_SUBMISSION_EXISTING",sub["id"],sub["attributes"].get("state"),flush=True)
    else:
        sub=request("POST","/reviewSubmissions",{"data":{
            "type":"reviewSubmissions","attributes":{"platform":"IOS"},
            "relationships":{"app":{"data":{"type":"apps","id":APP_ID}}}
        }})["data"]
        write_state(review_submission_id=sub["id"])
        print("REVIEW_SUBMISSION_CREATED",sub["id"],flush=True)
        item=request("POST","/reviewSubmissionItems",{"data":{
            "type":"reviewSubmissionItems",
            "relationships":{
                "reviewSubmission":{"data":{"type":"reviewSubmissions","id":sub["id"]}},
                "appStoreVersion":{"data":{"type":"appStoreVersions","id":version_id}}
            }
        }})["data"]
        print("REVIEW_ITEM_CREATED",item["id"],flush=True)
    state=sub["attributes"].get("state")
    if state=="WAITING_FOR_REVIEW":
        print("ALREADY_SUBMITTED",sub["id"],flush=True);return
    response=request("PATCH",f"/reviewSubmissions/{sub['id']}",{"data":{
        "type":"reviewSubmissions","id":sub["id"],"attributes":{"submitted":True}
    }})["data"]
    print("REVIEW_SUBMITTED",sub["id"],response["attributes"].get("state"),flush=True)
    write_state(review_submitted=True)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("action",choices=["inspect","prepare","screenshots","attach","review","prune","submit"])
    parser.add_argument("--workers",type=int,default=4)
    parser.add_argument("--locales",default="")
    args=parser.parse_args()
    if args.action=="prepare":prepare()
    elif args.action=="screenshots":screenshots(args.workers,[x for x in args.locales.split(",") if x])
    elif args.action=="attach":attach()
    elif args.action=="review":review()
    elif args.action=="inspect":inspect()
    elif args.action=="prune":prune_version_locales()
    elif args.action=="submit":submission()

if __name__=="__main__":main()
