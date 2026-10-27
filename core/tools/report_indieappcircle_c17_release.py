#!/usr/bin/env python3
"""Generate local release preflight from four signed IPA hash records (no ASC writes)."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
src=json.loads((ROOT/'core/docs/INDIEAPPCIRCLE_C17_SIGNED_RELEASE_MANIFEST.json').read_text())
assert src['stage']=='SIGNED_QA_NOT_UPLOADED'
apps={'photo':('Фото/PDF','6816346084',3),
      'pushkin':('Pushkin','6817847111',4),
      'what':('Ухват','6822476399',4),
      'chickmark':('ChickMark','6818711298',5)}
lines=['# C17 — Indie App Circle: подписанные кандидаты на релиз, 27.10.2026',
       '', '**Все IPA проверены и подписаны локально, но не отправлены в Apple.**',
       '', '| Приложение | Apple ID | Новая версия | SHA-256 IPA | Доступных ASC локалей |',
       '| --- | --- | --- | --- | ---: |']
for key,(title,app_id,locale_count) in apps.items():
    a=src['apps'][key]
    lines.append(f"| {title} | {app_id} | {a['version']} ({a['build']}) | {a['sha256']} | {locale_count}/16 |")
lines.extend(['',
'IPA лежат на Mac mini: /Volumes/ArvectumSSD/Arvectum/qa/indieappcircle-release-candidates-20261027/export-PRODUCT/. Файлы не должны попадать в публичный Git.',
'',
'## Изменения продукта',
'',
'- ChickMark: собственные группы прямо в форме новой привычки без миграции данных.',
'- Pushkin: международные приложения из проверенного существующего каталога появляются первыми.',
'- Ухват: подсказка о расшифровке аудио на 12 языках, privacy manifests в iOS/Watch/widget/complication.',
'- Фото/PDF: понятная стрелка возврата после результата.',
'- Для 4 приложений готовы 64 What’s New, 448 нативных региональных PNG и 144 iPad маркетинговых JPEG.',
'',
'## Результаты',
'',
'- Все 4 Apple Distribution IPA проверены codesign --verify --deep --strict, версии вложенных bundles и их privacy manifests совпадают.',
'- 85 Core Python tests, новые UI тесты ChickMark и Pushkin, локализационный аудит PASS.',
'- ASC read-only: все текущие версии READY_FOR_SALE, а локалей там только 3–5, не 16.',
'',
'## Незакрытые релизные ограничения',
'',
'- [ ] P0 Photo/PDF App Privacy: YandexMobileAds / AppMetrica содержат встроенные privacy manifests с рекламными идентификаторами, coarse location и tracking. Прежде чем менять анкеты Apple, подтвердить фактическую передачу данных и текущие ответы ASC.',
'- [ ] Авторизованная сверка новых локалей, экранов, App Privacy и Accessibility на конкретной редактируемой версии.',
'- [ ] Неизменяющие личные данные физические iPhone/iPad/Watch тесты нового подписанного релиза.',
'- [ ] Явное разрешение владельца на каждый из 4 точных version/build/SHA256 и на согласованные ASC метаданные. General consent не является подписью release gate.',
'- [ ] После разрешения выставить AFTER_APPROVAL, загрузить конкретные IPA и отправить на App Review.',
'',
'См. INDIEAPPCIRCLE_FEEDBACK_2026-10-27.md и INDIEAPPCIRCLE_APP_PRIVACY_AUDIT_2026-10-27.md.'])
out=ROOT/'core/docs/INDIEAPPCIRCLE_C17_RELEASE_PREFLIGHT_2026-10-27.md'
out.write_text('\n'.join(lines)+'\n')
print('RELEASE_PREFLIGHT_CREATED',out,len(src['apps']))
