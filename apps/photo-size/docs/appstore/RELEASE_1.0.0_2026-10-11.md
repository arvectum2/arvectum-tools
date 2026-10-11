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

## Source provenance — recovered 2026-10-11

The original signed release was located in a separate local Git worktree that had not been merged into the canonical ArvectumSSD repository:

- Original worktree: `/Users/master/arvectum-tools-aso`
- Original branch: `release/photo-pdf-1.0.0`
- **Build-12 source commit:** `0346d7579b8795408788e9cb4037de05d76f9d44` (includes memory-safe PDF engine)
- Final release documentation commit: `ca034b131099dea4d61824b9df9f484ce2360382`
- Matching Apple build ID in the local submission record: `825a5b4d-53f7-480f-8eb7-22f0f2d98cc6`
- Local exported IPA: `PhotoPodRazmer.ipa`, `CFBundleShortVersionString=1.0.0`, `CFBundleVersion=12`, `CFBundleIdentifier=ru.arvectum.tools.tosize`
- **Local exported IPA SHA-256:** `24ae813d73771947b386aeddfec4f9de263e4cd40231c77ef2a6451864f023eb`
- Matching signed archive: `PhotoPodRazmer-1.0.0-12.xcarchive`.
- The archive and exported IPA are now preserved under the canonical ArvectumSSD checkout's ignored directory `apps/photo-size/ios/build/release-1.0.0-12/`; file checksum was verified after copying.

The product source tree in the canonical release integration has been restored exactly to the local shipped-source commit, rather than combining conflicting versions of `AppModel` or the PDF engine. The 1.0.0 (12) source lineage is merged without altering unrelated application branches. The local artifacts and metadata link the submission with this source snapshot; Apple does not expose a public byte-for-byte cryptographic digest of the uploaded binary for an independent comparison.

The App Store release source tag is `photo-size-ios-v1.0.0-build12`, pointing to the original build-source commit. This tag is **not** a new binary upload or a new App Store version.

## Follow-ups

- [x] Verify 1.0.0 Ready for Distribution directly in authenticated App Store Connect.
- [x] Verify 1.0.0 build **12** and Apple upload/review/distribution timestamps.
- [x] Recover the separate original release worktree and merge release sources into canonical `main`.
- [x] Verify archived 1.0.0 (12) IPA version/bundle, hash and matched local App Store build ID; preserve archive on ArvectumSSD and tag the source commit.
- [ ] Verify RU storefront propagation: Apple public iTunes lookup returned 0.6.2 on 2026-10-11 while Connect had 1.0.0 Ready for Distribution.
- [ ] Validate the published build on a physical device for photo/PDF regression and monetization.
