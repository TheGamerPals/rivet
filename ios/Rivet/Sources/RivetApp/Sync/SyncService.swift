import CryptoKit
import Foundation

@MainActor
@Observable
public final class SyncService {
    private let api: APIClient
    private let timeline: TimelineStore
    private let settings: SettingsStore
    private let notifications: NotificationScheduler
    private var credentials: DeviceCredentials?

    public init(api: APIClient, timeline: TimelineStore, settings: SettingsStore, notifications: NotificationScheduler) {
        self.api = api
        self.timeline = timeline
        self.settings = settings
        self.notifications = notifications
        credentials = KeychainStore.loadCredentials()
        if credentials == nil, settings.pairingState == .paired {
            settings.markUnpaired()
        }
    }

    public func pair(code: String) async {
        do {
            let privateKey = Curve25519.Signing.PrivateKey()
            let response = try await api.claimPairing(
                code: code,
                displayName: settings.deviceDisplayName,
                publicKey: privateKey.publicKey.rawRepresentation.base64URLEncodedString()
            )
            let pairedCredentials = DeviceCredentials(
                deviceID: response.deviceID,
                token: response.deviceToken,
                signingPrivateKeyData: privateKey.rawRepresentation
            )
            try KeychainStore.save(credentials: pairedCredentials)
            credentials = pairedCredentials
            settings.deviceID = response.deviceID
            settings.settings = response.settings.local
            settings.pairingState = .paired
            timeline.syncCursor = response.initialCursor
        } catch {
            settings.lastSyncError = error.localizedDescription
        }
    }

    public func sync(reason: String) async {
        guard let credentials else { return }
        do {
            let response = try await api.sync(cursor: timeline.syncCursor, credentials: credentials)
            timeline.syncCursor = response.cursor
            settings.settings = response.settings.local
            timeline.currentWindow = response.progressWindow
            settings.lastSyncAt = Date()
            settings.lastSyncError = nil
            await notifications.refreshNext48Hours(settings: settings.settings, window: response.progressWindow)
        } catch {
            settings.lastSyncError = "Sync failed. Cached history is shown."
        }
    }
}

private extension RemoteSettings {
    var local: AppSettings {
        AppSettings(
            version: version,
            morningTimeLocal: morningTimeLocal,
            eveningTimeLocal: eveningTimeLocal,
            timezoneIdentifier: timezoneIdentifier,
            notificationsEnabled: notificationsEnabled,
            theme: ThemeMode(rawValue: themeMode) ?? .dark,
            styleExampleEgo: styleExampleEgo,
            styleExampleMotivational: styleExampleMotivational,
            summaryMemory: summaryMemory,
            summaryAutoUpdateEnabled: summaryAutoUpdateEnabled
        )
    }
}
