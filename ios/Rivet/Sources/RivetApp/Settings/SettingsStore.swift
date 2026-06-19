import Foundation
import UIKit

@MainActor
@Observable
public final class SettingsStore {
    public var pairingState: PairingState = .unpaired
    public var backendBaseURL: URL = URL(string: "https://rivetapp.duckdns.org")!
    public var deviceID: String?
    public var deviceDisplayName: String = UIDevice.current.name
    public var settings = AppSettings()
    public var lastSyncAt: Date?
    public var lastSyncError: String?
    public var notificationPermission: String = "unknown"

    public var theme: ThemeMode {
        get { settings.theme }
        set { settings.theme = newValue }
    }
}
