# Pushkin 1.0.1 (5) — Apple App Review submission

19 October 2026: SUCCESSFULLY SUBMITTED, WAITING_FOR_REVIEW.

The owner explicitly authorized uploading exact build 5 if all checks were green. All 8 PR GitHub checks completed SUCCESS; previous physical QA and local IPA signing/hash checks passed.

- App: Pushkin; Apple ID 6817847111; bundle ru.arvectum.tools.notify.
- Version 1.0.1; ASC version resource 3eb2a583-7fea-43fc-91ef-c5d967d07630.
- Build 5; ASC build resource 36e43f01-96bb-4b8c-be9a-11ab6f84ed29.
- Upload: altool accepted 15,144,910-byte IPA, no errors. ASC processed build5 as VALID and APP_STORE_ELIGIBLE.
- Exact SHA-256: 1568948e6f7d4efdc904e0354b5311828ce160e18cbd164717853e389e5c544c.
- ASC version 1.0.1 relationship to build5 verified through GET.
- Review Submission resource: c62cc2d3-a78c-4563-b09b-f32a7c05e196. Exactly one version item added. Apple accepted PATCH submitted=true (HTTP 200).
- Final independent GET: Review Submission state WAITING_FOR_REVIEW; App Store version state WAITING_FOR_REVIEW.
- Release type AFTER_APPROVAL set and verified. This enables AUTOMATIC publication after Apple approves. No manual release.
- Version 1.0 remained the public storefront version before submission; WAITING_FOR_REVIEW is not a public release.
- The previous App Review 1.0.1(4) was withdrawn; do not mistakenly submit it.

Local audit evidence on external ArvectumSSD:
/Volumes/ArvectumSSD/Arvectum/tmp/pushkin-final-acceptance-20261019

asc-upload-build5.log and asc-upload-build5.exit: successful IPA transfer.
asc-submission-build5.log: build attached, version configured, new review created, then API timeout.
resume-review.log and resume-review.exit: idempotent continuation: GET confirmed zero items, POST added one item, PATCH submitted; independent GET confirmed WAITING_FOR_REVIEW and AFTER_APPROVAL.
asc-submission-build5-result.json: final approval and review IDs.

Remaining: wait for Apple's decision. If approved, publication is automatic. If rejected or changes requested, follow up without submitting any new unapproved build. Physical migration of the actual production App Store app on a personal device was not performed; test QA bundle preserved all eight records in place.
