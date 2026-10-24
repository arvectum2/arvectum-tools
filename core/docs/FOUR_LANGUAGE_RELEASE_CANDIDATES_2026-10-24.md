# Ухват 1.1.1(9) и ChickMark 1.5.1(19) — реальные 4-язычные кандидаты

**24.10.2026, Mac mini:** Release ARCHIVE SUCCEEDED и подписанный
EXPORT SUCCEEDED по обоим приложениям. НЕ загружены в App Store Connect:
согласно AGENTS.md требуется новое явное разрешение на каждую отправку.
Текущие публичные версии по последнему Apple API: 1.1.0(8) и 1.5.0(18).

## Подписанные бинарники

| Приложение | Версия/build | Размер (байт) | SHA-256 |
| --- | --- | ---: | --- |
| Ухват | 1.1.1(9) | 4 856 892 | cab8fdb8c077575eca0bd2a8d350a91c299fa2754b65d78c85f86d0bdb23e26a |
| ChickMark | 1.5.1(19) | 13 017 108 | ec02563eb04accf44b6324eb15e780cad164cea18cc240fe0eb387511e42b162 |

- Ухват: IPA ru.arvectum.tools.what, iPhone + Widget + Watch + complication;
  во всех четырёх реально en/es/fr/ru Localizable.strings, одинаковая
  маркетинговая версия и build; французские permission strings есть в IPA.
- ChickMark: IPA ru.arvectum.tools.habits, iPhone + Widget + Watch + Watch
  Widget, те же четыре языка и версия 1.5.1(19) в каждом bundle;
  французские App Shortcuts находятся в архиве.
- Проверка распакованных IPA codesign --verify --deep --strict PASS.
- PR #138 Uhvat (source 08bdd43, merge 93ed563) и PR #139 ChickMark
  (source d17e2f7, merge 4f47e5b) слиты в main.
- Каталоги портфеля и 33 Python-теста PASS; release hygiene ChickMark PASS.
  CI обоих PR содержал внешние сетевые ошибки загрузки бинарников
  Yandex Ads/Tapjoy, повторные задания запущены; это не Swift failure.
  Не считать полный CI зелёным без итогового подтверждения GitHub.
- Физическая миграция установленных личных приложений не тестировалась
  и пользовательские записи/привычки не изменялись.

## Файлы и независимое свидетельство на Mac mini

/Volumes/ArvectumSSD/Arvectum/releases/four-locales-20261024/

- uhvat/export/WhatIOS.ipa
- chickmark/export/HabitsByArvectum.ipa
- FOUR_LOCALE_IPA_ATTESTATION.json — JSON по восьми app-owned bundle;
  включает sha256, номера билдов и языки.
- metadata/uhvat-release-metadata-draft.json — тексты es-ES, fr-FR,
  обновление RU/EN.
- metadata/chickmark-release-metadata-draft.json — тексты fr-FR,
  обновление RU/EN/ES-ES/ES-MX.
  Черновики локальные: App Store Connect ими ещё не изменён.
- Архивы .xcarchive, экспортные логи и параметры подписи рядом.

## Дальше по релизному gate

- [x] Четыре языка реально входят в iPhone, Watch, Widgets;
  оригинальные bundle ID и группы данных не меняются.
- [x] Xcode signed IPA, codesign, checksum подтверждены.
- [x] Source PR merged в main.
- [ ] Получить отдельное разрешение владельца отправить точно Ухват
  1.1.1(9) и ChickMark 1.5.1(19) в App Store Connect и App Review.
- [ ] После разрешения создать карточки, перенести RU/EN/ES, добавить
  испанский/французский магазинные локали, согласовать screenshots,
  App Privacy и review details; у ChickMark изменить primary category
  на Productivity в редактируемой версии.
- [ ] Провести ASC preflight; загрузить только эти SHA-256; Review Submit,
  releaseType AFTER_APPROVAL; после Apple approval проверить витрины.
