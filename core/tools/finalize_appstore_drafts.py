#!/usr/bin/env python3
"""Limited terminology cleanup and keyword budgeting for staged metadata only."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]/'core/appstore/staged-2026-10-26'
RU_KEYWORDS={
 'pushkin':'уведомления,архив,поиск,команды,история',
 'what':'диктофон,голос,запись,аудио,мысли,видео',
 'chickmark':'привычки,серии,цели,планер,отметки'
}
BRAND_VARIANTS={
 'es-ES':['¿Eh qué?'],'es-MX':['¿Eh qué?'],
 'fr-FR':['EuhQuoi ?','Euh quoi ?'],
 'de-DE':['ÄhWas?'],
 'it':['Uh cosa?'],
 'ja':['え、何？'],
 'ko':['어뭐?'],
 'pt-BR':['Uh, o que?'],'pt-PT':['Uh, o quê?'],
 'zh-Hans':['呃什么？'],
 'zh-Hant':['呃什麼？']
}
for app in ('pushkin','what','chickmark','photo'):
 p=ROOT/f'{app}.json'; data=json.loads(p.read_text())
 for loc,v in data['localeData'].items():
  if loc=='ru' and app in RU_KEYWORDS:v['keywords']=RU_KEYWORDS[app]
  if app=='what':
   for variant in BRAND_VARIANTS.get(loc,[]):
    v['description']=v['description'].replace(variant,'UhWhat?')
   if loc=='ko':
    v['keywords']='음성,녹음,오디오,메모,아이디어,받아쓰기,시계,동영상,검색'
    v['description']=v['description'].replace('다시 방문할 수 있습니다','다시 확인할 수 있습니다').replace('스크립트','텍스트 변환')
   if loc=='ja':
    v['description']=v['description'].replace('再検討','確認')
  if app=='chickmark' and loc=='ko':
   v['keywords']=v['keywords'].replace('시청','애플워치').replace('일일','매일').replace(',플래너','')
  if app=='pushkin' and loc=='ko':
   v['keywords']=v['keywords'].replace('부재중','놓친 알림').replace('바로가기','단축어')
 p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 print('TERMS',app)
