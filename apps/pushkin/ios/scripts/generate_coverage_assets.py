#!/usr/bin/env python3
"""Generate PUSHKIN base catalog + per-app micro refresh shortcuts.

Input manifest schema:
{
  "catalogVersion": 1,
  "apps": [
    {
      "name": "...",
      "bundleIdentifier": "...",
      "teamIdentifier": "..." // optional; Shortcuts accepts Bundle ID + Name
    }
  ]
}

The shortcut name stays stable across catalog releases so iOS can offer Replace.
The WFTriggerUUID changes with catalogVersion so a new release forces a fresh
trigger identity when the signed package is re-imported.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import copy
import json
import pathlib
import plistlib
import re
import subprocess
import uuid

NAMESPACE = uuid.UUID("9a8cc838-e146-4ccb-95c5-49495fa90792")


def safe_slug(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9._-]+", "-", value)
    return value.strip("-") or "app"


def visible_filename(name: str, bundle_identifier: str, used: set[str]) -> str:
    component = re.sub(r"[/:\\\\]+", "-", name).strip().strip(".")
    component = re.sub(r"\\s+", " ", component) or "App"
    stem = f"PUSHKIN - {component}"
    key = stem.casefold()
    if key in used:
        stem = f"{stem} - {safe_slug(bundle_identifier)[-12:]}"
        key = stem.casefold()
    used.add(key)
    return f"{stem}.shortcut"


def load_manifest(path: pathlib.Path) -> dict:
    data = json.loads(path.read_text())
    apps = data.get("apps")
    if not isinstance(apps, list) or not apps:
        raise SystemExit("manifest must contain a non-empty apps array")

    seen = set()
    for app in apps:
        for key in ("name", "bundleIdentifier"):
            if not app.get(key):
                raise SystemExit(f"missing {key}: {app!r}")
        bundle = app["bundleIdentifier"]
        if bundle in seen:
            raise SystemExit(f"duplicate bundleIdentifier: {bundle}")
        seen.add(bundle)
    return data


def app_descriptor(app: dict) -> dict:
    result = {
        "BundleIdentifier": app["bundleIdentifier"],
        "Name": app["name"],
    }
    team_identifier = app.get("teamIdentifier")
    if team_identifier:
        result["TeamIdentifier"] = team_identifier
    return result


def render(template: dict, apps: list[dict], workflow_name: str, trigger_uuid: str) -> dict:
    result = copy.deepcopy(template)
    triggers = result.get("WFWorkflowTriggers")
    if not isinstance(triggers, list) or not triggers:
        raise SystemExit("template has no WFWorkflowTriggers")

    result["WFWorkflowName"] = workflow_name
    trigger = triggers[0]
    trigger["WFTriggerUUID"] = trigger_uuid
    params = trigger.setdefault("WFTriggerSerializedParameters", {})
    params["SelectedApps"] = [app_descriptor(app) for app in apps]
    return result


def write_shortcut(payload: dict, output: pathlib.Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(plistlib.dumps(payload, fmt=plistlib.FMT_BINARY))


def sign(
    input_path: pathlib.Path,
    output_path: pathlib.Path,
    retries: int = 5,
) -> None:
    if output_path.exists() and output_path.stat().st_size > 1024:
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    last_error: subprocess.CalledProcessError | None = None

    for attempt in range(1, retries + 1):
        try:
            subprocess.run(
                [
                    "shortcuts", "sign",
                    "--mode", "anyone",
                    "--input", str(input_path),
                    "--output", str(output_path),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                text=True,
            )
            return
        except subprocess.CalledProcessError as exc:
            last_error = exc
            output_path.unlink(missing_ok=True)
            if attempt < retries:
                import time
                time.sleep(min(2 ** attempt, 20))

    assert last_error is not None
    stderr = (last_error.stderr or "").strip()
    raise RuntimeError(
        f"failed to sign {input_path.name} after {retries} attempts: {stderr}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True, type=pathlib.Path)
    parser.add_argument("--template", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--sign", action="store_true")
    parser.add_argument("--sign-limit", type=int, default=None)
    parser.add_argument("--sign-workers", type=int, default=8)
    args = parser.parse_args()

    manifest = load_manifest(args.manifest)
    version = int(manifest.get("catalogVersion", manifest.get("version", 1)))
    apps = manifest["apps"]
    template = plistlib.loads(args.template.read_bytes())
    # The exported research template may itself carry a large SelectedApps
    # fixture. Strip it once before cloning so generating 1000 one-app
    # packages does not deep-copy the old catalog 1000 times.
    template_triggers = template.get("WFWorkflowTriggers") or []
    if template_triggers:
        template_triggers[0].setdefault(
            "WFTriggerSerializedParameters", {}
        )["SelectedApps"] = []

    unsigned_dir = args.output / "unsigned"
    signed_dir = args.output / "signed"
    unsigned_dir.mkdir(parents=True, exist_ok=True)
    signed_dir.mkdir(parents=True, exist_ok=True)

    base_uuid = str(uuid.uuid5(NAMESPACE, f"base:{version}")).upper()
    base_filename = "PUSHKIN - Base.shortcut"
    base_payload = render(template, apps, "PUSHKIN - Base", base_uuid)
    base_unsigned = unsigned_dir / base_filename
    write_shortcut(base_payload, base_unsigned)

    output_entries = []
    sign_jobs: list[tuple[pathlib.Path, pathlib.Path]] = []
    used_filenames: set[str] = set()

    if args.sign:
        sign_jobs.append((base_unsigned, signed_dir / base_filename))

    for index, app in enumerate(apps, start=1):
        bundle = app["bundleIdentifier"]
        shortcut_name = f"PUSHKIN - {app['name']}"
        filename = visible_filename(
            app["name"],
            bundle,
            used_filenames,
        )
        trigger_uuid = str(
            uuid.uuid5(NAMESPACE, f"micro:{version}:{bundle}")
        ).upper()

        payload = render(template, [app], shortcut_name, trigger_uuid)
        unsigned = unsigned_dir / filename
        write_shortcut(payload, unsigned)

        if args.sign:
            sign_jobs.append((unsigned, signed_dir / filename))

        output_entries.append(
            {
                **app,
                "shortcutName": shortcut_name,
                "packageFile": filename,
                "rank": index,
            }
        )

    sign_count = 0
    if args.sign:
        jobs = sign_jobs
        if args.sign_limit is not None:
            jobs = jobs[: max(0, args.sign_limit)]

        workers = max(1, min(args.sign_workers, len(jobs) or 1))
        with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
            future_map = {
                executor.submit(sign, input_path, output_path): output_path
                for input_path, output_path in jobs
            }
            for future in concurrent.futures.as_completed(future_map):
                output_path = future_map[future]
                future.result()
                sign_count += 1
                if sign_count % 50 == 0 or sign_count == len(jobs):
                    print(
                        f"signed {sign_count}/{len(jobs)}: {output_path.name}",
                        flush=True,
                    )

    runtime_manifest = {
        "catalogVersion": version,
        "basePackageFile": base_filename,
        "apps": output_entries,
    }
    (args.output / "coverage-catalog.json").write_text(
        json.dumps(runtime_manifest, ensure_ascii=False, indent=2) + "\n"
    )

    print(
        json.dumps(
            {
                "catalogVersion": version,
                "apps": len(apps),
                "unsignedMicroPacks": len(apps),
                "signedArtifacts": sign_count,
                "output": str(args.output),
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
