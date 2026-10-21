#!/usr/bin/env python3
"""Android 16 emulator Photo Picker → 500 KB compression → system SaveDocument.

Uses only a generated synthetic image, production UI and production image
processing. Does NOT use the Debug engine test receiver or user gallery.
The script is run by qa_photo_picker_emulator.sh on disposable AVD.
"""
import os,sys,time,re,subprocess,json,random,struct,zlib
from pathlib import Path
from xml.etree import ElementTree as ET
o=Path(os.environ.get(
    "ARVECTUM_QA_OUTPUT_DIR",
    "/Volumes/ArvectumSSD/Arvectum/tmp/photo-picker-qa"
))
o.mkdir(parents=True,exist_ok=True)
if not str(o.resolve()).startswith("/Volumes/ArvectumSSD/"):
    raise RuntimeError("Refusing to write QA results outside ArvectumSSD")
report={"status":"running","stages":[]}
def report_uncaught(exc_type, exc, traceback):
    if report.get("status") == "running":
        report["status"] = "failed"
        report["error"] = exc_type.__name__
        report["message"] = str(exc)
        (o/"qa-photo-picker-report.json").write_text(json.dumps(report,indent=2))
    sys.__excepthook__(exc_type,exc,traceback)
sys.excepthook = report_uncaught

def stage(name):
    report["stages"].append(name)
    (o/"qa-photo-picker-report.json").write_text(json.dumps(report,indent=2))
    print("STAGE",name,flush=True)
def chunk(tag,payload):
    return (struct.pack(">I",len(payload))+tag+payload+
            struct.pack(">I",zlib.crc32(tag+payload)&0xffffffff))
def make_synthetic_png(path):
    # Deterministic artificial pixels; no personal photos.
    randomizer=random.Random(914441)
    width,height=900,700
    rows=bytearray()
    for y in range(height):
        rows.append(0)
        for x in range(width):
            rows.extend((randomizer.randrange(256), randomizer.randrange(256),
                         randomizer.randrange(256)))
    path.write_bytes(b"\x89PNG\r\n\x1a\n"+
        chunk(b"IHDR",struct.pack(">IIBBBBB",width,height,8,2,0,0,0))+
        chunk(b"IDAT",zlib.compress(rows,6))+chunk(b"IEND",b""))

adb=str(Path.home()/"Library/Android/sdk/platform-tools/adb")
def run(*args,timeout=24):
 p=subprocess.run([adb,"-s","emulator-5554",*args],capture_output=True,timeout=timeout)
 if p.returncode: raise RuntimeError((args,p.stderr.decode(errors="replace")[:800]))
 return p.stdout
def tap(x,y):
 run("shell","input","tap",str(x),str(y));print("TAP",x,y,flush=True)
def screen(name):
 p=o/name;p.write_bytes(run("exec-out","screencap","-p"))
 print("SCREEN",name,len(p.read_bytes()),flush=True)
def dump(name):
 run("shell","uiautomator","dump","/sdcard/window.xml",timeout=25)
 xml=run("exec-out","cat","/sdcard/window.xml")
 (o/(name+".xml")).write_bytes(xml)
 nodes=[]
 for el in ET.fromstring(xml).iter("node"):
  v=el.attrib;label=v.get("text") or v.get("content-desc")
  if label:
   box=[int(t) for t in re.findall(r"\d+",v.get("bounds",""))]
   nodes.append((label,box))
   print("UI",name,repr(label),box,flush=True)
 return nodes
def clicktext(items,query):
 for label,box in items:
  if label==query:
   tap((box[0]+box[2])//2,(box[1]+box[3])//2);return
 raise RuntimeError("No UI item "+query)
apk=str(Path(__file__).resolve().parents[1]/
    "app/build/outputs/apk/debug/app-debug.apk")
source=o/"qa-synthetic-900x700.png"
make_synthetic_png(source)
stage("synthetic-png-created")
run("install","-r",apk,timeout=35)
run("push",str(source),"/sdcard/Pictures/arvectum_test_qa_image.png")
run("shell","am","broadcast","-a","android.intent.action.MEDIA_SCANNER_SCAN_FILE","-d","file:///sdcard/Pictures/arvectum_test_qa_image.png")
run("shell","settings","put","system","font_scale","1")
run("shell","cmd","locale","set-app-locales","ru.arvectum.tools.tosize","--locales","en-US")
run("shell","am","start","-n","ru.arvectum.tools.tosize/.MainActivity")
time.sleep(2.0)
time.sleep(.6)
start=dump("qa-picker-start")
clicktext(start,"Choose photo")
time.sleep(3)
tiles=dump("qa-picker-gallery")
images=[(l,b) for l,b in tiles if l.startswith("Photo taken")]
if len(images)!=1:
    raise RuntimeError(f"Expected one QA gallery photo, got {len(images)}")
l,b=images[0]
tap((b[0]+b[2])//2,(b[1]+b[3])//2)
time.sleep(.5)
clicktext(dump("qa-picker-selected"),"Done")
time.sleep(1.4)
imported=dump("qa-picker-imported")
assert any("900×700 px" in l for l,b in imported), imported
stage("real-system-photo-picker-imported")
clicktext(imported,"500 KB")
time.sleep(.3)
preset=dump("qa-picker-preset")
compress=[l for l,b in preset if l.startswith("Compress to 500 KB")]
if len(compress)!=1:raise RuntimeError("500KB compression action missing")
clicktext(preset,compress[0])
stage("compression-requested")
time.sleep(2)
items=dump("qa-picker-result")
screen("qa-picker-result.png")
if not any(l=="Save" for l,b in items):
    raise RuntimeError("No save action on processed image screen")
assert any("500 KB" in l or "file size" in l.lower() for l,b in items)
stage("image-processing-result-shown")
clicktext(items,"Save")
time.sleep(2)
items=dump("qa-picker-documents")
screen("qa-picker-documents.png")
stage("system-save-document-opened")
save=[(l,b) for l,b in items if l.lower()=="save" and len(b)==4]
if not save:
    raise RuntimeError("System SaveDocument needs location selection")
l,b=save[-1]
tap((b[0]+b[2])//2,(b[1]+b[3])//2)
time.sleep(2)
screen("qa-picker-after-save.png")
stage("system-save-button-pressed")
file_list=run("shell","find","/sdcard/Download","-maxdepth","1",
    "-iname","*.jpg",timeout=25).decode(errors="replace").splitlines()
if not file_list:
    raise RuntimeError("No saved JPEG in Downloads to verify")
selected=file_list[-1]
saved=o/"qa-picker-exported.jpg"
saved.write_bytes(run("exec-out","cat",selected,timeout=30))
data=saved.read_bytes()
assert len(data)<=500_000 and data[:2]==b"\xff\xd8" and len(data)>10000,(len(data),data[:2])
stage("jpeg-verified-in-downloads")
report.update({"status":"passed","exportedBytes":len(data),
               "exportedJpeg":saved.name,"systemUri":selected})
(o/"qa-photo-picker-report.json").write_text(json.dumps(report,indent=2))
print("QA_FULL_GUI_E2E_PASS",json.dumps(report),flush=True)
