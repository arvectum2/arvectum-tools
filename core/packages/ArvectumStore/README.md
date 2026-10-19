# App Store optional update prompt

Source: `AppStoreUpdatePrompt.swift` in `ArvectumCore`. Also compiled as a shared source file into ChickMark and Pushkin, whose targets do not link the SwiftPM module yet.

Call `.appStoreUpdatePrompt()` on the iOS app's root view. For app-level initial consent, pass `enabled: !showingConsent` to defer the prompt. Locale may be passed for apps with custom UI language.

- Looks up the installed bundle ID + user region at Apple's public Lookup API, falling back to RU only if the listing is absent.
- Compares dotted numeric **marketing versions**. Equal/older, invalid, unlisted and network failures silently skip.
- Verifies that the update deep link uses `https://apps.apple.com`.
- Shows **Update / Later** without blocking launch. On **Update**, opens the actual App Store listing; on **Later**, dismisses for the rest of this launch (next launch checks again).
- Does not download/install the app, require new permissions, persist user data, use analytics or contact any Arvectum server.
- iOS app only; Watch extensions inherit phone-app upgrades. Android's Play Store update flow is separate.
- Does not show during `--ui-testing` automated launch.
- Release remains independently gated by product QA and owner approval; code in main does not update an App Store binary.
