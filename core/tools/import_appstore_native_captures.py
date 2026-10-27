#!/usr/bin/env python3
"""Index actual XCTest screenshot attachments, never fabricate marketing images.

Run only on an isolated simulator after xcresulttool export attachments.
All images are drafts; there are no App Store Connect writes.
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "core/appstore/staged-2026-10-26"
APP_FOLDERS = {
    "photo": "photo-pdf-to-size", "pushkin": "pushkin",
    "what": "what", "chickmark": "chickmark"
}
POSITIONS = {
    "photo": {"fileSize": 1, "pixels": 2, "passport": 3, "pdf": 4},
    "pushkin": {"history": 1, "sources": 2, "settings": 3, "search": 4},
    "what": {"home": 1, "library": 2, "settings": 3, "text": 4},
    "chickmark": {"habits": 1, "create": 2, "progress": 3, "reminders": 4},
}
COLLAPSE_REGIONAL = {
    "en-US": "en", "en-GB": "en", "en-AU": "en", "en-CA": "en",
    "es-ES": "es", "es-MX": "es", "fr-FR": "fr", "de-DE": "de",
}
RESOLUTIONS = {
    "iphone-6.9": {(1320, 2868), (1290, 2796), (1260, 2736)},
    "ipad-13": {(2064, 2752), (2048, 2732)},
}

def dimensions(path: Path):
    result = subprocess.run(
        ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
        capture_output=True, text=True, check=True
    ).stdout
    x = re.search(r"pixelWidth:\s*(\d+)", result)
    y = re.search(r"pixelHeight:\s*(\d+)", result)
    if not x or not y:
        raise ValueError(f"Cannot read image dimensions: {path}")
    return int(x.group(1)), int(y.group(1))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--app", choices=APP_FOLDERS, required=True)
    ap.add_argument("--attachments", required=True)
    ap.add_argument("--device", choices=RESOLUTIONS, default="iphone-6.9")
    ap.add_argument("--replace-existing", action="store_true",
                    help="Replace only staged editorial images with newer verified XCTest captures")
    args = ap.parse_args()
    src = Path(args.attachments)
    manifest = json.loads((src / "manifest.json").read_text())
    stage = json.loads((STAGE / "screenshot_manifest.json").read_text())
    imported = {}
    for test in manifest:
        for attachment in test.get("attachments", []):
            name = attachment.get("suggestedHumanReadableName", "")
            # xcresulttool adds attachment sequence ID and UUID after original name.
            m = re.match(r"^aso-(photo|pushkin|what|chickmark)--([A-Za-z-]+)--([A-Za-z][A-Za-z0-9]*)_", name)
            if not m or m.group(1) != args.app:
                continue
            app, language, state = m.groups()
            position = POSITIONS[app].get(state)
            if position is None:
                continue
            source = src / attachment["exportedFileName"]
            if dimensions(source) not in RESOLUTIONS[args.device]:
                raise ValueError(f"Unexpected Apple screenshot dimensions {source}: {dimensions(source)}")
            output = (ROOT / APP_FOLDERS[app] / "store-assets" / "appstore"
                      / "editorial-20261027" / language / args.device
                      / f"{position:02d}-{state}.png")
            output.parent.mkdir(parents=True, exist_ok=True)
            if output.exists() and hashlib.sha256(output.read_bytes()).digest() != hashlib.sha256(source.read_bytes()).digest():
                if not args.replace_existing:
                    raise ValueError(f"Refusing overwrite without --replace-existing: {output}")
            shutil.copyfile(source, output)
            imported[(language, position)] = (str(output.relative_to(ROOT)), hashlib.sha256(output.read_bytes()).hexdigest())
    if not imported:
        raise ValueError(f"No attachments matched app={args.app}; check test and xcresult export")
    patched = 0
    for shot in stage["apps"][args.app]["slots"]:
        if shot["device"] != args.device:
            continue
        locale = COLLAPSE_REGIONAL.get(shot["locale"], shot["locale"])
        value = imported.get((locale, shot["position"]))
        if value:
            shot.update({
                "status": "NATIVE_SIMULATOR_DRAFT_NOT_RELEASE_SIGNED",
                "path": value[0], "sha256": value[1],
                "evidence": "isolated XCTest screenshot; localized SwiftUI, synthetic QA data",
            })
            patched += 1
    (STAGE / "screenshot_manifest.json").write_text(
        json.dumps(stage, ensure_ascii=False, indent=2) + "\n"
    )
    print(f"{args.app}/{args.device}: unique captures={len(imported)}, "
          f"regional screenshot slots indexed={patched}, "
          f"pending={sum(1 for x in stage['apps'][args.app]['slots'] if not x['path'])}")

if __name__ == "__main__":
    main()
