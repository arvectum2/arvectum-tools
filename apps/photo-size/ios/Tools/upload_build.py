#!/usr/bin/env python3
import argparse, os, re, subprocess
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
