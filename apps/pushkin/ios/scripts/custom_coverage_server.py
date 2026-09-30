#!/usr/bin/env python3
"""Sign one-app PUSHKIN coverage packages for apps outside the bundled catalog."""
from __future__ import annotations

import argparse
import hashlib
import pathlib
import plistlib
import re
import subprocess
import tempfile
import threading
import urllib.parse
import uuid
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

NAMESPACE = uuid.UUID("9a8cc838-e146-4ccb-95c5-49495fa90792")
FORMAT_VERSION = 1
BUNDLE_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{2,254}$")
_LOCKS: dict[str, threading.Lock] = {}
_LOCKS_GUARD = threading.Lock()


def app_lock(bundle: str) -> threading.Lock:
    with _LOCKS_GUARD:
        return _LOCKS.setdefault(bundle, threading.Lock())


def clean_name(value: str) -> str:
    value = " ".join(value.strip().split())
    return value.replace("/", "-").replace("\\", "-").replace(":", "-")[:120]


class Signer:
    def __init__(self, template: pathlib.Path, cache: pathlib.Path):
        self.template = plistlib.loads(template.read_bytes())
        self.cache = cache
        cache.mkdir(parents=True, exist_ok=True)

    def output_path(self, bundle: str) -> pathlib.Path:
        digest = hashlib.sha256(
            f"{FORMAT_VERSION}:{bundle}".encode()
        ).hexdigest()[:16]
        return self.cache / f"PUSHKIN-Custom-{digest}.shortcut"

    def build(self, name: str, bundle: str) -> pathlib.Path:
        output = self.output_path(bundle)
        if output.exists() and output.stat().st_size > 1024:
            return output
        with app_lock(bundle):
            if output.exists() and output.stat().st_size > 1024:
                return output
            payload = self._render(name, bundle)

            with tempfile.TemporaryDirectory(prefix="pushkin-custom-") as td:
                unsigned = pathlib.Path(td) / "custom.shortcut"
                unsigned.write_bytes(
                    plistlib.dumps(payload, fmt=plistlib.FMT_BINARY)
                )
                subprocess.run(
                    ["shortcuts", "sign", "--mode", "anyone",
                     "--input", str(unsigned), "--output", str(output)],
                    check=True, timeout=45,
                    stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                )
            return output

    def _render(self, name: str, bundle: str) -> dict:
        import copy
        payload = copy.deepcopy(self.template)
        payload["WFWorkflowName"] = f"PUSHKIN - {clean_name(name)}"
        trigger = payload["WFWorkflowTriggers"][0]
        trigger["WFTriggerUUID"] = str(uuid.uuid5(
            NAMESPACE, f"custom:{FORMAT_VERSION}:{bundle}"
        )).upper()
        trigger.setdefault("WFTriggerSerializedParameters", {})[
            "SelectedApps"
        ] = [{"BundleIdentifier": bundle, "Name": name}]
        return payload


class Handler(BaseHTTPRequestHandler):
    signer: Signer

    def do_GET(self) -> None:
        url = urllib.parse.urlparse(self.path)
        if url.path == "/health":
            self._json(HTTPStatus.OK, b'{"ok":true}\n')
            return
        if url.path != "/v1/coverage/shortcut":
            self._json(HTTPStatus.NOT_FOUND, b'{"error":"not_found"}\n')
            return
        query = urllib.parse.parse_qs(url.query)
        bundle = (query.get("bundleIdentifier") or [""])[0].strip()
        name = clean_name((query.get("name") or [""])[0])
        if not BUNDLE_RE.fullmatch(bundle) or not name:
            self._json(HTTPStatus.BAD_REQUEST, b'{"error":"invalid_app"}\n')
            return
        try:
            data = self.signer.build(name, bundle).read_bytes()
        except Exception as exc:
            print(repr(exc), flush=True)
            self._json(HTTPStatus.BAD_GATEWAY, b'{"error":"sign_failed"}\n')
            return
        self.send_response(HTTPStatus.OK)

        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "public, max-age=31536000")
        self.end_headers()
        self.wfile.write(data)

    def _json(self, status: int, data: bytes) -> None:
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main() -> None:
    here = pathlib.Path(__file__).resolve().parent
    parser = argparse.ArgumentParser()
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8766)
    parser.add_argument("--template", type=pathlib.Path,
                        default=here / "templates" / "pushkin-notification-template.shortcut")
    parser.add_argument("--cache", type=pathlib.Path,
                        default=pathlib.Path("/tmp/pushkin-custom-coverage-cache"))

    args = parser.parse_args()
    Handler.signer = Signer(args.template, args.cache)
    server = ThreadingHTTPServer((args.bind, args.port), Handler)
    print(f"PUSHKIN custom signer: http://{args.bind}:{args.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
