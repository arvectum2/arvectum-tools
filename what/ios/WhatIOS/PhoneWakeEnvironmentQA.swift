#if WATCH_ROUTE_QA
import Foundation
import UIKit
import WatchConnectivity

/// Read-only environmental context for physical WatchConnectivity QA.
///
/// Background App Refresh is diagnostic context, NOT a documented direct
/// on/off switch for WCSession.transferFile delivery. No preference changes,
/// notification posting, or private APIs are used.
@MainActor
enum PhoneWakeEnvironmentQA {
    static func snapshot(_ reason: String) {
        let app = UIApplication.shared
        let refresh: String
        switch app.backgroundRefreshStatus {
        case .available: refresh = "available"
        case .denied: refresh = "denied"
        case .restricted: refresh = "restricted"
        @unknown default: refresh = "unknown"
        }

        let appState: String
        switch app.applicationState {
        case .active: appState = "active"
        case .inactive: appState = "inactive"
        case .background: appState = "background"
        @unknown default: appState = "unknown"
        }

        let session = WCSession.default
        let activated = session.activationState == .activated
        // Reachability and pairing can be undefined before activation.
        let connection = activated
            ? "paired=\(session.isPaired),watchInstalled=\(session.isWatchAppInstalled),reachable=\(session.isReachable)"
            : "notActivated"

        WatchRouteQATrace.add(
            "phone-wake-environment",
            note: "reason=\(reason);app=\(appState);refresh=\(refresh);lowPower=\(ProcessInfo.processInfo.isLowPowerModeEnabled);protectedData=\(app.isProtectedDataAvailable);session=\(session.activationState.rawValue);\(connection)"
        )
    }
}
#endif
