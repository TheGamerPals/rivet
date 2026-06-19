import SwiftUI

struct NotificationPermissionView: View {
    @Environment(AppServices.self) private var services

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Notifications")
                .font(.title2.weight(.semibold))
            Text("Rivet schedules local notifications on this device. The backend does not push to the phone.")
                .foregroundStyle(RivetTheme.secondaryText)
            Button {
                Task { await services.notifications.requestPermission() }
            } label: {
                Label("Allow Notifications", systemImage: "bell")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open iOS Settings", systemImage: "gear")
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Notifications")
        .background(RivetTheme.background)
    }
}
