#!/usr/bin/env python3
import argparse, hashlib, json, os, re, subprocess, sys, time, urllib.request, urllib.error
from pathlib import Path

APP_ID="6816346084"
VERSION_ID="e0d324d2-1af2-441f-9f6c-5c80dba39f1b"
REVIEW_DETAIL_ID="8c6cec64-ba53-462a-95f8-75074148bcba"
REVIEW_SUBMISSION_ID="3d919ac2-4fbe-4a40-886a-c48a44276ec0"
API="https://api.appstoreconnect.apple.com"
CONFIG=Path.home()/".config/arvectum/appstore-connect.env"
ALTOOL="/Applications/Xcode-26.6.0.app/Contents/SharedFrameworks/ContentDelivery.framework/Versions/A/Resources/altool"

def die(s):
    print("ERROR:",s,file=sys.stderr); raise SystemExit(2)

def load_cfg():
    vals={}
    for raw in CONFIG.read_text().splitlines():
        line=raw.strip()
        if not line or line.startswith("#") or "=" not in line: continue
        if line.startswith("export "): line=line[7:]
        k,v=line.split("=",1); vals[k.strip()]=v.strip().strip("'").strip('"')
    return vals

def jwt():
    c=load_cfg(); env=os.environ.copy()
    env["API_PRIVATE_KEYS_DIR"]=c.get("ASC_KEY_DIR",str(Path.home()/".appstoreconnect/private_keys"))
    p=subprocess.run([ALTOOL,"--generate-jwt","--apiKey",c["ASC_KEY_ID"],"--apiIssuer",c["ASC_ISSUER_ID"]],
                     env=env,text=True,capture_output=True,check=True)
    m=re.search(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+",p.stderr+p.stdout)
    if not m: die("JWT generation failed")
    return m.group(0)

def api(tok,method,path,payload=None):
    headers={"Authorization":"Bearer "+tok}
    data=None
    if payload is not None:
        headers["Content-Type"]="application/json"
        data=json.dumps(payload).encode()
    req=urllib.request.Request(API+path,data=data,headers=headers,method=method)
    try:
        with urllib.request.urlopen(req,timeout=60) as r:
            raw=r.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"{method} {path}: HTTP {e.code}: {e.read().decode(errors='replace')}")

def validate_video(path):
    if not path.is_file(): die(f"missing video: {path}")
    p=subprocess.run(["ffprobe","-v","error","-select_streams","v:0",
        "-show_entries","stream=codec_name,width,height,r_frame_rate",
        "-show_entries","format=duration,size","-of","json",str(path)],
        text=True,capture_output=True,check=True)
    j=json.loads(p.stdout); s=(j.get("streams") or [{}])[0]; f=j.get("format",{})
    w=int(s.get("width",0)); h=int(s.get("height",0)); d=float(f.get("duration",0) or 0); z=int(f.get("size",0) or 0)
    if s.get("codec_name")!="h264": die("video must be H.264")
    if h<=w or d<20: die(f"unexpected review video {w}x{h} duration={d}")
    print("VIDEO_OK",s.get("codec_name"),f"{w}x{h}",f"{d:.2f}s",z)
    return z

