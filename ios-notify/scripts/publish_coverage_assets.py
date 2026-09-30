#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import pathlib
import shutil
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEST = ROOT / "ArvectumNotify/Resources/Coverage"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated", required=True, type=pathlib.Path)
    args = parser.parse_args()

    generated = args.generated.resolve()
    signed = generated / "signed"
    manifest_path = generated / "coverage-catalog.json"

    manifest = json.loads(manifest_path.read_text())
    apps = manifest["apps"]
    if len(apps) != 1000:
        raise SystemExit(f"expected 1000 apps, found {len(apps)}")

    base_name = manifest["basePackageFile"]
    base = signed / base_name
    if not base.exists():
        raise SystemExit(f"missing signed base: {base}")

    missing = [
        app["packageFile"]
        for app in apps
        if not (signed / app["packageFile"]).exists()
    ]
    if missing:
        raise SystemExit(
            f"missing {len(missing)} signed micro packages; "
            f"first: {missing[:5]}"
        )

    with tempfile.TemporaryDirectory(
        prefix="pushkin-coverage-publish-"
    ) as temp_dir:
        temp = pathlib.Path(temp_dir)
        micro = temp / "Micro"
        micro.mkdir()

        shutil.copy2(base, temp / base_name)
        shutil.copy2(manifest_path, temp / "coverage-catalog.json")
        for app in apps:
            shutil.copy2(
                signed / app["packageFile"],
                micro / app["packageFile"],
            )

        destination_micro = DEST / "Micro"
        if destination_micro.exists():
            shutil.rmtree(destination_micro)
        shutil.copytree(micro, destination_micro)
        shutil.copy2(
            temp / base_name,
            DEST / base_name,
        )
        shutil.copy2(
            temp / "coverage-catalog.json",
            DEST / "coverage-catalog.json",
        )

    print(
        json.dumps(
            {
                "publishedApps": len(apps),
                "microPackages": len(list((DEST / "Micro").glob("*.shortcut"))),
                "base": str(DEST / base_name),
                "manifest": str(DEST / "coverage-catalog.json"),
            }
        )
    )


if __name__ == "__main__":
    main()
