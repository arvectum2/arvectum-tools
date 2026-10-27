#!/usr/bin/env python3
"""Offline release gate: never confuses screenshot presence with launch approval."""
import argparse
import json
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
P=ROOT/"core/appstore/staged-2026-10-26/editorial/c14-release-gate.json"
def check():
 d=json.loads(P.read_text())
 assert d["stage"]=="DRAFT_NOT_UPLOADED", "Do not mutate staged assets to claim live release"
 assert d["assetCoverage"]=={"metadata":"64/64","screenshotSlots":"448/448","uniqueImages":336}
 missing=[]
 for label,item in d["requiredBeforeAppStoreMutation"].items():
  if not item["approved"] or not item["evidence"]:
   missing.append(label)
 return missing
if __name__=="__main__":
 ap=argparse.ArgumentParser()
 ap.add_argument("--for-release",action="store_true")
 a=ap.parse_args()
 missing=check()
 print(f"ASO assets: staged; release gates {len(missing)} pending")
 for k in missing:print(" -",k)
 if a.for_release and missing:
  print("BLOCKED: missing verified approvals; no ASC changes permitted",file=sys.stderr)
  raise SystemExit(2)
 print("DRAFT VALID (no publication authorization)" if missing else "Evidence checks passed; requires human release action")
