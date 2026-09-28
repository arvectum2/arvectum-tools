# App Review response — 2026-09-27

Status: **Rejected — Guideline 2.1 / Information Needed / New App Submission**

Apple requested additional information because the developer account has limited App Review history. No app defect was identified in the review message.

## What Apple requested

1. Screen recording from a physical device on the latest OS, starting from app launch and showing the typical flow.
2. Purpose, target audience, problem solved, and user value.
3. Setup/access instructions, including credentials or sample files if required.
4. External services, tools, or platforms used for core functionality.
5. Regional differences, or confirmation that functionality is consistent across regions.
6. Documentation for regulated activity/protected third-party material, if applicable.

## Response text for Apple

Hello App Review,

Thank you for the request. Below is the additional information for “Фото под размер” version 0.4.2 (build 2).

**1. Physical-device screen recording**
A screen recording captured on the paired physical iPhone 13 (iPhone14,5) running iOS 27.0 will be attached to this App Review conversation before resubmission. The recording starts with a cold launch and demonstrates the normal user flow for all three modes, including selecting a photo, processing it, and the result/save/share flow.

**2. Purpose and target audience**
“Фото под размер” is a small utility for people who need an image file to meet a specific technical upload limit. It solves three common tasks: reducing a photo to a maximum file size, resizing it by the long side in pixels, and preparing the technical 35×45 crop used for passport-application image files. The value is fast, local processing without an account, backend, cloud upload, advertising, or analytics.

**3. Setup and access**
No registration, login, subscription, payment, or special configuration is required. All features are available immediately after launch.

Typical flow:
- Launch the app.
- Select one of the three modes: “По весу”, “По размеру”, or “На паспорт”.
- Tap “Выбрать фото” and select an image with the system iOS photo picker.
- Choose the desired limit/size, or adjust the 35×45 crop.
- Run the operation.
- Review the result and save/export it or use the system Share sheet.

No special sample file is required. Any JPEG, PNG, or HEIC image in the device photo library can be used. A portrait photo can be used to demonstrate the 35×45 technical crop.

**4. External services/tools/platforms**
The app uses no external service to deliver its core functionality. There is no backend, authentication provider, payment processor, analytics SDK, advertising SDK, AI service, cloud image processor, or third-party SDK. Image processing is performed on-device using Apple system frameworks. The app uses the system photo picker, file export/save flow, and Share sheet.

**5. Regional differences**
There are no regional differences, geofencing rules, regional accounts, or region-dependent services. The same functionality is available in every region where the app is distributed.

**6. Regulated industries / protected material**
The app is not a government service, identity-verification service, financial/medical service, or other regulated-service provider. It does not connect to any government system. The “На паспорт” mode only prepares technical file parameters (manual 35×45 crop, 620×797 px, 450 DPI, JPEG); it does not verify identity, modify the person’s face/background/appearance, determine eligibility, or certify compliance with government requirements. The app does not contain or distribute protected third-party content.

Before resubmission, version 0.4.2 (build 1) will be QA-tested on the same physical iPhone used for the recording.

Regards,
LLC ARVECTUM
