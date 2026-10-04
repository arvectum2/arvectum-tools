# Organic launch pack — Фото под размер

Status: draft for next editable App Store version
Date: 2026-10-04

## Positioning
Core job: make an image satisfy a technical size requirement without trial and error.
Primary intent: target file weight (KB/MB).
Secondary: pixel dimensions.
Tertiary: technical 35x45 document file.

## RU metadata
Name: Фото под размер
Subtitle A (recommended): Сжать фото до КБ и пикселей
Subtitle B: Сжатие фото: КБ, МБ, пиксели
Keywords draft: уменьшить,вес,мб,кб,пиксели,ресайз,паспорт,35x45,документы

Promotional text:
Уменьшите фото до нужного веса в КБ/МБ или размера в пикселях без ручного подбора качества. Также можно подготовить технический файл 35×45. Обработка — на iPhone.

## EN metadata
Name: Photo to Size
Subtitle: Compress & Resize Photos
Keywords draft: compress,resize,kb,mb,pixels,file,size,passport,35x45,image

Promotional text:
Make a photo fit a file-size limit in KB/MB or exact pixel dimensions without trial and error. Includes technical 35×45 preparation. Processing stays on iPhone.

## Screenshot hierarchy
1. Need it under 1 MB? / Фото должно быть меньше 1 МБ?
   Visual: input image → 1 MB target → successful result.
2. Need exact pixels? / Нужен точный размер в пикселях?
   Visual: long-side selector → resulting dimensions.
3. Need a 35×45 file? / Нужен файл 35×45?
   Visual: crop + technical output. Do not imply biometric or official compliance.

## Custom Product Page concepts
CPP-WEIGHT — exact file weight
Headline: Фото до нужного веса
Support: 100 КБ, 500 КБ, 1 МБ или свой лимит — без ручного перебора качества.
Primary audiences: upload forms, email attachments, portals.

CPP-PIXELS — pixel resize
Headline: Точный размер в пикселях
Support: Задайте длинную сторону — пропорции сохранятся автоматически.
Primary audiences: websites, profiles, forms.

CPP-35X45 — technical document file
Headline: Технический файл 35×45
Support: Кадрирование и параметры JPEG для документа. Без изменения лица и без обещания официального соответствия.
Primary audiences: document preparation.

Note: CPP creation is gated until the app is Ready for Distribution (or can be included with a first-version submission before approval). Prepare assets now; submit at the appropriate state.

## Campaign taxonomy
Apple campaign tokens are created only after Analytics has app data. Reserve these names:
- seo_ru_weight
- seo_ru_pixels
- seo_ru_35x45
- reddit_weight
- reddit_pixels
- telegram_owned
- vk_owned
- shorts_weight
- crosspromo_pushkin
- crosspromo_chickmark

Rules:
- one intent + one channel per token;
- never reuse a token for materially different creative;
- preserve token names in the Growth Agent opportunity record;
- wait for App Store Connect Analytics eligibility before generating actual links.

## Measurement
Baseline after release:
- impressions
- product page views
- first-time downloads
- conversion rate
- source type / web referrer
- campaign
- product page
- retention where thresholds permit

## Safety
No guaranteed passport acceptance.
No biometric compliance claim.
No background-removal claim.
No “no ads” claim once the ad-supported build ships.
