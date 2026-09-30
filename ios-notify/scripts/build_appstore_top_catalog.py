#!/usr/bin/env python3
from __future__ import annotations

import argparse
import concurrent.futures
import csv
import datetime as dt
import json
import pathlib
import time
import urllib.parse
import urllib.request
from collections import defaultdict

DEFAULT_MARKETS = [
    "us","gb","ca","au","de","fr","it","es","nl","se","no","fi","dk","ch","pl",
    "tr","ae","sa","in","jp","sg","hk","tw","br","mx","id","th","vn","ph","my",
    "za","ru","kz","ua"
]

MARKET_WEIGHTS = defaultdict(lambda: 1.0, {
    "ru": 2.2,
    "kz": 1.5,
    "ua": 1.3,
    "gb": 1.2,
    "us": 1.2,
})

CORE_SYSTEM_APPS = [
    {"name":"Messages","bundleIdentifier":"com.apple.MobileSMS","teamIdentifier":"0000000000"},
    {"name":"Mail","bundleIdentifier":"com.apple.mobilemail","teamIdentifier":"0000000000"},
    {"name":"Calendar","bundleIdentifier":"com.apple.mobilecal","teamIdentifier":"0000000000"},
    {"name":"Reminders","bundleIdentifier":"com.apple.reminders","teamIdentifier":"0000000000"},
    {"name":"Wallet","bundleIdentifier":"com.apple.Passbook","teamIdentifier":"0000000000"},
    {"name":"FaceTime","bundleIdentifier":"com.apple.facetime","teamIdentifier":"0000000000"},
]

def request_json(url: str, timeout: int = 25, retries: int = 3) -> dict:
    last = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(
                url,
                headers={"User-Agent":"Mozilla/5.0 PUSHKIN-AppStore-Catalog/1.0"},
            )
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.load(r)
        except Exception as e:
            last = e
            if attempt + 1 < retries:
                time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"{url}: {last}")

def fetch_chart(market: str, cache_dir: pathlib.Path) -> list[dict]:
    cache = cache_dir / f"{market}-top-free-100.json"
    if cache.exists():
        return json.loads(cache.read_text())["feed"]["results"]
    url = f"https://rss.marketingtools.apple.com/api/v2/{market}/apps/top-free/100/apps.json"
    data = request_json(url)
    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_text(json.dumps(data, ensure_ascii=False))
    return data["feed"]["results"]

def chunks(seq, n):
    for i in range(0, len(seq), n):
        yield seq[i:i+n]

def lookup_ids(ids: list[str], market: str, cache_dir: pathlib.Path) -> list[dict]:
    out = []
    cache_dir.mkdir(parents=True, exist_ok=True)
    for batch in chunks(ids, 50):
        key = "-".join(batch)
        cache = cache_dir / f"{market}-{abs(hash(key))}.json"
        if cache.exists():
            data = json.loads(cache.read_text())
        else:
            url = "https://itunes.apple.com/lookup?id=" + ",".join(batch) + "&country=" + market
            data = request_json(url)
            cache.write_text(json.dumps(data, ensure_ascii=False))
            time.sleep(0.15)
        out.extend(data.get("results", []))
    return out

def lookup_bundle(bundle_id: str, markets: list[str]) -> dict | None:
    query = urllib.parse.urlencode({"bundleId": bundle_id, "country": markets[0]})
    for market in markets:
        try:
            query = urllib.parse.urlencode({"bundleId": bundle_id, "country": market})
            data = request_json("https://itunes.apple.com/lookup?" + query, retries=2)
            if data.get("results"):
                return data["results"][0]
        except Exception:
            pass
    return None

def load_known_team_by_bundle(path: pathlib.Path) -> dict[str,str]:
    if not path.exists():
        return {}
    doc = json.loads(path.read_text())
    return {
        a["bundleIdentifier"]: a.get("teamIdentifier","")
        for a in doc.get("apps",[])
        if a.get("bundleIdentifier") and a.get("teamIdentifier")
    }

