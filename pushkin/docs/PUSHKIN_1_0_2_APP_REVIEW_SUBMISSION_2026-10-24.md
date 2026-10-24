# PUSHKIN 1.0.2 (6) — App Review submitted, 24 October 2026

**Real Apple API readback: WAITING_FOR_REVIEW.**
This is not the public release yet; public App Store version remains 1.0.1
until Apple approves and automatically releases the update.

- Owner specifically authorized PUSHKIN 1.0.2 (build 6) for App Review.
- GitHub [PR #140](https://github.com/arvectum2/arvectum-tools/pull/140)
  all 10 CI checks passed, merged as commit 8988e8f0.
- Apple app ID 6817847111; bundle ru.arvectum.tools.notify.
- App Store Version ID: 41caaf39-abbf-40fc-9d9d-ec4176c265ac.
- App Store Build ID: 3c61f388-d217-4ad2-bd6a-7b4bcdff25ad;
  actual build 6, VALID; linked to exactly this App Store Version.
- Review Submission ID: 768a65c3-6f8e-4d7c-9076-eb6f8f463366;
  state WAITING_FOR_REVIEW, exactly one item.
- Release type AFTER_APPROVAL: publish automatically after Apple approval.
- Localized store listings en-US, ru, es-ES, fr-FR. Existing EN/RU
  descriptions preserved, Spanish/French descriptions and release notes added.
- Required screenshot sets APP_IPHONE_61 and APP_IPHONE_67:
  three images each per locale, all asset states COMPLETE before submission.
  ES/FR images reuse authentic published PUSHKIN EN screenshots, not
  fully localized marketing screenshots. Further visual adaptation deferred.
- Uploaded exact signed IPA, 15 278 115 bytes;
  SHA-256 4c5ad84f6f58f83739e064a0752bb12f59ccc742f3557ba64a80aeeb6af1cb89.
- Actual iOS IPA contains RU/EN/ES/FR runtime Localizable.strings,
  codesign --verify --deep --strict PASS.
- Mac mini evidence and readback scripts:
  /Volumes/ArvectumSSD/Arvectum/releases/pushkin-102-four-locales-20261024/.
  Delivery UUID: 3c61f388-d217-4ad2-bd6a-7b4bcdff25ad.

## Next

- [x] Signed binary transport and VALID processing confirmed.
- [x] Four store locales, screenshots, review details preflight.
- [x] Apple App Review submission accepted; WAITING_FOR_REVIEW.
- [ ] After Apple's decision, independently check READY_FOR_SALE and
  public RU/EN/ES/FR storefronts; do not preemptively mark published.
- [ ] If Apple rejects, read the exact reason and get a new targeted
  release approval before submitting replacement binary.

Product constraint: notification capture uses supported, user-configured
Shortcuts automation; it cannot automatically read every iOS notification.
No user's personal notification data or Shortcuts were changed for upload.
