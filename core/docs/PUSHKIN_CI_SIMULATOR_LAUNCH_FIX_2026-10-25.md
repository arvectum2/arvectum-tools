# Pushkin iOS CI: simulator launch hardening

Date: 25 October 2026.

## Root cause of main CI failure

Main commit 1cb4cf5, Pushkin iOS CI run 40163205343,
delete-regression: app launch took 129 seconds before Xcode returned
"Timed out while launching application via Xcode".
This failed before running the deletion assertions. The other two
UI and three native deletion unit tests passed. The historical CI
failure remains a real red run, not marked successful.

## Fix

- [x] Create a uniquely named disposable CI deletion simulator.
- [x] Boot and await readiness with simctl bootstatus -b.
- [x] Target exact private simulator UDID rather than shared name.
- [x] Use Xcode bounded 2 iterations with one retry on failure,
  with retries visible in the standard Xcode test log.
- [x] Always shut down and delete disposable simulator.
- [x] Do not change the production deletion code or original tests.

## Real Mac mini regression

Disposable iPhone 17 Pro iOS 27.0, Xcode 27.1.
Three Swift deletion unit tests and three isolated UI deletion tests
executed twice using the new Xcode flags: **12/12 PASS**, exit 0.
No real notification history or Shortcuts automations accessed.

QA log, XCResult bundle, and exit code:
 /Volumes/ArvectumSSD/Arvectum/qa/pushkin-ci-launch-20261025

GitHub xcode-27 workflow still needs its own verification.
Apple uploads remain subject to per-release explicit approval.
