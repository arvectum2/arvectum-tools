# 26.10.2026 — нативная PT-PT/KO приёмка (ARC, Mac mini)

Xcode 27.1, независимые iPhone 18 Pro Simulator iOS 27.0, `CODE_SIGNING_ALLOWED=NO`. Тестовые локальные фикстуры, реальные Shortcut/HealthKit/CloudKit и личные данные не изменялись.

| Приложение | PT-PT UI | KO UI |
|---|---|---|
| Фото/PDF | **3/3 PASS** | **3/3 PASS** |
| Pushkin | **1/1 PASS** | **1/1 PASS (после исправления)** |
| Ухват | **1/1 PASS** | KO не создан |
| ChickMark | **1/1 PASS** | KO не создан |
| **Итого** | **6/6** | **4/4** |

Всего **10/10 XCUITest PASS** после исправления; дополнительно **1/1 Swift unit Pushkin KO PASS** и **63/63 Core Python PASS**. В первоначальном Pushkin KO прогоне **FAIL** (вкладка `기록` не появилась): `PushkinCopy.text` не маршрутизировал `ko`, хотя файл был. Добавлены ветка `ko`, корейский `N개 앱` и unit-регресс; повторный нативный UI-прогон успешен.

Сырые журналы и `.xcresult` (Mac mini): `/Volumes/ArvectumSSD/Arvectum/qa/`
- `ios-ptpt-ko-native-20261026/photo.{log,xcresult}` — Фото/PDF 6/6
- `ios-ptpt-ko-native-20261026/pushkin.{log,xcresult}` — Pushkin PT-PT 1/1, первичный KO FAIL (код 65); **не суммировать этот FAIL как PASS**
- `ios-korean-pushkin-fixed-20261026/pushkin-fixed.{log,xcresult}` — Pushkin KO unit и UI PASS
- `ios-ptpt-ko-recovery-20261026/{what,chickmark}.{log,xcresult}` — по 1/1 PT-PT PASS

Автоматизированный редакторский аудит: 182 файла/9484 ключей вне EN, 0 региональных флагов PT-PT; 31 совпадение EN зарегистрировано в `core/localization/english-identical-exceptions.json`, 0 неразобранных. Это **лексическая классификация**, не проверка носителем.

**Открытые блокеры:** KO в Ухвате/ChickMark; носители языков и физический Watch/iPhone/VoiceOver/consent/upgrade; полная ручная GitHub UI matrix; provisioning для подписанных релизов. Новые IPA/App Store Connect/TestFlight/Review не отправлялись; по `AGENTS.md` нужен отдельный per-version/build/hash approval.

## Подписанный артефактный preflight 26.10

Независимо от вышеописанной нативной QA созданы 4/4 device xcarchive и 4/4 локально подписанных IPA (Apple Distribution), проверенных по SHA-256. Это **не новые** App Store версии, ни один IPA не загружен в Apple. Подробности и текущие блокеры — [signed IPA gate](IOS_SIGNED_IPA_GATE_2026-10-26.md).