def upload_attachment(tok,path):
    size=path.stat().st_size
    payload={"data":{"type":"appStoreReviewAttachments",
      "attributes":{"fileName":path.name,"fileSize":size},
      "relationships":{"appStoreReviewDetail":{"data":{"type":"appStoreReviewDetails","id":REVIEW_DETAIL_ID}}}}}
    obj=api(tok,"POST","/v1/appStoreReviewAttachments",payload)["data"]
    aid=obj["id"]; attrs=obj["attributes"]
    print("ATTACHMENT_RESERVED",aid,attrs["assetDeliveryState"]["state"])
    blob=path.read_bytes()
    for i,op in enumerate(attrs.get("uploadOperations",[]),1):
        chunk=blob[op["offset"]:op["offset"]+op["length"]]
        headers={h["name"]:h["value"] for h in op.get("requestHeaders",[])}
        headers["Content-Length"]=str(len(chunk))
        req=urllib.request.Request(op["url"],data=chunk,headers=headers,method=op["method"])
        with urllib.request.urlopen(req,timeout=300) as r:
            print("ATTACHMENT_PART",i,"HTTP",r.status)
    checksum=hashlib.md5(blob).hexdigest()
    api(tok,"PATCH",f"/v1/appStoreReviewAttachments/{aid}",{
      "data":{"type":"appStoreReviewAttachments","id":aid,
              "attributes":{"uploaded":True,"sourceFileChecksum":checksum}}})
    for n in range(60):
        x=api(tok,"GET",f"/v1/appStoreReviewAttachments/{aid}")["data"]["attributes"]
        st=x["assetDeliveryState"]["state"]; print("ATTACHMENT_POLL",n+1,st)
        if st=="COMPLETE":
            print("ATTACHMENT_COMPLETE",aid); return aid
        if st=="FAILED": die(json.dumps(x["assetDeliveryState"]))
        time.sleep(3)
    die("attachment processing timeout")

def verify_build2(tok):
    v=api(tok,"GET",f"/v1/appStoreVersions/{VERSION_ID}?include=build")
    inc=[x for x in v.get("included",[]) if x.get("type")=="builds"]
    if not inc: die("no build attached")
    b=inc[0]; a=b["attributes"]
    print("ATTACHED_BUILD",b["id"],a.get("version"),a.get("processingState"))
    if a.get("version")!="2" or a.get("processingState")!="VALID": die("build 2 not attached and VALID")

def resubmit(tok):
    verify_build2(tok)
    sub=api(tok,"GET",f"/v1/reviewSubmissions/{REVIEW_SUBMISSION_ID}")["data"]
    print("SUBMISSION_STATE",sub["attributes"].get("state"))
    if sub["attributes"].get("state")!="UNRESOLVED_ISSUES": die("submission not in UNRESOLVED_ISSUES")
    items=api(tok,"GET",f"/v1/reviewSubmissions/{REVIEW_SUBMISSION_ID}/items?include=appStoreVersion&limit=50")["data"]
    target=None
    for it in items:
        rel=(it.get("relationships") or {}).get("appStoreVersion",{}).get("data")
        if rel and rel.get("id")==VERSION_ID: target=it; break
    if not target: die("version item not found")
    iid=target["id"]; state=target["attributes"].get("state")
    print("ITEM",iid,state)
    if state=="REJECTED":
        x=api(tok,"PATCH",f"/v1/reviewSubmissionItems/{iid}",{
          "data":{"type":"reviewSubmissionItems","id":iid,"attributes":{"resolved":True}}})
        print("ITEM_RESOLVED",x["data"]["attributes"].get("state"))
    elif state!="READY_FOR_REVIEW":
        die(f"unexpected item state {state}")
    api(tok,"PATCH",f"/v1/reviewSubmissions/{REVIEW_SUBMISSION_ID}",{
      "data":{"type":"reviewSubmissions","id":REVIEW_SUBMISSION_ID,"attributes":{"submitted":True}}})
    print("REVIEW_RESUBMITTED")
    for n in range(20):
        v=api(tok,"GET",f"/v1/appStoreVersions/{VERSION_ID}")["data"]["attributes"]
        st=v.get("appStoreState") or v.get("appVersionState")
        print("VERSION_STATE",st)
        if st not in ("PREPARE_FOR_SUBMISSION","READY_FOR_REVIEW"): break
        time.sleep(3)

def main():
    ap=argparse.ArgumentParser(); ap.add_argument("video",type=Path); ap.add_argument("--submit",action="store_true")
    args=ap.parse_args(); validate_video(args.video)
    tok=jwt(); aid=upload_attachment(tok,args.video); print("ATTACHMENT_ID",aid)
    if args.submit: resubmit(tok)

if __name__=="__main__": main()
