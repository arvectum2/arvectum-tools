# App Store ASO — global rollout (DRAFT, 2026-10-10)

**Product:** Arvectum Tools — «Фото и PDF под размер» · App Store ID `6816346084` · bundle `ru.arvectum.tools.tosize`.

**Release gate: HOLD.** These changes are **not in App Store Connect** and have **not been published**. Keep them in the `feature/photo-pdf-global-aso` branch and combine with the upcoming code refactor. Do not submit for review or update live metadata without the owner's explicit decision.

## Delivered

- `metadata-2026-10-10.json`: 20 App Store **locales**, including market-adapted name, subtitle, promotional text, keywords, description, privacy-policy link and three screenshot headlines.
- `validate.py`: validates every locale for limits (name/subtitle 30 chars, promotional text 170 chars, description 4000 chars, keywords **100 UTF-8 bytes**).
- `generate_screenshots.swift`: renders **60 draft 1320×2868 JPEG screenshots** from actual app UI, replacing the top marketing headline without altering the UI; crops the original in-app ad content, includes real before/after evidence where available.
- `store-assets/appstore/aso/<locale>/iphone-6.9/`: 3 localized frames per locale; only the largest iPhone size is prepared, which App Store Connect can scale down.
- A companion website branch `feature/photo-size-global-seo` contains country-oriented landing pages and PDF intent pages. Nothing is deployed.

## Locales and initial rollout priorities

| Stage | App Store locales | Markets / reasoning |
|---|---|---|
| P0, launch with refactor | `ru`, `en-US`, `en-GB`, `es-MX`, `es-ES`, `pt-BR`, `de-DE`, `fr-FR` | Russian baseline, English global reach, Mexico/LatAm and Spain, Brazil, Germany, France. |
| P1 | `en-AU`, `en-CA`, `pt-PT`, `it`, `hi`, `tr`, `id` | Country-specific English, Portugal/Italy, India, Turkey, Indonesia. |
| P2 | `pl`, `ja`, `ko`, `uk`, `vi` | Additional indexed locales; review actual app-language support and market impressions first. |

**Important:** App Store metadata localization ≠ in-app UI localization. The current UI screenshot sources are Russian and English. Non-RU/EN screenshots have a localized headline but English app UI. For a polished release, localize the actual UI to P0 languages **during the refactor**, or explicitly choose to ship English UI to those countries. Do not advertise a fully translated app until it is implemented.

**India:** Apple supports an English (UK) listing and a distinct Hindi metadata localization; there is no `en-IN` App Store Connect locale. Country eligibility and locale selection are managed by Apple.

## ASO search intent and positioning

| Cluster | Query/problem | Destination |
|---|---|---|
| Photo file-size constraints | photo to 100kb, compress photo to 1mb, reduce image file size | Name/subtitle/keywords + screenshot 1 |
| PDF upload limits | compress pdf to 1mb, shrink pdf, pdf 500kb | Name + description + dedicated web pages; **new PDF screenshot needed** |
| Exact image dimensions | resize photo in pixels, image width height, jpg pixel size | Subtitle/keywords + screenshot 2 |
| Document uploads | passport photo size, visa photo kb, photo for online form | Description + screenshot 3, no eligibility or acceptance guarantee |
| Privacy | offline image compression, on-device pdf processing | Descriptions and localized website copy (clarify ads use internet) |

Apple search primarily uses **name, subtitle and keyword field**; promotional text does not improve keyword indexing. The description is important for comprehension and search-engine exposure. Avoid keyword stuffing, trademarked competitors, and redundant keywords already in title/subtitle.

## Screenshot order and next design pass

Current draft: 1) photo compressed to a specific KB target, 2) exact pixel dimensions, 3) document presets. Each uses an **actual screenshot**. The current first two sources show a before/after photo comparison. Do not present the draft as a finalized visual pack.

**Before release after refactor, add a genuine PDF-mode screen** and test two first-screen sequences:
- Set A: **Photo KB → PDF KB → Pixels → Documents**
- Set B: **PDF KB → Photo KB → Pixels → Documents**

Do not invent or photoshop a PDF UI. Capture a running build from a simulator/real device and regenerate the final locale graphics. Verify cropping and right-to-left scripts if Arabic is ever added. Final image order can be tested later with Product Page Optimization; with just 22 initial downloads, the experiment probably cannot produce reliable statistical conclusions yet.

## Release checklist (not done)

- [x] Verify current app is public: 0.6.2 READY_FOR_SALE (checked 2026-10-10).
- [x] Create isolated staging branches and metadata pack.
- [x] Validate 20 localized metadata records and 60 screenshot dimensions.
- [x] Draft localized web pages and multilingual canonical/hreflang metadata.
- [ ] Complete code refactor and freeze the feature set.
- [ ] Verify all claims against new running build: PDF compression, file-size behavior, pixel dimensions, export formats, document presets, local processing, ad disclosures.
- [ ] Capture true PDF-mode UI and re-export screenshots at 1320×2868 for all approved locales.
- [ ] Verify native app interface copy for languages chosen for release; get human review for professional translations where appropriate.
- [ ] Confirm screenshots meet current Apple device requirements and avoid screenshots that differ from submitted app binary.
- [ ] Create the **next** App Store Connect version draft, and only then populate names/subtitles/version-localized metadata and upload assets.
- [ ] Verify every locale in App Store Connect via read-only API inspection; do not change promotional text on a live version by mistake.
- [ ] Test the new build + localized UI on at least one device.
- [ ] **STOP for approval** before any App Review submission, public site deploy, or release.
- [ ] After an approved release, run 2- and 4-week cohort analysis.

## Measurement / organic marketing plan

Record before/after by App Store storefront: impressions, product-page views, first-time downloads, page-to-download conversion, source (search, browse, web referrer), crash-free sessions, ratings and ad revenue. The known baseline is **22 downloads as reported 2026-10-10**, not a reliable source-by-country conversion dataset. Choose focus geos from **actual Analytics data** after the next release, not just population.

Free distribution after approval:
1. Localized landing pages for global “photo to 100KB / PDF to 1MB” intents, with App Store download CTA and proper `hreflang`.
2. Search Console + Yandex Webmaster indexing only once the site deploy is approved.
3. Helpful posts on relevant forums explaining file-size limitations and the free iPhone workflow, respecting each community's promotion rules.
4. A genuine review prompt **after a successful save**, with throttling, if implemented in a separate code sprint. Never buy/incentivize reviews.
5. Test CPP pages for PDF and document-photo niches only when there is enough traffic to make the results meaningful; never publish an experiment automatically.

## Sources / policy references

- [App Store product page](https://developer.apple.com/app-store/product-page/)
- [App metadata limits](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Localization support](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations)
- [Apple screenshots](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [App Store search](https://developer.apple.com/app-store/search/)

**No App Store API POST/PATCH/DELETE, no binary upload, no review submission, no production web deploy in this workstream.**
