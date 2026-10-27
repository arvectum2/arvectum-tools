#!/usr/bin/env python3
"""Build a local-only human-review ASO gallery of native simulator screenshots."""
from pathlib import Path
from urllib.parse import quote
import json,os
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"core/appstore/staged-2026-10-26"
manifest=json.loads((OUT/"screenshot_manifest.json").read_text())
records=[]
for app in ("photo","pushkin","what","chickmark"):
    doc=json.loads((OUT/(app+".json")).read_text())
    for locale,meta in doc["localeData"].items():
        for device in ("iphone-6.9","ipad-13"):
            shots=sorted((x for x in manifest["apps"][app]["slots"]
                          if x["locale"]==locale and x["device"]==device),
                         key=lambda v:v["position"])
            if not shots:continue
            images=[]
            for s in shots:
                path=ROOT/s["path"]
                assert path.is_file(),path
                rel=Path(os.path.relpath(path,OUT)).as_posix()
                images.append({"src":quote(rel,safe="/-._~"),"caption":s["headline"],"index":s["position"]})
            records.append({"app":app,"locale":locale,"device":device,
                            "name":meta["name"],"subtitle":meta["subtitle"],
                            "promo":meta["promotionalText"],
                            "keywords":meta["keywords"],"description":meta["description"],
                            "whatsNew":meta["whatsNew"],"images":images})
assert len(records)==112
assert sum(len(r["images"]) for r in records)==448
raw=json.dumps(records,ensure_ascii=False).replace("<","\\u003c")
page='''<!doctype html><html lang="ru"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Arvectum · ASO Review</title>
<style>
:root{color-scheme:dark;background:#10151d;color:#e6edf4;font:15px/1.55 system-ui,-apple-system,sans-serif}
*{box-sizing:border-box}body{margin:0}
header{padding:24px max(22px,calc((100vw - 1300px)/2));background:#192230;border-bottom:1px solid #344053}
h1{font-size:27px;margin:0 0 8px}h2{font-size:20px;margin:0 0 4px}h3{font-size:13px;color:#9eb1c4;margin:16px 0 4px}
p{margin:5px 0}.sub{color:#a4b3c5}.notice{color:#ffcd89;max-width:950px}
main{max-width:1340px;margin:auto;padding:22px}
.filters{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:18px}
label{display:grid;gap:6px;color:#a7b8c9;font-size:13px}
select{font:inherit;min-width:180px;padding:9px 11px;border-radius:10px;border:1px solid #506078;background:#263244;color:#e9f2f9}
.meta{background:#1d2837;border:1px solid #374961;border-radius:14px;padding:20px;margin:20px 0}
.meta p{white-space:pre-wrap;overflow-wrap:anywhere}
.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px}
figure{margin:0;background:#202c3a;padding:10px;border:1px solid #39495b;border-radius:14px}
figure img{display:block;width:100%;height:auto;max-height:720px;object-fit:contain;border-radius:9px}
figcaption{margin:10px 0 2px;font-size:13px}
.small{color:#89d9cc;font-size:13px;margin-top:9px}
footer{margin-top:30px;padding:24px 0;color:#8fa0b4;font-size:13px}
@media(max-width:900px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}
@media(max-width:490px){.grid{grid-template-columns:1fr}.filters label{flex:1}select{width:100%}}
</style></head>
<body><header>
<h1>Arvectum Tools · App Store ASO</h1>
<p class="sub">64 комплекта · 448 региональных слотов · 336 оригинальных PNG · iPhone / iPad</p>
<p class="notice">DRAFT — публикация не выполнялась. Это настоящие снимки с iOS Simulator, но не финальный подписанный RC; переводы и дизайн ещё требуют редакторской приёмки.</p>
</header>
<main>
<div class="filters"><label>Приложение<select id="app"></select></label><label>Локаль<select id="locale"></select></label><label>Устройство<select id="device"></select></label></div>
<p id="status" class="small"></p>
<section class="meta" id="meta"></section><section class="grid" id="grid"></section>
<footer>Просмотр выполняется локально без сетевых запросов и без копий PNG. Источник: screenshot_manifest.json · DRAFT_NOT_UPLOADED.</footer>
</main>
<script type="application/json" id="data">__DATA__</script>
<script>
"use strict";
const records=JSON.parse(document.getElementById("data").textContent);
const el=id=>document.getElementById(id);
const app=el("app"),locale=el("locale"),device=el("device");
const brands={photo:"Фото и PDF",pushkin:"PUSHKIN",what:"Ухват / UhWhat?",chickmark:"ChickMark"};
const unique=values=>Array.from(new Set(values));
function fill(sel,vals,display){
 const previous=sel.value;sel.replaceChildren();
 for(const v of vals){const op=document.createElement("option");op.value=v;op.textContent=display?display(v):v;sel.append(op)}
 sel.value=vals.includes(previous)?previous:vals[0];
}
function txt(tag,value){const e=document.createElement(tag);e.textContent=value;return e}
function render(){
 const forApp=records.filter(x=>x.app===app.value);
 fill(locale,unique(forApp.map(x=>x.locale)));
 fill(device,unique(forApp.filter(x=>x.locale===locale.value).map(x=>x.device)),x=>x==="ipad-13"?"iPad 13″":"iPhone 6,9″");
 const r=records.find(x=>x.app===app.value&&x.locale===locale.value&&x.device===device.value);
 if(!r)return;
 el("status").textContent=brands[r.app]+" · "+r.locale+" · "+r.device+" · "+r.images.length+" изображения";
 const m=el("meta");m.replaceChildren();
 m.append(txt("h2",r.name),txt("p",r.subtitle),txt("h3","Promotional text"),txt("p",r.promo),
          txt("h3","Keywords"),txt("p",r.keywords),txt("h3","Description"),txt("p",r.description),
          txt("h3","What's New"),txt("p",r.whatsNew));
 const g=el("grid");g.replaceChildren();
 for(const shot of r.images){
  const fig=document.createElement("figure"),im=document.createElement("img");
  im.src=shot.src;im.loading="lazy";im.alt=r.app+" "+r.locale+" "+shot.caption;
  fig.append(im,txt("figcaption",shot.index+". "+shot.caption));g.append(fig);
 }
}
fill(app,Object.keys(brands),x=>brands[x]);
app.addEventListener("change",render);
locale.addEventListener("change",render);
device.addEventListener("change",render);
render();
</script></body></html>'''
(OUT/"review-gallery.html").write_text(page.replace("__DATA__",raw),encoding="utf-8")
print("Generated 112 offline review views, 448 referenced slots,",round((OUT/"review-gallery.html").stat().st_size/1024),"KB")
