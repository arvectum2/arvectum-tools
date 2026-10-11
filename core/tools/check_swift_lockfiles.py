#!/usr/bin/env python3
"""Check exact direct SwiftPM SDK revisions match the shared Core catalog."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
catalog = json.loads((ROOT / "core/dependencies/catalog.json").read_text())["swiftPackages"]
locks = [
    "chickmark/ios/Package.resolved",
    "chickmark/ios/HabitsByArvectumIOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
    "photo-pdf-to-size/ios/PhotoPodRazmerIOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
]
for lock in locks:
    path = ROOT / lock
    pins = json.loads(path.read_text())["pins"]
    for name, cfg in catalog.items():
        pkg = cfg["url"].rstrip("/").split("/")[-1].lower()
        matching = [p for p in pins if p["identity"].lower() == pkg]
        if len(matching) != 1 or matching[0]["state"].get("version") != cfg["version"]:
            raise SystemExit(f"OUT OF SYNC: {lock} {name} != {cfg['version']}")
print("All SwiftPM locks match the shared Core SDK catalog")
