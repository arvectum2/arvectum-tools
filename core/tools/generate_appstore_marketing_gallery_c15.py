#!/usr/bin/env python3
"""Generate fully offline human review gallery for real-ui iPad compositions."""
import html,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
STAGE=R/'core/appstore/staged-2026-10-26'
INDEX=json.loads((STAGE/'editorial/c15-ipad-marketing-manifest.json').read_text())['apps']
parts=['<!doctype html><html lang="ru"><meta charset="utf-8"><title>Arvectum ASO C15: iPad 13″ editorial review</title>',
'<style>body{margin:0;background:#0f172a;color:#e2e8f0;font:16px -apple-system,BlinkMacSystemFont,sans-serif;padding:26px}h1{font-size:28px}h2{color:#67e8f9}details{margin:14px 0;background:#1e293b;border-radius:16px;padding:16px}summary{cursor:pointer;font-size:19px;font-weight:600}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(205px,1fr));gap:16px;margin-top:18px}.shot img{width:100%;height:auto;border:1px solid #475569;border-radius:12px}.shot small{display:block;margin:8px 0;color:#94a3b8}aside{border-left:3px solid #67e8f9;padding-left:14px;margin:18px 0}</style>',
'<h1>Arvectum Tools · C15 · iPad 13″</h1>',
'<aside>144 реальных локализованных JPEG, отражающие нативные UI-снимки iPad Simulator. 192 региональных варианта App Store. Обложки только для внутренней редакторской проверки — App Store Connect не изменялся.</aside>']
for app in ('photo','what','chickmark'):
 parts.append(f'<h2>{html.escape(app.upper())}</h2>')
 by_loc={}
 for e in INDEX[app]:by_loc.setdefault(e['locale'],[]).append(e)
 for loc,images in by_loc.items():
  images.sort(key=lambda z:z['position'])
  parts.append(f'<details><summary>{html.escape(loc)} — {len(images)} кадров</summary><div class="grid">')
  for d in images:
   src='../../../'+d['marketingPath']
   parts.append(f'<div class="shot"><small>#{d["position"]} · {html.escape(d["caption"])}</small><img loading="lazy" src="{html.escape(src,quote=True)}"></div>')
  parts.append('</div></details>')
parts.append('</html>')
out=STAGE/'review-marketing-c15.html'
out.write_text('\n'.join(parts)+'\n')
print('offline gallery:',out.relative_to(R),'regional frames:',sum(len(v) for v in INDEX.values()))
