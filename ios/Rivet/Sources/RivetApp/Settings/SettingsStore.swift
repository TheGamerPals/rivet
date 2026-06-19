import Foundation
import UIKit

@MainActor
@Observable
public final class SettingsStore {
    private enum DefaultsKey {
        static let pairingState = "rivet.pairingState"
        static let deviceID = "rivet.deviceID"
        static let appSettings = "rivet.appSettings"
        static let lastSyncAt = "rivet.lastSyncAt"
    }

    public var pairingState: PairingState = .unpaired {
        didSet { UserDefaults.standard.set(pairingState.rawValue, forKey: DefaultsKey.pairingState) }
    }
    public var backendBaseURL: URL = URL(string: "https://rivetapp.duckdns.org")!
    public var deviceID: String? {
        didSet { UserDefaults.standard.set(deviceID, forKey: DefaultsKey.deviceID) }
    }
    public var deviceDisplayName: String = UIDevice.current.name
    public var settings = AppSettings() {
        didSet { persistSettings() }
    }
    public var lastSyncAt: Date? {
        didSet { UserDefaults.standard.set(lastSyncAt, forKey: DefaultsKey.lastSyncAt) }
    }
    public var lastSyncError: String?
    public var notificationPermission: String = "unknown"

    public init() {
        let defaults = UserDefaults.standard
        if let rawState = defaults.string(forKey: DefaultsKey.pairingState),
           let state = PairingState(rawValue: rawState) {
            pairingState = state
        }
        deviceID = defaults.string(forKey: DefaultsKey.deviceID)
        lastSyncAt = defaults.object(forKey: DefaultsKey.lastSyncAt) as? Date
        if let data = defaults.data(forKey: DefaultsKey.appSettings),
           let storedSettings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = storedSettings
        }
    }

    public var theme: ThemeMode {
        get { settings.theme }
        set { settings.theme = newValue }
    }

    public func markUnpaired() {
        KeychainStore.deleteCredentials()
        deviceID = nil
        pairingState = .unpaired
    }

    private func persistSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: DefaultsKey.appSettings)
        }
    }
}
