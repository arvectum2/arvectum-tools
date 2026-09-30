# Passport / ID photo market adaptation — 2026-09-30

## Scope
Goal: expand the existing Russian 35×45 workflow only where an iPhone utility can produce a technically useful file without claiming to replace official biometric checks or a required professional photographer.

The app only crops/resizes/compresses. It does not alter the face or background and does not certify acceptance.

## Enabled presets

### Russia — passport
Existing product preset retained:
- 35×45 mm
- 620×797 px
- 450 DPI
- JPEG

### United States — passport print
Official U.S. passport guidance specifies a 2×2 inch (51×51 mm) printed photo and a head height of 25–35 mm.
Preset:
- 600×600 px
- 300 DPI
- JPEG
- intended as a print-preparation size, not an acceptance guarantee

Official source:
https://travel.state.gov/en/passports/apply/help/photos.html

### United States — visa digital
U.S. Department of State digital visa requirements:
- square image
- 600×600 minimum, 1200×1200 maximum
- JPEG
- maximum 240 KB
Preset:
- 600×600 px
- JPEG
- ≤240 KB

Official source:
https://travel.state.gov/content/travel/en/us-visas/visa-information-resources/photos/digital-image-requirements.html

### India — e-Visa
Government of India e-Visa requirements:
- JPEG
- square image
- 10 KB–1 MB
Preset:
- 900×900 px
- JPEG
- 10 KB–1 MB

Official source:
https://indianvisaonline.gov.in/evisa/tvoa.html

### United Kingdom — passport print
GOV.UK printed passport requirement:
- 35×45 mm
- head height 29–34 mm
Preset:
- 413×531 px
- 300 DPI
- JPEG

For online UK passport applications this preset is intentionally labelled for print only: GOV.UK tells users taking their own digital photo not to crop it because the application handles the crop.

Official sources:
https://www.gov.uk/photos-for-passports/photo-requirements
https://www.gov.uk/photos-for-passports

## Investigated but not enabled

### Canada — passport
Not enabled. Canada requires 50×70 mm photos to be taken in person by a commercial photographer/photo studio, professionally printed, and says the original photo must not be altered or edited.

Official source:
https://www.canada.ca/en/immigration-refugees-citizenship/services/canadian-passports/photos.html

### Australia — passport
Not enabled. The Australian Passport Office specifies a range of 35–40 mm × 45–50 mm, requires professional-quality printed output, and explicitly says it does not recommend online passport photo services or mobile apps.

Official source:
https://www.passports.gov.au/passports-explained/how-apply/passport-photo-guidelines

### Australia — citizenship / visa uploads
Potential later preset. Australian Home Affairs accepts digital photographs for some online workflows and provides file-size/resolution guidance, but also recommends professional providers and warns against edited/manipulated images. Keep out of the passport preset until the exact document workflow is selected.

Official sources:
https://immi.homeaffairs.gov.au/citizenship/photo-requirements-for-citizenship-applications
https://immi.homeaffairs.gov.au/help-support/applying-online-or-on-paper/online/attach-documents-to-your-application

## Product decision
Initial international rollout targets Russia + English-language/self-service-compatible workflows:
1. Russia passport
2. U.S. passport print
3. U.S. visa digital
4. India e-Visa
5. UK passport print

Canada and Australia passport modes are deliberately excluded rather than presenting a misleading one-tap compliance claim.

## Competitive signal
Current App Store search results show active competitors centered on:
- multi-country presets;
- US 2×2;
- visa-specific digital output;
- India e-Visa;
- print-sheet generation;
- face-position/compliance guidance.

The useful differentiation for Arvectum should remain:
- local-first processing;
- transparent technical specs;
- no fake “guaranteed acceptance” promise;
- no face/background manipulation by default;
- simple document-specific presets.
