# PUSHKIN UI/UX cross-review — post-1.0

Target: next public release after the currently submitted 1.0 build.

## Non-negotiable product rules

- History is the only top-level screen allowed to scroll vertically.
- Apps and Settings must expose every primary action without scrolling at default Dynamic Type.
- App search may show only a compact result set; refine the query instead of presenting a long browse list.
- One visible action per external destination. Do not place two Shortcuts buttons in the same state.
- Copy is functional, short, and never repeats privacy/setup information already visible elsewhere.
- The main History screen carries the product identity in one compact row: Arvectum wordmark + Pushkin portrait + distinctive PUSHKIN wordmark.
- 1.0 remains ad-free. The next-release layout contains an explicit native-ad insertion point without showing an empty placeholder while ads are disabled.
- No future App Store submission until the final UI screenshots are explicitly approved by the product owner.

## Cross-review

### 1. Product / task flow

Before: setup language was repeated across History, Apps and Settings; setup and “open automation” actions could appear close together.

After:
- History empty state has one CTA: **Set up PUSHKIN**.
- Apps has a Shortcuts CTA only when setup is incomplete: **Set up PUSHKIN**. Once active, the status card becomes informational and shows no duplicate external action.
- **Add app** is the single primary action on the active Apps screen and opens the picker directly; privacy copy is not repeated there.
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
- Arvectum remains visibly present as the corporate signature without becoming a separate full-width block.
- The Pushkin portrait sits immediately beside the Arvectum wordmark so the product concept is legible at a glance.
- PUSHKIN uses Baskerville Bold Italic with a restrained mint underline, giving it a literary identity while staying inside the Arvectum navy/mint shell.
- Repeated full-width list sections are replaced by compact Arvectum cards.

### 4. iOS interaction review

- Primary and row actions target at least 44 pt.
- Search fields stay fixed; app results are capped at 4 popular / 5 search matches so the picker stays fully visible without becoming a browse feed.
- History search has a visible keyboard-dismiss button inside the search field while focused; Return and interactive list scrolling also dismiss it, so the keyboard can never become a dead-end overlay.
- Apps, Settings and Manual Add use fixed vertical layouts rather than scroll containers.
- Long content remains only where content itself is inherently a feed (History).

### 5. Monetization readiness

Future native ad placement is structurally located after the third History item as a compact native-feed card; it does not reserve blank space while ads are off.
`PushkinFeatureFlags.adsEnabled` remains `false`, so the first release and current UI show no blank ad area and no SDK dependency.

## Verification evidence

- Simulator build on Xcode 27: passed.
- Physical iPhone 13 (`iPhone14,5`), iOS 27.0.1, 1170×2532: redesigned History / Apps / Settings / Add App / Manual Add rendered successfully.
- Unit suite: **9/9 passed** after verifying all 1000 bundled micro-packages resolve as local files, including Unicode filenames.
- Focused UI/UX suite: **6/6 passed** — consumer shell, non-scrolling primary tabs, Add App + Manual Add fit, search keyboard dismissal, calm Add App picker, and offline manual fallback.
- Light and Dark appearances captured for all five review screens.
- Future ad slot previewed after the third History item; with `adsEnabled = false` the slot is absent and leaves no blank space.

## Approval gate

Before enabling ads or submitting the next build:
1. build on simulator + physical iPhone;
2. capture History / Apps / Settings / Add App / Manual Add screenshots;
3. verify no scrolling on non-History primary screens;
4. review light + dark appearance;
5. product owner approves the screenshots;
6. only then prepare/upload the next App Store build.
