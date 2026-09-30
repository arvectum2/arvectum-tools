#!/usr/bin/env python3
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP_ID = "6816346084"
VERSION = "0.4.2"
LOCALE = "ru"
SCREENSHOT_TYPE = "APP_IPHONE_65"
SHOT_DIR = ROOT / "store-assets" / "appstore" / "iphone-6.5"
CONFIG = Path.home() / ".config" / "arvectum" / "appstore-connect.env"
ALTOOL = Path("/Applications/Xcode-26.6.0.app/Contents/SharedFrameworks/ContentDelivery.framework/Versions/A/Resources/altool")
API = "https://api.appstoreconnect.apple.com/v1"

def load_config():
    values = {}
    for raw in CONFIG.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:]
        if "=" not in line:
            continue
        k, v = line.split("=", 1)
        values[k.strip()] = v.strip().strip("'").strip('"')
    return values

CFG = load_config()
KEY_ID = CFG["ASC_KEY_ID"]
ISSUER_ID = CFG["ASC_ISSUER_ID"]
KEY_DIR = Path(CFG.get("ASC_KEY_DIR", str(Path.home() / ".appstoreconnect" / "private_keys"))).expanduser()

def jwt():
    env = os.environ.copy()
    env["API_PRIVATE_KEYS_DIR"] = str(KEY_DIR)
    p = subprocess.run(
        [str(ALTOOL), "--generate-jwt", "--apiKey", KEY_ID, "--apiIssuer", ISSUER_ID],
        env=env, text=True, capture_output=True, check=True,
    )
    m = re.search(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+", p.stderr)
    if not m:
        raise RuntimeError("Could not generate App Store Connect JWT")
    return m.group(0)

TOKEN = jwt()

def api(method, path, payload=None):
    data = None if payload is None else json.dumps(payload, ensure_ascii=False).encode()
    req = urllib.request.Request(
        API + path,
        data=data,
        method=method,
        headers={
            "Authorization": "Bearer " + TOKEN,
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        raise RuntimeError(f"{method} {path} -> HTTP {e.code}: {body}") from e

versions = api("GET", f"/apps/{APP_ID}/appStoreVersions?limit=20")["data"]
version = next(
    x for x in versions
    if x["attributes"].get("platform") == "IOS"
    and x["attributes"].get("versionString") == VERSION
)
version_id = version["id"]

locs = api("GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=20")["data"]
loc = next(x for x in locs if x["attributes"].get("locale") == LOCALE)
loc_id = loc["id"]

builds = api("GET", f"/apps/{APP_ID}/builds?limit=20")["data"]
valid_builds = [x for x in builds if x["attributes"].get("processingState") == "VALID"]
if not valid_builds:
    raise RuntimeError("No VALID build is available yet")
build = sorted(valid_builds, key=lambda x: x["attributes"].get("uploadedDate", ""))[-1]
build_id = build["id"]

api("PATCH", f"/appStoreVersions/{version_id}", {
    "data": {
        "type": "appStoreVersions",
        "id": version_id,
        "relationships": {
            "build": {"data": {"type": "builds", "id": build_id}}
        },
    }
})
print("BUILD_ATTACHED", build_id, build["attributes"].get("version"))

sets = api("GET", f"/appStoreVersionLocalizations/{loc_id}/appScreenshotSets?limit=50")["data"]
shot_set = next((x for x in sets if x["attributes"].get("screenshotDisplayType") == SCREENSHOT_TYPE), None)
if shot_set is None:
    shot_set = api("POST", "/appScreenshotSets", {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": SCREENSHOT_TYPE},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": loc_id}
                }
            },
        }
    })["data"]
shot_set_id = shot_set["id"]

existing = api("GET", f"/appScreenshotSets/{shot_set_id}/appScreenshots?limit=50")["data"]
for screenshot in existing:
    api("DELETE", f"/appScreenshots/{screenshot['id']}")
if existing:
    print("DELETED_OLD_SCREENSHOTS", len(existing))

def upload_binary(operation, file_path):
    offset = operation["offset"]
    length = operation["length"]
    with open(file_path, "rb") as f:
        f.seek(offset)
        chunk = f.read(length)
    headers = {h["name"]: h["value"] for h in operation.get("requestHeaders", [])}
    req = urllib.request.Request(
        operation["url"], data=chunk, method=operation["method"], headers=headers
    )
    with urllib.request.urlopen(req, timeout=120) as r:
        r.read()

created_ids = []
for path in sorted(SHOT_DIR.glob("*.png")):
    size = path.stat().st_size
    resource = api("POST", "/appScreenshots", {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": path.name, "fileSize": size},
            "relationships": {
                "appScreenshotSet": {
                    "data": {"type": "appScreenshotSets", "id": shot_set_id}
                }
            },
        }
    })["data"]
    screenshot_id = resource["id"]
    for operation in resource["attributes"].get("uploadOperations", []):
        upload_binary(operation, path)
    checksum = hashlib.md5(path.read_bytes()).hexdigest()
    api("PATCH", f"/appScreenshots/{screenshot_id}", {
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {
                "uploaded": True,
                "sourceFileChecksum": checksum,
            },
        }
    })
    created_ids.append(screenshot_id)
    print("SCREENSHOT_UPLOADED", path.name, screenshot_id)

api("PATCH", f"/appScreenshotSets/{shot_set_id}/relationships/appScreenshots", {
    "data": [{"type": "appScreenshots", "id": x} for x in created_ids]
})
print("SCREENSHOT_SET", shot_set_id, SCREENSHOT_TYPE, len(created_ids))
print("DONE")
