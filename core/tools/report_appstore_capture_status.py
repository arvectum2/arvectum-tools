#!/usr/bin/env python3
"""Derive ASO screenshot progress directly from verified staged image manifest."""
import collections
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT/"core/appstore/staged-2026-10-26"
manifest = json.loads((STAGE/"screenshot_manifest.json").read_text())
lines = [
    "# ASO C11 — настоящие локализованные скриншоты, 27.10.2026",
    "",
    "**Только staged материалы, не опубликовано в App Store.**"
    " Источник: native XCUITest на изолированных iOS 27 Simulator,"
    " реальные экраны iPhone/iPad и синтетические безвредные демоданные.",
    "",
    "| Приложение | Всего слотов | Подтверждённых скриншотами | Уникальных файлов | iPhone | iPad | Осталось |",
    "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
]
total=0;complete=0;unique=set()
for app, group in manifest["apps"].items():
    shots=group["slots"]
    c=[s for s in shots if s.get("path")]
    files={s["path"] for s in c}
    iphone=sum(s.get("path") is not None for s in shots if s["device"]=="iphone-6.9")
    ipad=sum(s.get("path") is not None for s in shots if s["device"]=="ipad-13")
    lines.append(f"| {app} | {len(shots)} | {len(c)} | {len(files)} | {iphone} | {ipad} | {len(shots)-len(c)} |")
    total+=len(shots);complete+=len(c)
    unique.update(files)
lines+=["",f"**Покрытие: {complete}/{total} слотов, {len(unique)} уникальных файлов.**"
         " Региональные английские и испанские метаданные могут повторно использовать"
         " один честный native UI скриншот своего языка; это не новая локализация бинарника.",
         "",
         "## Приёмочные ограничения","",
         "- [x] Регионы сопоставлены с языками исходного iOS UI, изображения в полном разрешении Apple.",
         "- [x] SHA-256 каждого существующего файла проверяется офлайн валидатором ASO.",
         "- [ ] Визуальная редактура и маркетинговая композиция изображений с учётом региональных ASO-обещаний.",
         "- [ ] Верификация по финальному подписанному Release Candidate, реальным устройствам и проверка контента у носителей.",
         "- [ ] Apple ASC metadata upload / screenshot publication — только с отдельным release approval.",
         "",
         "См. [манифест изображений](../appstore/staged-2026-10-26/screenshot_manifest.json)"
         " и [64 ASO-пакета](../appstore/staged-2026-10-26/README.md)."]
out=ROOT/"core/docs/ASO_NATIVE_CAPTURE_C11_2026-10-27.md"
out.write_text("\n".join(lines)+"\n",encoding="utf-8")
print(f"ASO screenshot progress: {complete}/{total}, unique native image files={len(unique)}")
