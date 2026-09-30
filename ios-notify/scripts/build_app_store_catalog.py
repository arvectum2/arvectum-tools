#!/usr/bin/env python3
from __future__ import annotations
import argparse, concurrent.futures, json, pathlib, subprocess, time
import urllib.parse, urllib.request
from collections import defaultdict

MARKETS = "us gb ca au de fr it es nl se no fi dk ch at pl tr ae sa in jp kr sg hk tw br mx id th vn ph my za ru kz ua".split()
RU_PRIORITY_IDS = """
597880187 1367959794 1069871095 778681735 1401500803
1399903464 777645417 1438856489 881463973 1622633822
1052681694 313877526 483693909 1050704155 1369890634
1078986931 1515819287 1451612172 1294366633 455705533
557857165 1629869891 436145623 1418412616 1352346712
1154436683 1460007771 771700826 1384376966 502838820
1043371985 507760450 569251594
""".split()

def curl_json(url: str, retries: int = 4) -> dict:
    cmd = ["curl","-fsSL","--connect-timeout","5","--max-time","20","--retry",str(retries),"--retry-delay","1",url]
    raw = subprocess.check_output(cmd, stderr=subprocess.DEVNULL)
    return json.loads(raw)

def fetch_chart(market: str, cache: pathlib.Path) -> tuple[str,list, str|None]:
    path = cache / f"{market}-top-free.json"
    if path.exists():
        try: return market, json.loads(path.read_text())["feed"]["results"], None
        except Exception: path.unlink(missing_ok=True)
    url=f"https://rss.marketingtools.apple.com/api/v2/{market}/apps/top-free/100/apps.json"
    try:
        data=curl_json(url)
        path.parent.mkdir(parents=True, exist_ok=True); path.write_text(json.dumps(data))
        return market,data["feed"]["results"],None
    except Exception as exc: return market,[],repr(exc)
def lookup_batch(market: str, ids: list[str]) -> list[dict]:
    url="https://itunes.apple.com/lookup?"+urllib.parse.urlencode({"id":",".join(ids),"country":market,"entity":"software"})
    for attempt in range(4):
        try:
            req=urllib.request.Request(url,headers={"User-Agent":"PUSHKIN-Catalog/1.0"})
            with urllib.request.urlopen(req,timeout=25) as r: return json.load(r).get("results",[])
        except Exception:
            if attempt == 3: return []
            time.sleep(1+attempt)

