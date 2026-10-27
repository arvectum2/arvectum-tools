#!/usr/bin/env python3
"""Structural bilingual editorial audit. Human native-speaker acceptance is separate."""
import csv,json,re,sys
from collections import Counter,defaultdict
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/"core/tools"))
import localization_portfolio as lp
import editorial_localization_audit as er
OUT=ROOT/"core/appstore/staged-2026-10-26/editorial"
OUT.mkdir(parents=True,exist_ok=True)
risk=re.compile(r'privacy|private|consent|tracking|health|icloud|sync|ads|adver|record|transcri|speak|audio|video|camera|microphone|permission|notification|shortcut|backup|delet|erase|data|location|file|export|import|upload|security|fail|recovery|restore|error|purchase|subscription|device|storage|watch|transf|background',re.I)
findings=er.audit()
flags=[]
critical=[]
by_locale=defaultdict(lambda:{"bundles":set(),"keys":0,"high_risk":0,"flags":0})
reg=lp.config()
for app,conf in reg["apps"].items():
 for bundle in conf["bundles"]:
  root=ROOT/bundle
  for en_file in sorted((root/"en.lproj").glob("*.strings")):
   orig=lp.read_strings(en_file,[])
   for locale_file in sorted(root.glob("*.lproj/"+en_file.name)):
    lang=locale_file.parent.name[:-6]
    if lang=="en":continue
    trans=lp.read_strings(locale_file,[])
    st=by_locale[lang]
    st["bundles"].add(bundle)
    st["keys"]+=len(trans)
    for key,original in orig.items():
     tr=trans.get(key,"")
     if not tr and original:
      flags.append((app,bundle,lang,key,"empty_translation",original,tr));st["flags"]+=1
      continue
     if risk.search(key+" "+original):
      st["high_risk"]+=1
      critical.append((app,bundle,lang,en_file.name,key,original,tr,"NATIVE_REVIEW_REQUIRED"))
     if lp.placeholders(original)!=lp.placeholders(tr):
      flags.append((app,bundle,lang,key,"format_mismatch",original,tr));st["flags"]+=1
     if en_file.name=="InfoPlist.strings" and "UsageDescription" in key and tr==original:
      flags.append((app,bundle,lang,key,"permission_untranslated",original,tr));st["flags"]+=1
     if key=="CFBundleDisplayName" and lang!="ru" and app=="what" and "UhWhat?" not in tr:
      flags.append((app,bundle,lang,key,"app_brand_translated",original,tr));st["flags"]+=1
for item in findings["english_identical_untriaged"]:
 flags.append(("","","",item[1],"unclassified_english_identical",item[2],""))
with (OUT/"critical_source_target_review.csv").open("w",newline="") as f:
 w=csv.writer(f,lineterminator="\n");w.writerow(["app","bundle","locale","file","key","canonical_english","translated_copy","review_status"])
 w.writerows(critical)
with (OUT/"machine_flags.csv").open("w",newline="") as f:
 w=csv.writer(f,lineterminator="\n");w.writerow(["app","bundle","locale","key","finding","source","target"]);w.writerows(flags)
details={"status":"structural_and_risk_screen_only_not_human_editorial_signoff",
 "date":"2026-10-26","catalogFiles":findings["files"],
 "localizedEntries":findings["entries"],
 "englishIdenticalTriaged":findings["english_identical_triaged"],
 "englishIdenticalUntriaged":findings["english_identical_untriaged"],
 "englishIdenticalStaleExceptions":findings["english_identical_stale_exceptions"],
 "criticalReviewRows":len(critical),"machineErrorFlags":len(flags),
 "locales":{l:{**v,"bundles":len(v["bundles"]),"nativeSpeakerSignedOff":False}
            for l,v in sorted(by_locale.items())}}
(OUT/"audit.json").write_text(json.dumps(details,ensure_ascii=False,indent=2)+"\n")
md=["# Проверка локализаций — редакторская матрица C10, 26.10.2026","",
"**Выполнено:** машинная сверка исходных каталогов четырёх приложений (iPhone/Watch/widgets), ключей и placeholder; выделены критичные фразы в двуязычную таблицу, выполнены специальные проверки privacy/permissions/app names. **Не выполнено:** профессиональная вычитка носителями, региональная юридическая редактура и физический QA. Нельзя отмечать эти этапы как подписанные.",
"",
"| Язык | Значений | Критичные для редактора | Машинных ошибок | Статус |",
"| --- | ---: | ---: | ---: | --- |"]
for lang,v in sorted(by_locale.items()):
 md.append(f"| {lang} | {v['keys']} | {v['high_risk']} | {v['flags']} | машинный аудит |")
md+=["",
f"Полная выборка: **{findings['files']} каталогов / {findings['entries']} локализованных значений**; {len(critical)} риск-чувствительных строк, выгружены в [critical_source_target_review.csv](critical_source_target_review.csv).",
f"Разрешённых совпадений с английским: {findings['english_identical_triaged']}; новых непроверенных совпадений: {len(findings['english_identical_untriaged'])}. Машинных критических ошибок: {len(flags)}.",
"",
"## Коррекции, проверенные вручную по оригиналу и смыслу",
"",
"- [x] KO ChickMark: перевод «transcript» как «табель успеваемости» заменён на корректный смысл; ошибка в названии приложения при повторном открытии исправлена.",
"- [x] KO Ухват: «transcribe more» ошибочно превращалось в «record more»; исправлена формулировка о переводе аудио в текст; английское название продукта сохраняется.",
"- [x] KO App Store cards: название UhWhat? не переводится и не транслитерируется; исправлены вводящие в заблуждение слова для Apple Watch и транскрипции.",
"- [x] 64 ASO-комплекта в 16 поддерживаемых региональных локалях проверяются валидатором ограничений и названий.",
"",
"## Внешние блокеры",
"",
"- [ ] Native speaker по каждому из 11 переводных языков и все опасные строки из CSV (особенно Apple Health, согласия, уведомления, удаление, фоновые записи).",
"- [ ] Физические сценарии с длинным текстом, iPhone/Watch/VoiceOver, проверки безопасного обновления без удаления пользовательских данных.",
"- [ ] Подписанные Release IPA и снимки из точных новых бинарников, затем отдельное разрешение на App Store Connect.",
"",
"**Результат аудита — машинная проверка без допуска к публикации**. CSV позволяет назначить конкретные строки редакторам без повторного извлечения строк из Xcode."]
(OUT/"REPORT.md").write_text("\n".join(md)+"\n")
print("EDITORIAL",findings["files"],"catalogs",findings["entries"],"strings",len(critical),"critical",len(flags),"machine flags")
if flags:sys.exit(1)
