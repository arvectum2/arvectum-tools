#!/usr/bin/env python3
"""Validate draft App Store metadata; never talks to App Store Connect."""
import json, re, sys, unicodedata
from pathlib import Path

path = Path(__file__).with_name("metadata-2026-10-10.json")
data = json.loads(path.read_text(encoding="utf-8"))
errors = []
trimmed = []
for locale, a in data["localeData"].items():
    for field, limit in (("name", 30), ("subtitle", 30), ("promotionalText", 170), ("description", 4000)):
        value = a[field]
        if not value.strip() or len(value) > limit:
            errors.append(f"{locale} {field}: {len(value)} chars (max {limit})")
    terms = [t.strip() for t in a["keywords"].split(",")]
    if any(not t or " " in t.strip(" ") and t.strip() != t for t in terms):
        errors.append(f"{locale}: malformed keywords")
    if len(terms) != len(set(t.casefold() for t in terms)):
        errors.append(f"{locale}: duplicate keywords")
    if "--normalise" in sys.argv:
        while len(",".join(terms).encode("utf-8")) > 100 and terms:
            dropped = terms.pop()
            trimmed.append((locale, dropped))
        a["keywords"] = ",".join(terms)
    if len(a["keywords"].encode("utf-8")) > 100:
        errors.append(f"{locale}: keywords {len(a['keywords'].encode('utf-8'))} bytes (max 100)")
    if len(a["screenshots"]) != 3 or any(not s.strip() for s in a["screenshots"]):
        errors.append(f"{locale}: expected 3 screenshot headings")
    if a.get("privacyPolicyUrl") != "https://arvectum.com/photo-pod-razmer-privacy.html":
        errors.append(f"{locale}: invalid privacy link")
    print(f"{locale:6s} name={len(a['name']):2d} subtitle={len(a['subtitle']):2d} keywords={len(a['keywords'].encode('utf-8')):3d}B promo={len(a['promotionalText']):3d} desc={len(a['description']):4d}")
if "--normalise" in sys.argv:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print("Truncated trailing keywords:",trimmed)
print("Localizations:",len(data["localeData"]))
if errors:
    print("ERRORS:",*errors,sep="\n - ",file=sys.stderr)
    sys.exit(1)
print("VALID")