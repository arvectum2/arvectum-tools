#!/usr/bin/env python3
"""Read-only ASO C14 keyword and visual review ledger."""
import json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
E=R/'core/appstore/staged-2026-10-26/editorial'
x=json.loads((E/'c14-keyword-overrides.json').read_text())
g=json.loads((E/'c14-release-gate.json').read_text())
rows=['# C14 — проверка ключей и релизный визуальный контроль, 27.10.2026','',
'После сверки с рекомендациями Apple удалены точные совпадения отдельных keywords с title/subtitle в черновых карточках. Это не результат измеренного роста ранжирования.','',
'| Продукт | Изменено региональных комплектов |',
'| --- | ---: |']
for app in ('photo','pushkin','what','chickmark'):
 rows.append(f'| {app} | {len(x.get(app,{}))} |')
rows+=['',f"Всего улучшены {sum(map(len,x.values()))}/64 региональных комплектов. Прежние слова, удалённые совпадения и новая строка сохранены в c14-keyword-overrides.json.",'',
'## Визуальные замечания по настоящим скриншотам','']
for f in g['visualFindings']:
 rows.append(f"- {f['app']} / {f['device']} / {f['positions']}: {f['issue']} ({f['severity']})")
rows+=['','Покрытие 448/448 означает лишь проверенные PNG/SHA/размеры, а не маркетинговое согласование.','',
'## Релизные условия','']
for key,v in g['requiredBeforeAppStoreMutation'].items():
 rows.append(f"- [{'x' if v['approved'] and v['evidence'] else ' '}] {key}: {v['evidence'] or 'нет подписанного подтверждения'}")
rows+=['','Выпуск заблокирован: проверка --for-release возвращает код 2 до независимого подтверждения каждого условия. Никаких изменений App Store Connect не выполнялось.']
out=R/'core/docs/ASO_C14_KEYWORDS_VISUAL_GATE_2026-10-27.md'
out.write_text('\n'.join(rows)+'\n')
print('generated',out.relative_to(R))
