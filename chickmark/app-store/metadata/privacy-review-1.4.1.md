# ChickMark 1.4.1 — App Privacy release compliance (P0)

Public deployment MUST NOT be submitted until App Store Connect privacy responses match the actual third-party SDKs.

Archive inspected: physically tested internal 1.4.1 (14), exact YandexMobileAds dependency used by candidate (15). Its embedded privacy manifests include:
- Yandex Mobile Ads: Device ID and Advertising Data for third-party advertising; neither linked to user nor marked tracking in Yandex's own manifest.
- Transitive AppMetrica: Device ID (one component explicitly linked=true, tracking=true), Coarse Location, Product Interaction, Purchase History, Other Data, crash and other diagnostics. The AdSupport component declares tracking=true, requiring review of actual compiled/runtime behavior (including IDFA/ATT policy).
- Transitive KSCrash: Device ID, crash data, performance and other diagnostic types. Runtime collection may depend on SDK initialization/configuration.
- App/Watch code: local HealthKit sample processing; no raw Health measurements are intentionally uploaded. A HealthKit sample *read locally* is not inherently a developer-collected health data item.

Release code audits:
- Yandex SDK only initializes after existing 3-day / 5-launch / 3-checkoff gate and only when ad placement is eligible. Calls YandexAds.setLocationTracking(false), setUserConsent(false) before initialization; no app-level ATT request. But SDK is distributed in final binary and Apple's privacy responses must be based on actual SDK collection, not on wishful assumptions.
- App's first-party PrivacyInfo.xcprivacy says NSPrivacyTracking=false and NSPrivacyCollectedDataTypes empty. This is NOT a complete accounting of third-party manifests.

Steps that require authenticated App Store Connect UI and responsible configuration verification:
1. Log into App Store Connect > ChickMark > App Privacy with Account Holder / Admin / App Manager credentials.
2. Reconcile App Privacy data types and intended purposes with third-party SDK privacy manifests, Yandex documentation and actual runtime settings. In particular do not leave "No Data Collected" unless you establish that none of the declared data is collected at runtime and can substantiate that answer. Resolve AppMetrica tracking status and any ATT requirement.
3. Publish corrected App Privacy responses and verify they are live.
4. Verify public privacy-policy copy accurately describes the advertising provider, data retention, opting out of Health permission and optional iCloud sync.
5. Only then approve public App Review submission and automatic release setting.

Sources:
- https://developer.apple.com/app-store/user-privacy-and-data-use/
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- https://ads.yandex.com/helpcenter/en/dev/ios/app-privacy-apple
