# Pushkin — Shortcuts resource lookup regression (2026-10-15)

## Finding

Full original ArvectumNotifyTests suite initially failed 2 of 9 tests: missing micro-package bundle URLs and local file URL expectations. 1,000 catalogued package files are present in the source and 1,001 .shortcut files were present inside the simulator app (1,000 micro and one base); resource lookup was returning nil for some localized or punctuated filenames even though those files existed.

## Scoped fix

CoverageCatalog.bundledURL retains its Bundle.main.url lookup and adds an exact file-path fallback under Bundle.main.resourceURL for the permitted bundle subdirectories and flattened resource root. No Shortcuts payload, catalog data, app version, SwiftData model or personal notification data is changed. All file URLs remain local.

## Evidence

- [x] Local isolated iPhone 17 simulator, iOS 27, full original ArvectumNotifyTests suite: **9/9 PASS** after patch (TEST SUCCEEDED).
- [x] All 1,000 micro-package URL checks and offline local-file assertions pass.
- [ ] GitHub CI results on independent PR to record after completion.
- [ ] Physical iPhone Shortcut preview / Add to Shortcuts / automatic capture remain onboarding acceptance gates.

This is an independent fix discovered while testing deletion safety; it is not an App Store submission.
