import SwiftUI

struct SettingsView: View {
    @Environment(AppServices.self) private var services
    @Environment(RouterPath.self) private var router

    var body: some View {
        @Bindable var settings = services.settings
        Form {
            Section("Sync") {
                LabeledContent("Backend", value: settings.backendBaseURL.absoluteString)
                LabeledContent("Status", value: settings.lastSyncError == nil ? "Connected" : "Error")
                LabeledContent("Last sync", value: settings.lastSyncAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
                Button {
                    Task { await services.sync.sync(reason: "manual") }
                } label: {
                    Label("Manual Sync", systemImage: "arrow.triangle.2.circlepath")
                }
                Button {
                    router.path.append(.diagnostics)
                } label: {
                    Label("Diagnostics", systemImage: "stethoscope")
                }
            }

            Section("Notifications") {
                Toggle("Notifications", isOn: $settings.settings.notificationsEnabled)
                LabeledContent("Permission", value: "\(services.notifications.permissionStatus)")
                Button {
                    router.path.append(.notificationExplanation)
                } label: {
                    Label("Permission", systemImage: "bell.badge")
                }
            }

            Section("Schedule") {
                TextField("Morning briefing time", text: $settings.settings.morningTimeLocal)
                    .accessibilityLabel("Morning briefing time")
                TextField("Evening check-in time", text: $settings.settings.eveningTimeLocal)
                    .accessibilityLabel("Evening check-in time")
                Picker("Theme", selection: $settings.settings.theme) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
            }

            Section("Memory") {
                TextEditor(text: $settings.settings.styleExampleEgo)
                    .frame(minHeight: 90)
                    .accessibilityLabel("Ego-crushing style example")
                TextEditor(text: $settings.settings.styleExampleMotivational)
                    .frame(minHeight: 90)
                    .accessibilityLabel("Pessimistic motivational style example")
                TextEditor(text: $settings.settings.summaryMemory)
                    .frame(minHeight: 120)
                    .accessibilityLabel("Situation summary memory")
                Toggle("Auto-update memory", isOn: $settings.settings.summaryAutoUpdateEnabled)
            }

            Section("Device") {
                LabeledContent("This device", value: settings.deviceDisplayName)
                LabeledContent("Device ID", value: settings.deviceID ?? "Unpaired")
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(RivetTheme.background)
    }
}
