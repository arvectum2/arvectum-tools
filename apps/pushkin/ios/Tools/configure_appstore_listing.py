#!/usr/bin/env python3
import json, os, pathlib, re, subprocess, urllib.request, urllib.error

APP_ID="6817847111"
VERSION_ID="87056df5-93c9-411f-b44c-2e3ea5cae5bf"
VERSION_LOC_EN="0a199bb5-0204-4f8a-ab14-89118afb55f1"
APP_INFO_ID="98d5237a-2975-401b-bd0f-6ccf3f5b2286"
APP_INFO_LOC_EN="775d1be2-f0d4-4fb4-8151-1dada794bd50"

EN_DESCRIPTION="""PUSHKIN keeps a local history of notifications on your iPhone so dismissed alerts are easier to find later.

Search what you missed
Browse recent notifications and search by app, title or message text.

Private by design
Notification content stays on your iPhone. PUSHKIN has no account system, cloud sync, runtime backend, notification-content analytics or advertising in version 1.0.

Fast setup for popular apps
PUSHKIN includes an offline catalog of popular apps and signed Shortcuts configurations. Setup uses Apple's Shortcuts automation system and App Intents.

Still works for uncommon apps
If an app is not in the bundled catalog yet, PUSHKIN shows a local step-by-step manual setup path. No server is required.

Help improve coverage
Missing an app? Send its exact name through support at arvectum.com or mention the app name in your App Store review. We use requests to prioritize future catalog updates.

PUSHKIN is an Arvectum Tool."""

RU_DESCRIPTION="""PUSHKIN сохраняет историю уведомлений на iPhone, чтобы случайно закрытое сообщение можно было найти позже.

Найдите то, что потеряли
Просматривайте историю и ищите по приложению, заголовку или тексту уведомления.

Приватность по умолчанию
Содержимое уведомлений остаётся на iPhone. В версии 1.0 нет аккаунта, облачной синхронизации, серверного бэкенда, аналитики содержимого уведомлений и рекламы.

Быстрая настройка популярных приложений
PUSHKIN поставляется со встроенной офлайн-базой популярных приложений и готовыми конфигурациями для системного приложения «Команды».

Если приложения нет в базе
Его всё равно можно подключить вручную по пошаговой инструкции внутри PUSHKIN. Сервер для этого не нужен.

Помогите улучшить базу
Не нашли нужное приложение? Напишите его точное название через поддержку на arvectum.com или укажите название в отзыве App Store. По таким запросам мы приоритизируем обновления базы.

PUSHKIN — приложение из семейства Arvectum Tools."""

CONFIG=pathlib.Path.home()/".config/arvectum/appstore-connect.env"
vals={}
for raw in CONFIG.read_text().splitlines():
    line=raw.strip()
    if line and not line.startswith("#") and "=" in line:
        k,v=line.split("=",1); vals[k.strip()]=v.strip().strip('"').strip("'")
