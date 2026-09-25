# Arvectum Tools

Small consumer utilities by Arvectum.

**Principles:** One tool. One job. Done. · Local first.

## First tool: «Фото под размер»

Android utility with three intentionally final user modes for the first market experiment:

- **По весу** — make an image fit a maximum file size.
- **По пикселям** — set the long side to 600 / 450 / 300 px or a custom value; the short side is calculated automatically with aspect ratio preserved.
- **На паспорт** — prepare the technical file for a passport application through Госуслуги: manual 35×45 crop, 620×797 px, 450 DPI, JPEG, 10 KB–5 MB.

Passport mode changes only crop and technical file parameters. It does not use AI, retouch the image, replace the background, analyze the face, or claim that the photographed person satisfies visual eligibility requirements.

## Product guardrail

**The functional scope was frozen at v0.2.** v0.3.0 is a UI/UX and branding release only: canonical Arvectum logo, brand palette, Proxy Launcher visual language, single-row mode selector and branded footer. No additional editor, converter, batch, AI or document features are added before the first market experiment. New user jobs should become separate Arvectum Tools.

## Build

Requirements: JDK 17 and Android SDK 37.

```bash
./gradlew assembleDebug lintDebug test
```

Debug APK:

`app/build/outputs/apk/debug/app-debug.apk`

See [ROADMAP.md](ROADMAP.md) for the canonical product contract, scope, design system and experiment plan.
