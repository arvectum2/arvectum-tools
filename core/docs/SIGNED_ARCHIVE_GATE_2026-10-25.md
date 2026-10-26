# Signed archive gate — 2026-10-25

## Обновление 26.10.2026

Этот документ сохраняет **исторический** blocker на 25.10. На 26.10 локальный сертификат Distribution и Store provisioning всех четырёх приложений и расширений найдены: 4/4 `.xcarchive` + 4/4 IPA export/подписи PASS. Сборки являются QA-артефактами со **старыми** версиями/build numbers и не готовы к загрузке.

[Текущий подписанный QA отчёт](IOS_SIGNED_IPA_GATE_2026-10-26.md).


Release candidate source: `feature/portfolio-roadmaps-zh-hant-20261025` at `b68ac42`.

## Confirmed

- Photo/PDF: device archive PASS (manual signing); App Store IPA export PASS.
- Local path: `/tmp/arvectum-photo-export-20261025/PhotoPodRazmer.ipa`.
- SHA-256: `b4644b745ff311cc4803414ccd1618ec5bca13dd445ed4dee26081dcda4a66b5`.
- Distribution signing identity available: Apple Distribution, LLC ARVECTUM, team VML75VY94V.

## Remaining archive blockers

- Pushkin: missing provisioning profile for `ArvectumNotify` target.
- What/Uhvat: missing profiles for `WhatIOS`, `WhatWatch`, `WhatPhoneWidget`, `WhatWatchComplication`.
- ChickMark: missing capability-bearing profiles for iOS, Watch and widget targets (App Groups, HealthKit, iCloud, Push Notifications as applicable).
- Manual signing used to avoid automatic Apple Developer account mutations. No Apple upload or provisioning changes attempted.
- Logs: `/tmp/arvectum-{pushkin,what,chickmark}-archive.log`; photo `/tmp/arvectum-photo-archive3.log` and `/tmp/arvectum-photo-export.log`.

Do not upload until specific version/build/hash approval, editorial and real-device acceptance.
