import SwiftUI

struct DiagnosticsView: View {
    @Environment(AppServices.self) private var services

    var body: some View {
        List {
            LabeledContent("Backend base URL", value: services.settings.backendBaseURL.absoluteString)
            LabeledContent("Pairing", value: services.settings.pairingState.rawValue)
            LabeledContent("Last sync", value: services.settings.lastSyncAt?.formatted(date: .abbreviated, time: .standard) ?? "Never")
            LabeledContent("Last error", value: services.settings.lastSyncError ?? "None")
            LabeledContent("Notification permission", value: "\(services.notifications.permissionStatus)")
            LabeledContent("Pending notifications", value: "\(services.notifications.pendingCount)")
            LabeledContent("Progress window", value: services.timeline.currentWindow?.status ?? "Unknown")
            LabeledContent("Sync cursor", value: "\(services.timeline.syncCursor)")
        }
        .navigationTitle("Diagnostics")
        .scrollContentBackground(.hidden)
        .background(RivetTheme.background)
    }
}
