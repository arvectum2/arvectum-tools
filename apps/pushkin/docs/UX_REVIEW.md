# PUSHKIN UI/UX cross-review — post-1.0

Target: next public release after the currently submitted 1.0 build.

## Non-negotiable product rules

- History is the only top-level screen allowed to scroll vertically.
- Apps and Settings must expose every primary action without scrolling at default Dynamic Type.
- App search may show only a compact result set; refine the query instead of presenting a long browse list.
- One visible action per external destination. Do not place two Shortcuts buttons in the same state.
- Copy is functional, short, and never repeats privacy/setup information already visible elsewhere.
- The main History screen carries the product identity: Arvectum wordmark + Pushkin portrait + distinctive PUSHKIN wordmark.
- 1.0 remains ad-free. The next-release layout contains an explicit native-ad insertion point without showing an empty placeholder while ads are disabled.
- No future App Store submission until the final UI screenshots are explicitly approved by the product owner.

## Cross-review

### 1. Product / task flow

Before: setup language was repeated across History, Apps and Settings; setup and “open automation” actions could appear close together.

After:
- History empty state has one CTA: **Set up PUSHKIN**.
- Apps has one status-dependent Shortcuts CTA: **Set up PUSHKIN** before verification, **Open automation** after verification.
- Adding an app is a separate CTA and opens the app picker directly.
- Missing-app manual setup is four short steps and one **Open Shortcuts** button.

Result: one task, one next action.

### 2. Information architecture

Top-level navigation stays at three tabs:
- History — notification feed/search and quick `+ App`.
- Apps — setup status and app coverage.
- Settings — local data, privacy, support, version.

Removed the extra intermediate “coverage management” screen from the active flow.

### 3. Visual hierarchy / Arvectum family

- Main header uses Arvectum navy/graphite + mint accent.
- Arvectum wordmark remains primary corporate signature.
- Pushkin portrait is placed directly beside the Arvectum mark.
- PUSHKIN uses a heavy serif treatment with tracking instead of the previous generic system headline.
- Repeated full-width list sections are replaced by compact Arvectum cards.

### 4. iOS interaction review

- Primary and row actions target at least 44 pt.
- Search fields stay fixed; app results are capped at 5 popular / 6 search matches.
- Apps, Settings and Manual Add use fixed vertical layouts rather than scroll containers.
- Long content remains only where content itself is inherently a feed (History).

### 5. Monetization readiness

Future native ad placement is structurally located after the third History item.
`PushkinFeatureFlags.adsEnabled` remains `false`, so the first release and current UI show no blank ad area and no SDK dependency.

## Approval gate

Before enabling ads or submitting the next build:
1. build on simulator + physical iPhone;
2. capture History / Apps / Settings / Add App / Manual Add screenshots;
3. verify no scrolling on non-History primary screens;
4. review light + dark appearance;
5. product owner approves the screenshots;
6. only then prepare/upload the next App Store build.
