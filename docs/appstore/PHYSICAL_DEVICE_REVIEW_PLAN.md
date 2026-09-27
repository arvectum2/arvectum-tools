# Physical-device QA and App Review recording — iOS 0.4.2

Target review device:
- **Physical iPhone 13 (iPhone14,5)**
- iOS: **27.0**
- Pairing: already configured on Mac mini
- Developer Mode: enabled
- Development provisioning profile already contains the device.

Current blocker: device is **unavailable** because it is not connected to Mac mini.

## Before recording

1. Connect iPhone to Mac mini by USB cable.
2. Unlock iPhone and keep it unlocked.
3. If iOS asks to trust the Mac/accessory, approve it.
4. Enable a Focus / Do Not Disturb mode to prevent personal notifications appearing in the recording.
5. Keep at least one ordinary photo and preferably one portrait photo in Photos.

## QA sequence before recording

Run `ios/Tools/prepare_physical_review.sh`.

Verify:
- app installs and launches without a crash;
- photo picker opens;
- **По весу**: 500 КБ target produces an output at or below 500 КБ;
- **По размеру**: 600 px target produces a result whose long side is exactly 600 px;
- **На паспорт**: crop interaction works and result reports 620×797 px / 450 DPI / JPEG;
- Save/export flow opens and succeeds;
- Share sheet opens;
- switching modes and returning to settings works;
- no login, paywall, network dependency, or unexpected permission prompt appears.

If any physical-device defect appears, do not resubmit build 1. Fix it, increment build number, upload a new build, and record that build instead.

## Recording storyboard

Target duration: approximately 60–90 seconds. Recording must begin before launching the app.

1. Show the iPhone Home Screen and launch **Фото под размер**.
2. **По весу**
   - tap “Выбрать фото”;
   - select a normal photo in the system picker;
   - select **500 КБ**;
   - tap “Уменьшить фото”;
   - show the result size and resolution;
   - open the Share sheet or Save flow, then return.
3. **По размеру**
   - switch to the mode;
   - select a photo;
   - choose **600 px**;
   - run processing;
   - show that the long side is 600 px.
4. **На паспорт**
   - switch to the mode;
   - select a portrait photo;
   - open 35×45 crop;
   - briefly drag/zoom the crop;
   - tap “Подготовить фото”;
   - show **620×797 px · 450 DPI · JPEG**.
5. End on the completed result or main screen.

No narration is required; the UI itself demonstrates the functionality.

## After recording

1. Trim only dead time at the start/end; do not edit out user-flow steps.
2. Encode to H.264 MP4/MOV if necessary.
3. Verify the video starts with app launch and all text is readable.
4. Attach the recording to the App Review conversation.
5. Replace the pending recording line in App Review Notes with the final attachment name.
6. Paste the prepared response from `REVIEW_RESPONSE_2026-09-27.md`.
7. Resubmit the existing **0.4.2 (1)** build unless physical QA required a code fix/new build.
