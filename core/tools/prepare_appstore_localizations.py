#!/usr/bin/env python3
"""Generate staged App Store listings from curated seeds; never contact ASC."""
from pathlib import Path
import concurrent.futures, json, re, time, urllib.parse, urllib.request
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"core/appstore/staged-2026-10-26"
names=json.loads((OUT/"names-and-subtitles.json").read_text())
seeds=json.loads((OUT/"product-seeds.json").read_text())
photo=json.loads((ROOT/"photo-pdf-to-size/docs/aso/metadata-2026-10-26-review.json").read_text())["localeData"]
locale_map={"ru":"ru","en-US":"en","en-GB":"en","en-AU":"en","en-CA":"en",
"es-ES":"es","es-MX":"es","fr-FR":"fr","de-DE":"de","it":"it","ja":"ja",
"ko":"ko","pt-BR":"pt-BR","pt-PT":"pt-PT","zh-Hans":"zh-CN","zh-Hant":"zh-TW"}
cache_path=OUT/"translate-cache.json"
cache=json.loads(cache_path.read_text()) if cache_path.exists() else {}
def local_key(loc):
 if loc.startswith("en-"):return "en"
 if loc.startswith("es-"):return "es"
 if loc.startswith("pt-"):return "pt"
 return {"de-DE":"de","fr-FR":"fr"}.get(loc,loc)
def translate(item):
 lang,text=item
 key=json.dumps([lang,text],ensure_ascii=False)
 if key in cache:return key,cache[key],None
 params=urllib.parse.urlencode({"client":"gtx","sl":"en","tl":lang,"dt":"t","q":text})
 url="https://translate.googleapis.com/translate_a/single?"+params
 for attempt in range(5):
  try:
   with urllib.request.urlopen(urllib.request.Request(url,headers={"User-Agent":"Mozilla/5.0"}),timeout=14) as res:
    raw=json.load(res)
   output="".join(x[0] for x in raw[0] if x and x[0]).replace("\u200b","").strip()
   if not output:raise ValueError("empty response")
   return key,output,None
  except Exception as e:
   if attempt==4:return key,"",str(e)
   time.sleep((attempt+1)*0.8)
def fit_keywords(q):
 q=q.replace("，",",").replace("、",",").replace("،",",").replace("؛",",")
 bits=[x.strip() for x in q.replace("\n",",").split(",")]
 if len(bits)<3:return ""
 result=[]
 for term in bits:
  term=term.strip(" .;:!?'\"")
  if not term or term.casefold() in [x.casefold() for x in result]:continue
  if len(",".join(result+[term]).encode("utf-8"))>100:continue
  result.append(term)
 return ",".join(result)
jobs=[]
for app in ["pushkin","what","chickmark","photo"]:
 for loc,lang in locale_map.items():
  if loc in ("ru","en-US","en-GB","en-AU","en-CA"):continue
  if app=="photo" and loc in photo:continue
  v=seeds["pushkin" if app=="photo" else app]["en"] if app!="photo" else photo["en-US"]
  for field in ("promotionalText","description","whatsNew","keywords"):
   jobs.append((lang,v[field]))
  for heading in v["screenshots"]:jobs.append((lang,heading))
jobs=list(dict.fromkeys(jobs))
print("translation fields:",len(jobs),"cached:",sum(json.dumps(list(x),ensure_ascii=False) in cache for x in jobs),flush=True)
errors=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=14) as pool:
 for i,(key,value,error) in enumerate(pool.map(translate,jobs),1):
  if error:errors.append((key[:65],error))
  else:cache[key]=value
  if i%45==0:
   cache_path.write_text(json.dumps(cache,ensure_ascii=False))
   print(f"{i}/{len(jobs)}, failed={len(errors)}",flush=True)
cache_path.write_text(json.dumps(cache,ensure_ascii=False,indent=2)+"\n")
if errors:
 print("RETRY NEEDED",errors[:8],flush=True)
 raise SystemExit(2)
def tr(lang,text):
 return cache[json.dumps([lang,text],ensure_ascii=False)]
for app in ["pushkin","what","chickmark","photo"]:
 result={"appId":seeds[app]["appId"] if app!="photo" else "6816346084",
 "bundleId":seeds[app]["bundleId"] if app!="photo" else "ru.arvectum.tools.tosize",
 "stage":"DRAFT_NOT_UPLOADED","source":"curated EN/RU seeds and automated translations; not native-speaker approved",
 "created":"2026-10-26","localeData":{}}
 for loc,lang in locale_map.items():
  if app=="photo" and loc in photo:
   entry=dict(photo[loc])
  elif app!="photo" and loc in ("ru","en-US","en-GB","en-AU","en-CA"):
   base=seeds[app]["ru" if loc=="ru" else "en"]
   entry=dict(base)
  else:
   base=seeds[app]["en"] if app!="photo" else photo["en-US"]
   entry={f:tr(lang,base[f]) for f in ("promotionalText","description","whatsNew")}
   entry["screenshots"]=[tr(lang,h) for h in base["screenshots"]]
   entry["keywords"]=fit_keywords(tr(lang,base["keywords"]))
  if app!="photo":
   entry["name"],entry["subtitle"]=names[app][local_key(loc)]
   entry["privacyPolicyUrl"]="https://arvectum.com/privacy.html"
  else:
   if loc not in photo:
    entry["name"],entry["subtitle"]=names["photo"][loc]
    entry["privacyPolicyUrl"]="https://arvectum.com/photo-pod-razmer-privacy.html"
    entry["keywords"]=fit_keywords(tr(lang,photo["en-US"]["keywords"]))
  result["localeData"][loc]=entry
 (OUT/f"{app}.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
 print("WROTE",app,len(result["localeData"]),"locales",flush=True)
