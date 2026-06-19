import SwiftUI

struct OnboardingPairingView: View {
    @Environment(AppServices.self) private var services
    @State private var pairingCode = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer()
            Text("Rivet")
                .font(.system(.largeTitle, design: .default, weight: .semibold))
                .foregroundStyle(RivetTheme.primaryText)
            Text("Pair this device with the private backend.")
                .foregroundStyle(RivetTheme.secondaryText)
            TextField("Pairing code", text: $pairingCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Pairing code")
            Button {
                Task { await services.sync.pair(code: pairingCode.trimmingCharacters(in: .whitespacesAndNewlines)) }
            } label: {
                Label("Pair", systemImage: "link")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(pairingCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if let error = services.settings.lastSyncError {
                Text(error).foregroundStyle(RivetTheme.warning)
            }
            Spacer()
        }
        .padding(24)
        .background(RivetTheme.background.ignoresSafeArea())
    }
}
