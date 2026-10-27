#!/usr/bin/env python3
"""Human-readable read-only index for all staged App Store text localizations."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
STAGE=ROOT/"core/appstore/staged-2026-10-26"
out=ROOT/"core/docs/ASO_COPY_MATRIX_C11_2026-10-27.md"
lines=[
    "# C11 — полный реестр региональных ASO-карточек, 27.10.2026",
    "",
    "Все тексты **DRAFT_NOT_UPLOADED**. Ниже — реальные значения из JSON,"
    " не записи в App Store Connect. Проходят автоматические проверки длины,"
    " но редактура носителями языков **не завершена**.",
    "",
    "| Приложение | Регион | Название (до 30 символов) | Подзаголовок (до 30) | Keywords, байт | Описание, символов |",
    "| --- | --- | --- | --- | ---: | ---: |",
]
for app in ("photo","pushkin","what","chickmark"):
    doc=json.loads((STAGE/(app+".json")).read_text())
    for locale, data in doc["localeData"].items():
        def esc(s):return s.replace("|",r"\|").replace("\n"," ")
        lines.append(
            f"| {app} | {locale} | {esc(data['name'])} | {esc(data['subtitle'])}"
            f" | {len(data['keywords'].encode('utf-8'))} | {len(data['description'])} |"
        )
lines.extend([
    "",
    "## Приёмка текста",
    "",
    "- [x] Для каждой из 64 комбинаций имеются название, подзаголовок, поисковые слова,"
    " описание, рекламный текст, What's New и 4 тематические подписи к кадрам.",
    "- [x] Автоматический валидатор проверяет лимиты и релевантные оговорки о Shortcuts,"
    " HealthKit, рекламе и ограничениях распознавания.",
    "- [ ] Носители языков подтверждают орфографию, тон, поиск и ключевые"
    " пользовательские обещания по своим рынкам.",
    "- [ ] Совпадение метаданных с конкретными App Store Connect локалями и финальным"
    " подписанным бинарником до публикации.",
    "",
    "Полные тексты — [JSON-черновики по каждому приложению]"
    "(../appstore/staged-2026-10-26/README.md);"
    " результаты снимков — [C11 screenshot QA](ASO_NATIVE_CAPTURE_C11_2026-10-27.md).",
])
out.write_text("\n".join(lines)+"\n")
print("Prepared",len(lines)-13,"table lines in",out.relative_to(ROOT))
