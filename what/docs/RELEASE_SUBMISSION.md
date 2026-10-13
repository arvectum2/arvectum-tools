# What? 1.0.0 — App Store submission

- Bundle: ru.arvectum.tools.what
- Platforms: iPhone (iOS 17+) + Apple Watch (watchOS 10+)
- Category: Productivity; free; no ads or in-app purchases
- English title: What? — Voice Notes
- English subtitle: Catch thoughts on Apple Watch
- Russian title: What? — Голосовые заметки
- Russian subtitle: Запиши мысль, пока не ушла
- Support: https://arvectum.com/contact
- Privacy policy: https://arvectum.com/privacy
- Marketing URL: https://arvectum.com/tools/

## English description

Catch a thought before it disappears. With What?, one tap on your Apple Watch starts your voice note. Stop when you are ready: your original recording stays on the Watch until safely delivered to your iPhone, including when the phone is offline or away.

On iPhone, play your voice notes, transcribe them on-device, edit text, search by words, archive and export the audio or transcription. No account, no server-side storage, no distractions.

## Русское описание

Запиши мысль, пока она не ушла. Одно нажатие на Apple Watch — и можно говорить. После остановки оригинальная запись надёжно сохраняется на часах, а при восстановлении связи передаётся на iPhone.

На iPhone можно слушать записи, расшифровывать их, исправлять текст, искать по словам, архивировать и экспортировать аудио или расшифровку. Без регистрации и облачного хранения записей.

## Privacy and release gate

All voice audio and transcriptions remain on the user's paired devices. No analytics, tracking, advertisements or developer cloud processing in the release source. App Store Connect privacy declarations must be checked against the final build. Original audio is retained even if transcription fails.

- [x] Release source separated from experimental semantic-search corpora.
- [x] iOS/watchOS signed debug builds installed on real paired devices.
- [x] 17 iPhone recording entries, 17 M4A audio files, 15 transcripts preserved byte-identically.
- [x] Watch queue backed up and preserved; no pending transfers at installation.
- [x] iOS simulator suite: 50 passed, zero failed, three optional experimental checks skipped.
- [x] Apple required-reason privacy manifests in iOS/watchOS bundles.
- [x] Release configuration xcarchive generated.
- [ ] App icon: user to supply one opaque 1024x1024 PNG, used for iPhone and Watch.
- [ ] Capture-to-microphone p95 measured in physical Watch use; target <=2 sec in warm/normal conditions.
- [ ] Offline real Watch recording and delayed transfer rechecked on the final signed build.
- [ ] App Store screenshots without user's private notes.
- [ ] App Store Connect listing and review submission, after icon is supplied.
