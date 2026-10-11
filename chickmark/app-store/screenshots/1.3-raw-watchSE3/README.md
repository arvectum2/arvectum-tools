# ChickMark 1.3 — Apple Watch screenshot masters

This folder contains **raw** images captured from a booted watchOS 27.0 Apple Watch SE 3 (40mm) simulator, paired to an isolated iOS 27 simulator — not to a physical iPhone.

- English, Russian and Spanish: one `01_today.png` snapshot per locale, **324 × 394** pixels.
- Synthetic Watch preview data represents a five-step habit at **3/5** with native increment/decrement controls, using `--seed-watch-screenshot` in DEBUG. No user data, and no production fixture.
- Intended for editorial review. Final watch screenshot needs the App Store Connect-compatible resolution / Watch display device family, localization proof and visual QA.
- All App Store and TestFlight upload actions remain on hold; these images are unpublished development assets.

The screenshot fixture bypasses actual WatchConnectivity only when the explicit DEBUG flag is set. **It does not demonstrate real iPhone↔Watch or cross-iPhone CloudKit convergence.** Those are the final acceptance tests.
