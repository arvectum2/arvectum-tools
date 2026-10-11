#!/usr/bin/env python3
import argparse, os, plistlib, re, subprocess, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CFG = Path.home() / ".config" / "arvectum" / "appstore-connect.env"

parser = argparse.ArgumentParser()
parser.add_argument("--ipa", type=Path, help="IPA to upload; defaults to the newest exported IPA")
args = parser.parse_args()

if args.ipa:
    IPA = args.ipa.expanduser().resolve()
else:
    candidates = sorted(
        (ROOT / "ios" / "build").glob("export-*/PhotoPodRazmer.ipa"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    if not candidates:
        raise SystemExit("No exported PhotoPodRazmer.ipa found; pass --ipa explicitly")
    IPA = candidates[0]

if not IPA.is_file():
    raise SystemExit(f"IPA not found: {IPA}")

with zipfile.ZipFile(IPA) as archive:
    info_paths = [
        name for name in archive.namelist()
        if name.startswith("Payload/")
        and name.endswith(".app/Info.plist")
        and name.count("/") == 2
    ]
    if len(info_paths) != 1:
        raise SystemExit(f"Expected one top-level app Info.plist, found {len(info_paths)}")
    info = plistlib.loads(archive.read(info_paths[0]))

version = str(info.get("CFBundleShortVersionString", "")).strip()
build = str(info.get("CFBundleVersion", "")).strip()
if not version or not build:
    raise SystemExit("Could not read version/build from IPA")

status_script = Path(__file__).with_name("appstore_status.sh")
status = subprocess.run(
    [str(status_script)],
    text=True,
    capture_output=True,
    check=True,
).stdout
for line in status.splitlines():
    fields = line.split()
    if len(fields) < 3 or fields[0] == "VERSION":
        continue
    existing_build = fields[1]
    marketing = None
    for index, field in enumerate(fields):
        if field == "marketing=" and index + 1 < len(fields):
            marketing = fields[index + 1]
            break
        if field.startswith("marketing=") and field != "marketing=":
            marketing = field.split("=", 1)[1]
            break
    if existing_build == build and marketing == version:
        raise SystemExit(
            f"Refusing redundant upload: {version} ({build}) already exists in App Store Connect"
        )

cfg={}
for raw in CFG.read_text().splitlines():
    line=raw.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    if line.startswith("export "):
        line=line[7:]
    k,v=line.split("=",1)
    cfg[k.strip()]=v.strip().strip("'").strip('"')

developer_dir = Path(subprocess.check_output(["xcode-select","-p"], text=True).strip())
xcode_app = developer_dir.parents[1]
altool = xcode_app / "Contents/SharedFrameworks/ContentDelivery.framework/Versions/A/Resources/altool"

env=os.environ.copy()
env["API_PRIVATE_KEYS_DIR"]=cfg.get("ASC_KEY_DIR", str(Path.home()/".appstoreconnect/private_keys"))

subprocess.run([
    str(altool), "--upload-app", "-f", str(IPA),
    "--apiKey", cfg["ASC_KEY_ID"],
    "--apiIssuer", cfg["ASC_ISSUER_ID"],
], env=env, check=True)
print("UPLOAD_SUCCEEDED", IPA)
