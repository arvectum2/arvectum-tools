# Pushkin: temporary iOS 27 QA Shortcut, safe cleanup P0 (2026-10-19)

User authorized creation, real notification testing and deletion of ONE temporary QA automation, but NOT Apple upload or App Review.

Findings:
- Native iPhone Shortcuts Automation screen originally contained five existing notification automations, none modified by this test.
- The iOS 27 Apple guide uses a model where the user first creates a Shortcut and then attaches a trigger using its Automation editor. The temporary new Shortcut created through this flow is named "Новая команда 4".
- The empty "Новая команда 4" exists and is synchronized through iCloud. This was confirmed by exactly one matching line in the native "shortcuts list" command on BOTH Mac mini and MacBook Air.
- The test navigated to the temporary Shortcut Automation category, confirmed available trigger families, and searched for "Уведомление"; that search returned no matches.
- The temporary shortcut was NEVER given any actions, was NEVER given an automation trigger, and was NEVER enabled to run. No notification-to-Pushkin end-to-end delivery was tested.
- The physical iPhone subsequently failed launching XCTest due to "Developer App Certificate is not trusted"; Xcode explicitly asks for trust through Settings > General > VPN & Device Management. macOS AppleScript shortcuts access was separately blocked by OS automation/accessibility restrictions. No further UI mutations should be attempted until access has been safely restored.
- IMPORTANT: The empty temporary Shortcut CURRENTLY REMAINS in the iCloud library. DO NOT report cleanup completed. It must be deleted specifically, and all earlier shortcuts left intact.
- Potentially mutating throwaway XCUITest sources were moved OUT of the Git worktree into the ArvectumSSD QA evidence directory. None belongs in a production app or PR.

Next safe steps:
1. Owner trusts their own Apple Development certificate on iPhone through Settings > General > VPN & Device Management if prompted, without sharing device passcode.
2. Delete ONLY the specific empty temporary "Новая команда 4" from Shortcuts, including native iCloud confirmation, and recheck absence using "shortcuts list" on Mac mini.
3. Compare the original five automations to baseline, ensuring they remain unmodified.
4. Revisit the pending real notification trigger QA ONLY if a deterministic, safely removable procedure can be established.
5. No IPA upload, TestFlight, App Review or Apple release without fresh explicit owner permission. Public Pushkin 1.0, attempted 1.0.1(4) withdrawn; future authorized distribution setting should be AFTER_APPROVAL.

Evidence, iOS screenshots and log output: /Volumes/ArvectumSSD/Arvectum/tmp/pushkin-temporary-automation-20261019.

## Additional physical QA result at 16:19 Moscow time

- Exactly one shortcut named "Новая команда 4", zero actions, UUID 84D2754E-B585-4D91-AD51-582212D4C174; confirmed using AppleScript. MacBook Air and Mac mini both still list exactly one such Shortcut.
- AppleScript delete on the EXACT UUID returned success but had no effect. The shortcut remains and cleanup is NOT completed.
- iPhone now launches the signed XCTest runner, but security UI prompts for the iPhone passcode to Enable UI Automation. XCTest timed out without obtaining this permission, and did not reach the deletion action.
- A deletion-specific QA XCTest is prepared in the isolated nonproduction worktree. Once owner authorizes automation using their passcode on the iPhone itself, retry the exact cleanup, verify the iCloud item disappears on both Macs and confirm old automations remain unchanged.
- No active QA automation was created, no user automations edited, no App Store submission/upload took place.


## Final resolution — 19 October 2026, 16:32 Moscow time

The exact cleanup is **COMPLETE** (supersedes the earlier historical pending status in this document). After re-running the isolated scoped XCTest and clearing the on-device iOS security prompt, Xcode reported `QA_ONLY_EXACT_ZERO_ACTION_SHORTCUT_FOUND`, `QA_ONLY_SHORTCUT_DELETED`, `QA_PREEXISTING_ITEMS_RETAINED`, `** TEST SUCCEEDED **`. After iCloud sync, native Shortcuts CLI returned **zero** instances of `Новая команда 4` on both Mac mini and MacBook Air. The original library entries were retained. No new automation or notification trigger was active or tested; E2E is still OPEN. No App Store Connect actions were taken.

Evidence: `/Volumes/ArvectumSSD/Arvectum/tmp/pushkin-temporary-automation-20261019/cleanup-exact-one-retry.log` and physical screenshot captured after deletion.
