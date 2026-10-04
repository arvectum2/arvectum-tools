#!/usr/bin/env python3
"""Read-only Arvectum Growth Research Agent v0.

Normalizes evidence-backed opportunities into one ranked queue. It never
publishes, replies, changes store metadata, or performs other external writes.
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DEFAULT_INPUTS = [ROOT / "opportunities.json", ROOT / "photo-size-community-opportunities.json"]
PRIORITY = {"P0": 0, "P1": 1, "P2": 2, "RESEARCH": 3}


def load_items(path: Path) -> list[dict]:
    data = json.loads(path.read_text())
    return data.get("items", data.get("opportunities", []))


def normalize(item: dict, source: Path) -> dict:
    row = dict(item)
    row.setdefault("app", "photo-size")
    row.setdefault("status", "research")
    row["source_file"] = source.name
    return row


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("inputs", nargs="*", type=Path, default=DEFAULT_INPUTS)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    rows = [normalize(item, path) for path in args.inputs for item in load_items(path)]
    rows.sort(key=lambda row: (PRIORITY.get(row.get("priority", "RESEARCH"), 9), row.get("app", ""), row.get("intent", row.get("type", ""))))
    result = {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "mode": "read_only",
        "count": len(rows),
        "items": rows,
    }
    text = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(text)
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
