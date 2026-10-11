# PUSHKIN missing-app request queue

Source of truth for user-requested catalog additions.

| App name | Requests | Region | Apple ID | Bundle ID | Status | Target release | Notes |
| --- | ---: | --- | --- | --- | --- | --- | --- |
| — | 0 | — | — | — | new | — | Add rows from support and App Store review feedback. |

Rules:
- count independent requests rather than duplicate messages from the same conversation;
- keep the exact user-facing app name for search/UX review;
- resolve Apple ID and Bundle ID before moving to `queued`;
- mark `shipped` only after the signed micro-package is bundled in a released build.