key_id=vals["ASC_KEY_ID"]; issuer=vals["ASC_ISSUER_ID"]
key_dir=pathlib.Path(vals.get("ASC_KEY_DIR", str(pathlib.Path.home()/".appstoreconnect/private_keys")))
altool="/Applications/Xcode-27.0.0.app/Contents/SharedFrameworks/ContentDelivery.framework/Versions/A/Resources/altool"
env=os.environ.copy(); env["API_PRIVATE_KEYS_DIR"]=str(key_dir)
p=subprocess.run([altool,"--generate-jwt","--apiKey",key_id,"--apiIssuer",issuer],text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=env)
m=re.search(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+",p.stdout+"\n"+p.stderr)
if not m: raise SystemExit("JWT generation failed")
token=m.group(0)

def api(method,path,body=None):
    data=None if body is None else json.dumps(body,separators=(",",":")).encode()
    req=urllib.request.Request("https://api.appstoreconnect.apple.com"+path,data=data,method=method)
    req.add_header("Authorization","Bearer "+token)
    req.add_header("Content-Type","application/json")
    try:
        with urllib.request.urlopen(req,timeout=30) as r:
            raw=r.read().decode()
            return r.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw=e.read().decode()
        try: payload=json.loads(raw)
        except Exception: payload={"raw":raw}
        return e.code,payload

def must(method,path,body):
    status,payload=api(method,path,body)
    if status not in (200,201):
        print("FAILED",method,path,status,json.dumps(payload,ensure_ascii=False))
        raise SystemExit(2)
    print("OK",method,path,status)
    return payload

# App-level content rights.
must("PATCH",f"/v1/apps/{APP_ID}",{
  "data":{"type":"apps","id":APP_ID,"attributes":{"contentRightsDeclaration":"USES_THIRD_PARTY_CONTENT"}}
})

# Age rating: PUSHKIN is a local utility with no chat, social feed, ads, web browser,
# gambling, mature content, health/medical content, or violent content of its own.
age_attributes={
  "advertising":False,
  "alcoholTobaccoOrDrugUseOrReferences":"NONE",
  "contests":"NONE",
  "gambling":False,
  "gamblingSimulated":"NONE",
  "gunsOrOtherWeapons":"NONE",
  "healthOrWellnessTopics":False,
  "lootBox":False,
  "medicalOrTreatmentInformation":"NONE",
  "messagingAndChat":False,
  "parentalControls":False,
  "profanityOrCrudeHumor":"NONE",
  "ageAssurance":False,
  "sexualContentGraphicAndNudity":"NONE",
  "sexualContentOrNudity":"NONE",
  "socialMedia":False,
  "socialMediaAgeRestricted":False,
  "horrorOrFearThemes":"NONE",
  "matureOrSuggestiveThemes":"NONE",
  "unrestrictedWebAccess":False,
  "userGeneratedContent":False,
  "violenceCartoonOrFantasy":"NONE",
  "violenceRealisticProlongedGraphicOrSadistic":"NONE",
  "violenceRealistic":"NONE",
  "ageRatingOverrideV2":"NONE",
  "koreaAgeRatingOverride":"NONE"
}
must("PATCH",f"/v1/ageRatingDeclarations/{APP_INFO_ID}",{
  "data":{"type":"ageRatingDeclarations","id":APP_INFO_ID,"attributes":age_attributes}
})

# Existing English version metadata.
must("PATCH",f"/v1/appStoreVersionLocalizations/{VERSION_LOC_EN}",{
  "data":{"type":"appStoreVersionLocalizations","id":VERSION_LOC_EN,"attributes":{
    "description":EN_DESCRIPTION,
    "keywords":"notification,history,alerts,archive,search,missed,shortcuts,privacy,local",
    "marketingUrl":"https://arvectum.com",
    "promotionalText":"Keep a searchable history of important iPhone notifications. Local on your device, no account, no cloud backend.",
    "supportUrl":"https://arvectum.com"
  }}
})

# Existing English app info metadata.
must("PATCH",f"/v1/appInfoLocalizations/{APP_INFO_LOC_EN}",{
  "data":{"type":"appInfoLocalizations","id":APP_INFO_LOC_EN,"attributes":{
    "name":"PUSHKIN by Arvectum",
    "subtitle":"Notification History",
    "privacyPolicyUrl":"https://arvectum.com/privacy"
  }}
})

# Russian version localization, create only if absent.
status,locs=api("GET",f"/v1/appStoreVersions/{VERSION_ID}/appStoreVersionLocalizations?limit=50")
ru=next((x for x in locs.get("data",[]) if x.get("attributes",{}).get("locale")=="ru"),None)
attrs={
  "description":RU_DESCRIPTION,
  "keywords":"уведомления,история,архив,поиск,пропущенные,команды,приватность",
  "marketingUrl":"https://arvectum.com",
  "promotionalText":"Сохраняйте и находите важные уведомления iPhone. История хранится локально — без аккаунта и облачного сервера.",
  "supportUrl":"https://arvectum.com"
}
if ru:
    must("PATCH",f"/v1/appStoreVersionLocalizations/{ru['id']}",{"data":{"type":"appStoreVersionLocalizations","id":ru["id"],"attributes":attrs}})
else:
    must("POST","/v1/appStoreVersionLocalizations",{
      "data":{"type":"appStoreVersionLocalizations","attributes":{"locale":"ru",**attrs},
      "relationships":{"appStoreVersion":{"data":{"type":"appStoreVersions","id":VERSION_ID}}}}
    })

# Russian app-info localization, create only if absent.
status,locs=api("GET",f"/v1/appInfos/{APP_INFO_ID}/appInfoLocalizations?limit=50")
ru=next((x for x in locs.get("data",[]) if x.get("attributes",{}).get("locale")=="ru"),None)
attrs={"name":"PUSHKIN by Arvectum","subtitle":"История уведомлений","privacyPolicyUrl":"https://arvectum.com/privacy"}
if ru:
    must("PATCH",f"/v1/appInfoLocalizations/{ru['id']}",{"data":{"type":"appInfoLocalizations","id":ru["id"],"attributes":attrs}})
else:
    must("POST","/v1/appInfoLocalizations",{
      "data":{"type":"appInfoLocalizations","attributes":{"locale":"ru",**attrs},
      "relationships":{"appInfo":{"data":{"type":"appInfos","id":APP_INFO_ID}}}}
    })

print("LISTING_CONFIGURED")
