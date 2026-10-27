# Photo/PDF — App Privacy review of IndieAppCircle feedback

27.10.2026. Source: locally signed 1.0.4 (16) IPA on Mac mini; no Apple upload.

## Local document processing versus advertising data

- Main Photo/PDF app declares tracking false and an empty collected-data list in its own PrivacyInfo.xcprivacy. ImageEngine/PDFEngine process selected files locally and can strip EXIF metadata.
- The app calls YandexAds.setLocationTracking(false) and defaults consent to false until the user opts in. ATT is requested only after positive consent.
- The IPA **also contains third-party manifests**:
  - YandexMobileAds.framework: DeviceID and AdvertisingData for third-party advertising; NSPrivacyTracking=false.
  - AppMetricaCore: CoarseLocation, ProductInteraction, PurchaseHistory and OtherDataTypes for analytics/functionality; tracking=false.
  - AppMetricaAdSupport: DeviceID for analytics; NSPrivacyTracking=true and two tracking domains.
- These SDK manifests describe potential collection and not proof that all categories are transmitted by this app after consent refusal. We equally cannot claim none are collected or silently delete the App Store privacy label.

## Release controls

- [x] Source image/PDF processing is on-device; distinguish this from third-party advertising data.
- [x] Inspected embedded vendor manifests in actual locally signed IPA.
- [ ] Compare exact current App Store Connect App Privacy questionnaire responses with vendor and on-device network evidence. The ASC appPrivacyDetails GET returned HTTP 404; no mutation performed.
- [ ] Disposable device: opt-out flow and ATT/IDFA/network auditing without personal data.
- [ ] Optional commercial choice: truly tracking-free paid/ad-free app requires an explicit SDK/product decision.
- [ ] Replace previously published Demo Ad screenshot with verified native C15 assets only on authorized listing update.

Recommended wording: "Photos and PDFs are processed on your device. This app shows ads; its advertising SDK may process advertising/device data as disclosed in the privacy policy and App Store." Never claim no collection at all.

Official documentation:
https://developer.apple.com/app-store/app-privacy-details/
https://ads.yandex.com/helpcenter/en/dev/ios/app-privacy-apple
