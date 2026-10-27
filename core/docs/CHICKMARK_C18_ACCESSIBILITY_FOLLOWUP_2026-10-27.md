# ChickMark C18 — post-submission accessibility regression

The Apple App Review submission for ChickMark 1.5.3 (build 21) is already WAITING_FOR_REVIEW with releaseType AFTER_APPROVAL. Its exact signed IPA SHA-256 remains recorded in the C17 signed release manifest and must not be silently replaced.

## Reproduced
A clean iPhone 18 Pro Simulator, Xcode 27.1, running HabitFlowUITests.testAccessibilityAuditCoreScreens produced these diagnostics on the New Habit form:
- HABITS_A11Y surface=create: Contrast nearly passed — Group StaticText.
- HABITS_A11Y surface=create: Contrast failed — habit.group.add Button.
- HABITS_A11Y surface=create: Contrast failed — Done Button. The existing audited carveout for the mint-background Done button is documented in the pre-existing test; it was not created by C17.

The C17 custom-group UI added a section header that is rendered with low-contrast system styling and a disabled Add button rendered with low contrast when the group name is empty.

## C18 source follow-up, not part of submitted binary
- Removed the redundant system Group section header; the picker still labels group selection, and the text field retains its localised group-name prompt.
- Show the Add group button only after the user types a non-empty trimmed group name; use plain button styling and primary foreground colour for adequate contrast when actionable.
- No SwiftData schema changes, group storage changes or app permissions changes.
- Validate with isolated simulator on the existing UI accessibility test and inline custom-group creation test.

**No Apple upload, withdrawal or replacement authorized for this C18 change.** Ship only under a separately approved future build. Current C17 remains in Apple Review.
