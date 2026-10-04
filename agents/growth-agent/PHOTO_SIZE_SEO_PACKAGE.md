# SEO package — Фото под размер

Prepared: 2026-10-04
State: ready to integrate into arvectum.com source/deploy workflow.

## Architecture
Hub: /tools/photo-size/
Intent pages:
- /tools/photo-size/compress-to-kb/
- /tools/photo-size/resize-pixels/
- /tools/photo-size/35x45/

All pages should cross-link to the hub and only to genuinely related intents. Add the App Store CTA after the app is available.

## Hub
Title: Фото под размер — сжать фото до КБ/МБ или изменить размер в пикселях
Description: Бесплатная утилита для iPhone: уменьшить фото до нужного веса файла или размера в пикселях. Обработка локально на устройстве.
H1: Фото под размер
Lead: Когда сайт, анкета или письмо требует конкретный вес файла или размер изображения, задайте лимит и получите готовый результат без ручного перебора качества.

Sections:
1. Уменьшить фото до заданного веса
2. Изменить размер в пикселях
3. Подготовить технический файл 35×45
4. Фото обрабатываются на iPhone
5. FAQ

## Intent: compress-to-kb
Title: Как уменьшить фото до 1 МБ, 500 КБ или другого размера на iPhone
Description: Уменьшение фотографии до заданного лимита в КБ или МБ на iPhone. Без загрузки фотографии на сторонний сервер.
H1: Как уменьшить фото до нужного размера в КБ или МБ
Primary query family: уменьшить фото до 1 мб; сжать фото до 500 кб; уменьшить вес фото; фото до нужного размера файла.
Key answer: choose the maximum file size; the app adjusts output and verifies it does not exceed the selected limit.
Privacy angle: useful for document images because processing stays on device.
FAQ:
- Как уменьшить фото до 1 МБ на iPhone?
- Можно ли задать 500 КБ?
- Нужно ли вручную менять качество JPEG?
- Загружается ли фотография на сервер?

## Intent: resize-pixels
Title: Как изменить размер фото в пикселях на iPhone
Description: Измените длинную сторону фотографии до нужного количества пикселей с сохранением пропорций.
H1: Изменить размер фотографии в пикселях на iPhone
Primary query family: изменить размер фото в пикселях; уменьшить разрешение фото; resize image iphone.
Important limitation: current product uses long-side sizing; do not claim arbitrary exact width × height cropping.

## Intent: 35x45
Title: Как подготовить фото 35×45 на iPhone — технический размер файла
Description: Кадрирование 35×45 и техническая подготовка JPEG на iPhone. Без изменения лица и без обещания соответствия требованиям конкретного ведомства.
H1: Подготовить технический файл фото 35×45
Primary query family: фото 35x45; размер фото на паспорт; фото на документы iphone.
Mandatory disclaimer: the tool prepares technical file parameters only. It does not verify pose, face, background, biometric requirements or acceptance by an authority.

## Structured data
Use SoftwareApplication on hub after public App Store availability.
Use FAQPage only for FAQs visibly present on the page and only if consistent with current search-engine eligibility guidance.
Do not fabricate AggregateRating.

## Internal linking
Add a lightweight Arvectum Tools entry point from the main site rather than mixing consumer utilities into procurement-service navigation.
Hub links to all 3 intents.
Each intent links back to hub and one adjacent relevant intent.

## Launch checklist
- create pages
- canonical URLs
- RU language metadata
- sitemap entries
- robots indexable
- Open Graph metadata
- App Store CTA after availability
- campaign-tagged App Store link once Analytics campaigns are enabled
- submit sitemap/search indexing through existing webmaster tooling if connected
- measure Search Console/Bing/Yandex equivalents where available