def build_known_artist_team(known: dict[str,str]) -> dict[int,str]:
    mapping: dict[int,str] = {}
    fallback = ["us","gb","jp","ru","de","fr"]
    for i,(bundle,team) in enumerate(known.items(),1):
        row = lookup_bundle(bundle, fallback)
        artist = row.get("artistId") if row else None
        if artist:
            mapping[int(artist)] = team
        if i % 10 == 0:
            print(f"known-team enrichment {i}/{len(known)}", flush=True)
    return mapping

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", required=True, type=pathlib.Path)
    ap.add_argument("--known", type=pathlib.Path, required=True)
    ap.add_argument("--cache", type=pathlib.Path, default=pathlib.Path("/tmp/pushkin-appstore-cache"))
    ap.add_argument("--limit", type=int, default=1000)
    args = ap.parse_args()

    cache = args.cache
    chart_cache = cache / "charts"
    lookup_cache = cache / "lookup"
    markets = DEFAULT_MARKETS

    charts: dict[str,list[dict]] = {}
    failures = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
        futs = {ex.submit(fetch_chart,m,chart_cache):m for m in markets}
        for fut in concurrent.futures.as_completed(futs):
            market = futs[fut]
            try:
                charts[market] = fut.result()
                print(f"chart {market}: {len(charts[market])}", flush=True)
            except Exception as e:
                failures[market] = str(e)
                print(f"chart {market}: FAILED {e}", flush=True)

    appearances = defaultdict(list)
    seed = {}
    for market, rows in charts.items():
        for rank, row in enumerate(rows,1):
            app_id = str(row["id"])
            appearances[app_id].append((market,rank))
            seed.setdefault(app_id,{
                "adamId": app_id,
                "chartName": row["name"],
                "artistName": row.get("artistName",""),
                "firstMarket": market,
            })

    def score(app_id: str):
        apps = appearances[app_id]
        weighted = sum(MARKET_WEIGHTS[m] * (101-r) for m,r in apps)
        breadth = sum(MARKET_WEIGHTS[m] for m,r in apps)
        best = min(r for m,r in apps)
        return (breadth, weighted, -best)

    candidate_ids = sorted(appearances, key=score, reverse=True)
    # Look up more than needed because a few storefront records can fail lookup.
    candidate_ids = candidate_ids[: min(len(candidate_ids), args.limit + 500)]

    by_market = defaultdict(list)
    for app_id in candidate_ids:
        preferred = appearances[app_id][0][0]
        by_market[preferred].append(app_id)

    metadata: dict[str,dict] = {}
    for market, ids in by_market.items():
        try:
            for row in lookup_ids(ids,market,lookup_cache):
                if row.get("wrapperType") == "software" and row.get("trackId"):
                    metadata[str(row["trackId"])] = row
            print(f"lookup {market}: {len(ids)} requested", flush=True)
        except Exception as e:
            print(f"lookup {market} FAILED: {e}", flush=True)

    known_bundle_team = load_known_team_by_bundle(args.known)
    artist_team = build_known_artist_team(known_bundle_team)

    ranked = []
    seen_bundles = set()
    for app_id in candidate_ids:
        row = metadata.get(app_id)
        if not row:
            continue
        bundle = row.get("bundleId")
        if not bundle or bundle in seen_bundles:
            continue
        seen_bundles.add(bundle)
        team = known_bundle_team.get(bundle,"")
        artist_id = row.get("artistId")
        if not team and artist_id:
            team = artist_team.get(int(artist_id),"")
        apps = appearances[app_id]
        ranked.append({
            "name": row.get("trackName") or seed[app_id]["chartName"],
            "bundleIdentifier": bundle,
            "teamIdentifier": team,
            "adamId": int(app_id),
            "artistId": int(artist_id) if artist_id else None,
            "artistName": row.get("artistName") or row.get("sellerName") or seed[app_id]["artistName"],
            "primaryGenre": row.get("primaryGenreName",""),
            "marketCount": len(apps),
            "markets": [m for m,_ in sorted(apps,key=lambda x:x[1])],
            "bestChartRank": min(r for _,r in apps),
            "coverageScore": round(sum(MARKET_WEIGHTS[m]*(101-r) for m,r in apps),3),
            "source": "app-store-top-free",
        })
        if len(ranked) >= args.limit:
            break

    # Reserve core system apps even though they are not downloadable chart entries.
    core = []
    ranked_bundles = {x["bundleIdentifier"] for x in ranked}
    for app in CORE_SYSTEM_APPS:
        if app["bundleIdentifier"] not in ranked_bundles:
            core.append({
                **app,
                "adamId": None,
                "artistId": None,
                "artistName": "Apple",
                "primaryGenre": "System",
                "marketCount": 0,
                "markets": [],
                "bestChartRank": None,
                "coverageScore": 10_000.0,
                "source": "core-system",
            })

    final = (core + ranked)[: args.limit]
    for i,a in enumerate(final,1):
        a["rank"] = i

    doc = {
        "catalogVersion": 5,
        "generatedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
        "method": "Official Apple top-free-100 charts aggregated across storefronts; ranked by weighted cross-market breadth and chart position. Core Apple notification apps are reserved.",
        "marketsRequested": markets,
        "marketsSucceeded": sorted(charts),
        "marketsFailed": failures,
        "appCount": len(final),
        "knownTeamIdentifierCount": sum(bool(x.get("teamIdentifier")) for x in final),
        "apps": final,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n")

    csv_path = args.output.with_suffix(".csv")
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["rank","name","bundleIdentifier","teamIdentifier","artistName","marketCount","bestChartRank","coverageScore","markets","source"])
        for a in final:
            w.writerow([a["rank"],a["name"],a["bundleIdentifier"],a.get("teamIdentifier",""),a["artistName"],a["marketCount"],a["bestChartRank"],a["coverageScore"],",".join(a["markets"]),a["source"]])

    print(json.dumps({
        "final":len(final),
        "uniqueChartCandidates":len(appearances),
        "marketsSucceeded":len(charts),
        "teamIdentifiersKnown":sum(bool(x.get("teamIdentifier")) for x in final),
        "output":str(args.output),
    }, ensure_ascii=False))

if __name__ == "__main__":
    main()
