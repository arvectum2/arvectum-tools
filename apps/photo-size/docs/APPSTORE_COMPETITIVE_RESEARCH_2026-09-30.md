# App Store competitive / semantic-search research — 2026-09-30

## Scope

Reviewed current App Store results around the core jobs of «Фото под размер»:

- compress photo to an exact KB/MB limit;
- resize image dimensions;
- prepare passport / visa / ID photos;
- save/share a technically compliant result.

The sample includes both Russian-store listings and current U.S. listings, plus apps surfaced in Apple's “You Might Also Like” related-results block.

## Representative competitors

| App | Market signal | Strong mechanics | Weakness / overload risk |
| --- | --- | --- | --- |
| Image Resizer: Resize Photo | Exact KB/MB, 100+ batch, passport/social presets, EXIF cleaner, Siri/Spotlight | Exact dimensions, target size, Files integration, format conversion, privacy controls | Very broad feature set; social presets and power-user tools can bury the primary job |
| Image Compress Photo & Video | 4.7/5, 95 ratings; claims 2M users | Before/after comparison, target size, batch, save settings, metadata control, on-device positioning | Photo+video scope is much broader than Arvectum's one-job utility |
| Passport Photo Maker & Editor | 4.8/5, 474 ratings | Simple guided passport workflow, print sheets, camera/gallery/iCloud, crop/position | Background replacement and “compliance” language create correctness/liability risk |
| Фото на документы | 4.5/5, ~2.5K ratings in RU store | 100-country templates, head-position controls, print/save | Dense country/template UX; narrower document-only product |
| Простое сжатие фото | 4.8/5, 29 ratings in RU store | Simple compression/resize positioning | Less differentiated; mostly generic compression |
| Размер изображения - сжатие | RU + 20 languages | Preview, quality/size inspection, send to other apps, JPEG/PNG export | Older utilitarian UX and broader settings surface |
| Сжать фото / ShrinkPic | RU store | Exact target size, batch, on-device processing, before/after savings | Storage-cleanup positioning competes with the upload-form job |

## Repeated feature signals

### Strongly validated
1. Exact target file size in KB/MB.
2. Exact pixel resizing.
3. Clear before/after result preview.
4. Local/on-device processing as a trust message.
5. Save/share result immediately.
6. Input from both Photos and Files/iCloud.
7. Document-specific presets instead of one global passport size.

### Valuable, but second wave
1. Format conversion (HEIC/JPEG/PNG).
2. Optional EXIF/GPS stripping.
3. Batch processing.
4. Print sheets for document photos.
5. Remember last settings / quick repeat.
6. Exact width × height rather than only long-side resize.

### Deliberately not copied now
1. AI face retouching.
2. Automatic background replacement.
3. Generic “100% compliant / guaranteed acceptance” claims.
4. Social-media preset catalogs.
5. Video compression.
6. Storage-cleaner flows and deletion of originals.
7. Subscription-heavy editing suites.

These features either dilute the core job or create a misleading compliance promise.

## Reviews / pain signals

- Saving must be absolutely reliable: an App Store review for Image Resizer explicitly complained that files could not be saved; its developer later highlighted save-path fixes.
- Print sheets are a real document-photo need: Passport Photo Maker & Editor received a review asking for multiple photos per sheet, and the developer subsequently added it.
- Users value a short workflow: positive passport-app reviews explicitly praise speed and interface simplicity.
- Layout quality matters: competitors have shipped repeated updates specifically for button layout and modern iPhone compatibility.

## Product positioning decision

«Фото под размер» should stay a compact utility rather than become a general photo editor.

Core positioning:
- exact KB/MB and dimensions;
- document/visa presets where an app can truthfully prepare the technical file;
- local-first photo processing;
- transparent limits and no false acceptance guarantee;
- minimal taps;
- immediate visual proof of the result.

## Prioritized product actions

### P0 — do now
- [x] Exact target KB/MB.
- [x] Long-side pixel resize.
- [x] International document presets.
- [x] Add before/after result preview with source/result sizes.
- [x] Rebuild App Store screenshots around visible before/after proof.
- [x] Refresh RU/EN App Store metadata to match the current feature set and ads.

### P1 — next product iteration
- [x] Import from Files/iCloud in addition to Photos.
- [ ] Exact width × height mode with aspect-ratio lock.
- [ ] Output format selector: JPEG / PNG / HEIC where technically appropriate.
- [ ] Optional metadata/EXIF/GPS removal.
- [ ] Print-sheet export for print document presets.

### P2 — only after usage data
- [ ] Batch processing.
- [ ] Remember/reuse last settings.
- [ ] Siri / Shortcuts entry points.

## Source set

- https://apps.apple.com/us/app/image-resizer-resize-photo/id1025334396
- https://apps.apple.com/us/app/image-compress-photo-video/id1153379683
- https://apps.apple.com/us/app/passport-photo-maker-editor/id6449979104
- https://apps.apple.com/ru/app/фото-на-документы/id759142884
- https://apps.apple.com/ru/app/простое-сжатие-фото/id1538830649
- https://apps.apple.com/ru/app/размер-изображения-сжатие/id1347605620
- https://apps.apple.com/ru/app/сжать-фото/id6758235953
