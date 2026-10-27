#!/usr/bin/env python3
"""Read-only Apple public Lookup comparison. Not authenticated App Store Connect."""
import concurrent.futures, datetime, json, urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
IDS={6816346084:'photo',6817847111:'pushkin',6822476399:'what',6818711298:'chickmark'}
COUNTRIES=('ru','us','gb','ca','au','es','mx','fr','de','it','pt','br','jp','kr','cn','tw')
def fetch(country):
 url='https://itunes.apple.com/lookup?id='+','.join(map(str,IDS))+'&country='+country+'&entity=software'
 headers={'User-Agent':'Arvectum-ASO-readonly-check/1.0','Accept':'application/json'}
 with urllib.request.urlopen(urllib.request.Request(url,headers=headers),timeout=18) as resp:
  data=json.loads(resp.read())
 results={}
 for v in data.get('results',[]):
  if v.get('trackId') not in IDS:continue
  app=IDS[v['trackId']]
  shots={k:len(v.get(k,[])) for k in ('screenshotUrls','ipadScreenshotUrls','appletvScreenshotUrls')}
  results[app]={'name':v.get('trackName'),'version':v.get('version'),'releaseDate':v.get('currentVersionReleaseDate'),
   'category':v.get('primaryGenreName'),'languages':v.get('languageCodesISO2A',[]),'screenshots':shots,
   'minimumOs':v.get('minimumOsVersion'),'storeURL':v.get('trackViewUrl')}
 return country,results
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
 tasks=list(pool.map(fetch,COUNTRIES))
now=datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds')
snap={'asOfUTC':now,'source':'Apple public iTunes Lookup (not App Store Connect)','countries':dict(tasks)}
out=ROOT/'core/appstore/staged-2026-10-26/editorial/c16-public-storefront-snapshot.json'
out.write_text(json.dumps(snap,ensure_ascii=False,indent=2)+'\n')
lines=['# C16 — публичная сверка Apple App Store, 27 октября 2026','',
'Источник: официальный Apple Lookup API, HTTPS только для чтения. UTC: '+now+'. **Это не App Store Connect**, данные могут кэшироваться, не показывают keywords, ASC status, доступные локали ASC, build номера или App Privacy ответы.','',
'| Приложение | RU версия | US версия | Языки опубликованной RU-сборки | RU iPhone/iPad снимки |',
'| --- | --- | --- | --- | --- |']
for id,app in IDS.items():
 ru=snap['countries']['ru'].get(app,{})
 us=snap['countries']['us'].get(app,{})
 shots=ru.get('screenshots',{})
 lines.append(f"| {app} | {ru.get('version','не найдено')} | {us.get('version','не найдено')} | {', '.join(ru.get('languages',[]))} | {shots.get('screenshotUrls',0)}/{shots.get('ipadScreenshotUrls',0)} |")
lines+=['','Всего ответов: '+str(len(snap['countries']))+' витрин × 4 Apple ID. Региональный fallback не считается поддержкой исходных языков UI. Черновики C15 **не опубликованы**.','',
'### Проверки и следующий этап','',
'- [x] Достоверные публичные версии, перечни языков и устройства проверены в Apple Lookup read-only.',
'- [ ] ASC authenticated read-only diff: name/subtitle/keywords/description, локали, статус App Privacy, скриншоты и build для конкретной версии.',
'- [ ] Release/metadata upload только после приёмки подписанной сборки и согласия владельца.']
doc=ROOT/'core/docs/ASO_C16_PUBLIC_STORE_QA_2026-10-27.md'
doc.write_text('\n'.join(lines)+'\n')
print('Apple public Lookup',len(snap['countries']),'regions',len(IDS),'apps')
print('\n'.join(lines[4:10]))
