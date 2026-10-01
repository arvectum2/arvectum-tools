# PUSHKIN UI/UX cross-review — build 2

Target: iOS 1.0.0 (2), two-tab release candidate.

## Product rules

- Only two top-level destinations: History and Settings.
- History may scroll because its content is a feed; Settings must fit without scrolling at default Dynamic Type.
- One visible action per external destination in any state.
- Copy stays functional and short; no repeated privacy/setup explanations.
- Product identity is one compact line: Pushkin mark + PUSHKIN + by Arvectum.
- The standalone Arvectum wordmark is not shown in the app header.
- PUSHKIN uses a heavy geometric sans treatment aligned with the Arvectum wordmark rather than the previous literary serif.
- 1.0 stays ad-free; the future native slot remains structurally available in History without reserving blank space.
- Add App and manual fallback remain fully local.
- Release screenshots, metadata, Review Notes and binary must describe the same UI.

## 10 cross-review iterations

### 1. Information architecture
Finding: Apps and Settings were both sparse and split one management task across two tabs.
Change: merged setup, app coverage, storage, privacy, support and version into one Settings screen.
Result: two tabs only — History / Settings.

### 2. Brand hierarchy
Finding: Arvectum wordmark, Pushkin portrait and PUSHKIN competed for attention.
Change: removed the large Arvectum wordmark. Header is now Pushkin mark + PUSHKIN + by Arvectum.
Result: PUSHKIN is the product; Arvectum reads as a quiet maker signature.

### 3. Wordmark treatment
Finding: Baskerville Bold Italic made PUSHKIN feel stylistically unrelated to the Arvectum family.
Change: switched PUSHKIN to Avenir Next Heavy with restrained tracking.
Result: the name now reads as a geometric product wordmark consistent with Arvectum's visual language.

### 4. Primary scan path
Finding: setup/status text competed with core History content.
Change: kept the header compact, search directly below it, then only state-dependent action content.
Result: the eye lands on identity → search → notifications.

### 5. Action duplication
Finding: previous flows could surface multiple Shortcuts/Automation destinations close together.
Change: each state exposes only the next required external action. Active Settings has no Shortcuts button.
Result: one task → one CTA.

### 6. Copy density
Finding: the pending-app card still over-explained the step and wrapped long app names.
Change: reduced it to Finish setup, one app-name line and Open Automations; active status became Capture active.
Result: less reading, smaller card, clearer next action.

### 7. Screen fit / no-scroll rule
Finding: two separate sparse tabs wasted space; merging risked creating a scrolling settings page.
Change: compact cards, side-by-side Privacy/Support links, icon-only destructive action, short footer.
Result: all Settings primary actions remain visible without scrolling on the test iPhone layout.

### 8. Touch and accessibility review
Checked: primary controls remain at least 44 pt; destructive action has an accessibility label; Add App and manual setup keep stable identifiers; keyboard dismissal remains explicit in History/App search.
Result: no reduced hit targets introduced by compaction.

### 9. Light / Dark visual review
Checked simulator captures in both appearances.
Change after visual pass: removed redundant active-state sentence and shortened the pending setup card.
Result: hierarchy, borders, mint accent and destructive red remain readable in both themes without extra decorative containers.

### 10. App Store consistency review
Checked binary UI, screenshots plan, Review Notes, physical-device video shot list and EN/RU listing copy as one release surface.
Change: review instructions now reference History + Settings, not the removed Apps tab; build 2 will replace build 1.
Result: reviewer-facing material matches the product being submitted.

## Verification gates

- Unit tests: all catalog/store tests must pass.
- Focused UI tests: two-tab shell, no-scroll Settings, Add App, manual fallback, no duplicate Shortcuts action, search keyboard dismissal and future ad insertion point.
- Simulator visual captures: History + Settings in Light and Dark.
- Physical iPhone: build 2 install/launch and App Review recording.
- App Store metadata: English default localization; Russian localization for the Russian storefront.
- App Review attachment: physical-device video uploaded before submission.

## Release decision

Build 2 is eligible for submission only after the gates above pass and the physical-device review video is attached.
