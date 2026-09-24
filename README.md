# Arvectum Tools

Small consumer utilities by Arvectum.

**Principles:** One tool. One job. Done. · Local first.

## First tool: «До размера»

Android utility for the job:

> «Сайт говорит, что файл должен быть не больше X КБ/МБ. Сделай так, чтобы он подошёл».

Current MVP flow:

`choose image → choose maximum size → compress locally → save/share`

Supported in v0.1:
- JPEG/JPG, PNG and static WebP input;
- 100 KB / 500 KB / 1 MB / 2 MB / 5 MB / custom limit;
- JPG output when compression is required;
- original file is kept untouched;
- no re-encoding when the source already fits;
- no account, backend or broad media permission.

## Build

Requirements: JDK 17 and Android SDK 37.

```bash
./gradlew assembleDebug lintDebug test
```

Debug APK:

`app/build/outputs/apk/debug/app-debug.apk`

See [ROADMAP.md](ROADMAP.md) for the canonical product contract, scope, design system and experiment plan.
