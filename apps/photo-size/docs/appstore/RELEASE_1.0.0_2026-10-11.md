# Фото и PDF под размер — iOS App Store release 1.0.0

**Evidence captured:** 2026-10-11 from authenticated App Store Connect in Safari on Mac mini via Accessibility.

## Confirmed distribution identity

| Field | Value |
| --- | --- |
| Product | Фото и PDF под размер |
| Apple App ID | 6816346084 |
| Bundle ID | `ru.arvectum.tools.tosize` |
| Marketing version | **1.0.0** |
| Uploaded build | **12** |
| Build detail binary state | Validated |
| App Store Connect status | **Ready for Distribution** |
| Owner-confirmed public release | 2026-10-11 |
| Uploaded | 2026-10-10 4:02 PM (App Store Connect UI time; timezone not verified) |
| Ready for Distribution | 2026-10-11 2:21 AM (App Store Connect UI time; timezone not verified) |
| In Review | 2026-10-11 12:17 AM (App Store Connect UI time; timezone not verified) |
| Waiting for Review | 2026-10-10 4:05 PM (App Store Connect UI time; timezone not verified) |
| Uploaded file as listed by Apple | `309bf092-e68b-4940-9f96-1f056c3ca0c9.ipa` |
| Minimum iOS | 17.0 |
| Supported family | iPhone |
| Languages | English, Russian |
| Compressed binary size | 10.8 MB |

App Store Connect history additionally shows a **Developer Rejected** state at 2026-10-10 3:54 PM, followed by a new submission. This is a developer-side withdrawal, **not** an Apple review rejection.

Source of status: authenticated App Store Connect dashboard, app version page, build metadata page and History page. Public App Store listing: https://apps.apple.com/ru/app/id6816346084

## Source provenance — unresolved, do not invent a tag

The canonical repository `/Volumes/ArvectumSSD/Arvectum/repos/arvectum-tools` at this audit has `MARKETING_VERSION = 0.6.2` and `CURRENT_PROJECT_VERSION = 10` in `apps/photo-size/ios/project.yml`. The last locally retained PhotoPodRazmer device Release app in Xcode DerivedData is also `0.6.2 (10)`, timestamped October 7. Mac mini's standard Xcode Archives directory has no PhotoPodRazmer 1.0.0 archive; a limited inspection of the connected MacBook Air's Xcode Archives, Desktop, Downloads and Documents also found none.

**Consequently no verified source commit, local archive or reproducible build is linked to the uploaded 1.0.0 (12) binary.** Do not create a misleading `v1.0.0` source tag or rewrite the checked-in release version as if current sources were proven to be the uploaded build.

## Follow-ups

- [x] Verify 1.0.0 Ready for Distribution directly in authenticated App Store Connect.
- [x] Verify 1.0.0 build **12** and Apple upload/review/distribution timestamps.
- [x] Record the difference versus the source-controlled 0.6.2 (10) baseline.
- [ ] Locate or reconstruct the **exact** sources and export/archive for uploaded 1.0.0 (12), then attach a provenance commit/tag with reproducible evidence.
- [ ] Verify RU storefront propagation: Apple public iTunes lookup returned 0.6.2 on 2026-10-11 while Connect had 1.0.0 Ready for Distribution.
- [ ] Validate the published build on a physical device for photo/PDF regression and monetization.
