# PUSHKIN catalog maintenance

## Product rule

Runtime PUSHKIN stays offline and backend-free. Catalog discovery, ranking, lookup, and Shortcut signing happen only during release preparation on Arvectum's build machine.

Users whose app is missing can use the manual Shortcuts path immediately. Their support/review requests feed the next catalog release.

## Feedback queue

Track missing-app requests in `docs/CATALOG_REQUESTS.md`.

Record:
- exact app name as the user wrote it;
- number of independent requests;
- region/storefront when known;
- resolved Apple ID and Bundle ID;
- status: `new`, `resolved`, `queued`, `shipped`, or `declined`;
- target release.

Prioritize repeated requests and high-impact apps. A single request can still be promoted when the omission is obviously important.

Approved build-time input example:
```json
{"apps":[{"name":"Example","appleId":"123456789","country":"ru","requests":4}]}
```

## Release cadence

Target while PUSHKIN is young: **weekly catalog + bug-fix releases when there is meaningful demand/change**. Skip an empty release; do not publish merely to satisfy a calendar.

Release preparation:
1. Review new App Store reviews and support messages.
2. Update `docs/CATALOG_REQUESTS.md`.
3. Resolve requested apps to Apple IDs / Bundle IDs.
4. Add approved requests to `ios/scripts/catalog_requests.json` with Apple ID, storefront country, and request count; the catalog builder forces them into the next bundled catalog.
5. Refresh current App Store chart inputs with `scripts/build_app_store_catalog.py`.
6. Generate and pre-sign the base catalog plus micro-packages with `scripts/generate_coverage_assets.py --sign`.
7. Publish generated assets into the app bundle with `scripts/publish_coverage_assets.py`.
8. Run unit tests plus physical-device `+ App` smoke tests.
9. Increment catalog/app version and ship the catalog together with accumulated bug fixes.

## Success signal

The feedback loop is useful even before analytics exist:
- repeated requests identify missing high-value apps;
- review/support volume indicates whether coverage is a real user pain;
- fewer repeat requests for an app after it ships is a qualitative success signal.

PUSHKIN does not add in-app analytics solely to measure this loop.
