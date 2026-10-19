# Фото и PDF под размер — физический iPhone, четыре поворота PDF

**19.10.2026 — PASS.** Физический iPhone 13, iOS 27.0.1, только изолированный QA bundle ru.arvectum.tools.tosize.physicalqa, QA version 1.0.1(13). Это не означает новый App Store релиз.

**Тестовый документ:** полностью синтетический PDF 2 999 791 байт, четыре разные шумовые картинки, повороты страниц 0°, 90°, 180°, 270° (проверены исходным PDFKit). SHA-256 входа: 0fbbbd1cbc57031b56d436a3947f33b898bddc6935de2b8dd1f8f4484ef19ea4.

1. Резервные копии трёх прежних QA файлов сделаны на ArvectumSSD. Никакие личные Files/Photos/App Store контейнеры не читались и не изменялись.
2. Синтетический PDF передан в приватный Documents QA-приложения, запущен DEBUG-only режим --qa-physical-pdf-roundtrip, который вызывает настоящий PDFEngine.inspect и compressByBytes(max=500000).
3. Прочитанный из QA-контейнера JSON: status=passed, alreadyFit=false, inputPages=4, outputPages=4, inputBytes=2999791, outputBytes=464545. Выходной SHA-256: 6dbadfeb9bd7380aa8fa01d4728935638b83eeffb86d9bce65c4f801febc3bb2.
4. Независимый Poppler pdftoppm на Mac mini прорендерил вход и результат постранично; совпали все размеры и ориентации p1 219×300, p2 300×219, p3 219×300, p4 300×219. Нормализованная корреляция изображений после подавления высокочастотного шума: **0.99604, 0.99807, 0.99257, 0.99955**. Содержимое/ориентация сохранены у всех четырёх страниц.
5. Все три изначальных QA файла восстановлены на iPhone, снова скопированы на Mac и независимо проверены SHA-256 — байты идентичны бэкапам.

**Закрыто:** 4-страничное уменьшение с поворотами до 500 КБ на физическом iPhone; ранее отдельно пройден полный физический Files picker → fileExporter → повторный импорт (см. SYSTEM_FILE_EXPORT_QA_2026-10-18.md). Это два разных теста, не один combined UI.

**Открыто:** Photos picker с разрешением/отказом; HEIC/EXIF; разные системные расположения Files; повторные имена; native/banner РСЯ no-fill/consent; реальная публикация 1.0.2(14). Ни одного Apple upload или изменения пользовательских файлов не делалось.

QA evidence: /Volumes/ArvectumSSD/Arvectum/tmp/photo-rotated-physical-20261019/ — исходник/выход, FOUR_ROTATIONS_DEVICE_RESULT.json, verified-orientation-correlation.json, previous-qa и рендеры. Бинарные файлы не загружаются в Git.
