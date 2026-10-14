# ChickMark 1.4.0 — App Review submission receipt

Submitted to Apple App Review and confirmed with App Store Connect API.

| Field | Verified result |
|---|---|
| App ID | 6818711298 |
| Version | 1.4.0 |
| Build | 8 |
| Build ID | 6c70da60-b0dc-4edb-9615-bb52da3150bc |
| App review submission ID | e8dbe148-4328-4437-bd1b-e0d47a39235b |
| Submitted | 2026-10-13 05:20:06 UTC / 08:20 Moscow |
| Submission state | WAITING_FOR_REVIEW |
| App version state | WAITING_FOR_REVIEW |
| Release type | AFTER_APPROVAL (automatic publication) |
| Release source commit | 8a94ddd |

1. Verified historical 1.3.1 draft was NOT submitted and had no attached build.
2. Changed draft to 1.4.0, updated four localized release notes and review notes.
3. Built and exported signed iOS, Watch and widget packages.
4. Apple's first build 7 upload failed ITMS-90683 (missing HealthKit update privacy string on both iPhone and Watch).
5. Fixed and localized the keys; bumped build to 8 and archived, exported and uploaded again.
6. Apple reported upload COMPLETE and build processing VALID.
7. Attached build 8 to App Store version 1.4.0.
8. Created review submission, added version item and explicitly submitted.
9. Read both records back from Apple and confirmed submittedDate and WAITING_FOR_REVIEW.

No API keys or access tokens are stored in this file. The local JSON receipt is at
~/ChickMarkRelease/1.4.0-build8/review_submission_receipt.json.

Approval and publication are still pending with Apple.