def main() -> None:
    ap=argparse.ArgumentParser()
    ap.add_argument("--output", required=True, type=pathlib.Path)
    ap.add_argument("--known", required=True, type=pathlib.Path)
    ap.add_argument("--cache", default=pathlib.Path("scripts/cache/appstore"), type=pathlib.Path)
    args=ap.parse_args()
    args.cache.mkdir(parents=True, exist_ok=True)

    rows=[]; failures=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
        for market,items,err in ex.map(lambda m: fetch_chart(m,args.cache),MARKETS):
            if err:
                failures.append({"market":market,"error":err}); print("chart fail",market,flush=True); continue
            print("chart ok",market,len(items),flush=True)
            for rank,x in enumerate(items,1):
                rows.append({"market":market,"rank":rank,"id":str(x["id"]),"chartName":x["name"],"artistName":x.get("artistName","")})
    byid={}
    for r in rows:
        e=byid.setdefault(r["id"],{"id":r["id"],"chartName":r["chartName"],"artistName":r["artistName"],"appearances":[]})
        e["appearances"].append({"market":r["market"],"rank":r["rank"]})
    for e in byid.values():
        e["marketCount"]=len(e["appearances"])
        e["score"]=sum(101-a["rank"] for a in e["appearances"])
        e["bestRank"]=min(a["rank"] for a in e["appearances"])
    ordered=sorted(byid.values(),key=lambda e:(-e["score"],-e["marketCount"],e["bestRank"],e["chartName"].casefold()))
    print("unique chart ids",len(ordered),flush=True)

    groups=defaultdict(list)
    for e in ordered: groups[e["appearances"][0]["market"]].append(e["id"])
    tasks=[]
    for market,ids in groups.items():
        for i in range(0,len(ids),40): tasks.append((market,ids[i:i+40]))
    lookup={}
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:
        futs=[ex.submit(lookup_batch,m,ids) for m,ids in tasks]
        for idx,(task,fut) in enumerate(zip(tasks,futs),1):
            for x in fut.result():
                if x.get("wrapperType")=="software" and x.get("bundleId"):
                    lookup[str(x.get("trackId"))]=x
            if idx%10==0 or idx==len(tasks): print("lookup",idx,"/",len(tasks),"resolved",len(lookup),flush=True)

    known=json.loads(args.known.read_text())["apps"]
    known_by_bundle={x["bundleIdentifier"]:x for x in known}
    forced_system_bundles={
        "com.apple.MobileSMS",
        "com.apple.mobilecal",
        "com.apple.facetime",
        "com.apple.mobilemail",
        "com.apple.reminders",
        "com.apple.Passbook",
    }
    apps=[]; seen=set()
    system_extras=[]
    for x in known:
        b=x["bundleIdentifier"]
        if b not in forced_system_bundles: continue
        system_extras.append({**x,"source":"system-extra"})

    chart_limit = 1000 - len(system_extras)
    for e in ordered:
        x=lookup.get(e["id"])
        if not x: continue
        b=x.get("bundleId")
        if not b or b in seen: continue
        item={
            "name":x.get("trackName") or e["chartName"],
            "bundleIdentifier":b,
            "appleId":e["id"],
            "developer":x.get("artistName") or e.get("artistName",""),
            "genre":x.get("primaryGenreName",""),
            "source":"app-store-charts",
            "marketCount":e["marketCount"],
            "score":e["score"],
            "bestRank":e["bestRank"],
            "markets":[a["market"] for a in e["appearances"]],
        }
        team=known_by_bundle.get(b,{}).get("teamIdentifier")
        if team: item["teamIdentifier"]=team
        apps.append(item); seen.add(b)
        if len(apps)>=chart_limit: break

    # RU charts are not reliably available from Marketing Tools. Reserve only
    # the tail of the global list for a maintained set of currently available
    # mass-market Russian apps, preserving exactly 1000 total entries.
    ru_priority=[]
    for x in lookup_batch("ru", RU_PRIORITY_IDS):
        b=x.get("bundleId")
        if not b or b in seen or b in forced_system_bundles: continue
        ru_priority.append({
            "name":x.get("trackName") or b,
            "bundleIdentifier":b,
            "appleId":str(x.get("trackId")),
            "developer":x.get("artistName", ""),
            "genre":x.get("primaryGenreName", ""),
            "source":"ru-priority",
            "marketCount":0,
            "score":0,
            "bestRank":999,
            "markets":["ru-priority"],
        })
    if ru_priority:
        apps=apps[:-len(ru_priority)]
        seen={x["bundleIdentifier"] for x in apps}
        for item in ru_priority:
            if item["bundleIdentifier"] not in seen:
                apps.append(item); seen.add(item["bundleIdentifier"])

    for item in system_extras:
        if item["bundleIdentifier"] not in seen:
            apps.append(item)
            seen.add(item["bundleIdentifier"])

    payload={
        "catalogVersion":6,
        "generatedAt":time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()),
        "rankingMethod":"Apple Marketing Tools top-free charts; score=sum(101-rank) across storefronts; RU mass-market priority overlay; six iOS system apps appended for coverage",
        "markets":MARKETS,
        "chartFailures":failures,
        "apps":apps[:1000],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload,ensure_ascii=False,indent=2)+"\n")
    print("FINAL",len(payload["apps"]),"teamIDs",sum(bool(a.get("teamIdentifier")) for a in payload["apps"]),"failures",len(failures),flush=True)
    print("output",args.output,flush=True)

if __name__=="__main__":
    main()
