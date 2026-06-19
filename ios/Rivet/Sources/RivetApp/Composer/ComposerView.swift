import SwiftUI

struct ComposerView: View {
    @Environment(AppServices.self) private var services
    @State private var bodyText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if state.isOpen {
                TextEditor(text: $bodyText)
                    .frame(minHeight: 88, maxHeight: 140)
                    .scrollContentBackground(.hidden)
                    .background(RivetTheme.secondarySurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Progress input")
                Button {
                    submit()
                } label: {
                    Label("Submit", systemImage: "arrow.up.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } else {
                Label(state.message, systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(RivetTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(RivetTheme.primarySurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
            }
        }
        .padding()
        .background(RivetTheme.background)
    }

    private var state: ComposerState {
        ComposerState.resolve(
            selectedDate: services.timeline.selectedDate,
            window: services.timeline.currentWindow,
            messages: services.timeline.messages(on: services.timeline.selectedDate),
            now: Date()
        )
    }

    private func submit() {
        let text = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        services.timeline.queuedProgress[UUID().uuidString] = text
        bodyText = ""
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct ComposerState: Equatable {
    let isOpen: Bool
    let message: String

    static func resolve(selectedDate: Date, window: ProgressWindow?, messages: [TimelineMessage], now: Date, calendar: Calendar = .current) -> ComposerState {
        guard calendar.isDate(selectedDate, inSameDayAs: now) else {
            return ComposerState(isOpen: false, message: "Closed for tomorrow's briefing.")
        }
        guard let window else {
            return ComposerState(isOpen: false, message: "Check-in has not opened.")
        }
        guard messages.contains(where: { $0.kind == .checkin }) else {
            return ComposerState(isOpen: false, message: "Check-in has not opened.")
        }
        guard now >= window.opensAt, now < window.locksAt, window.status == "open" else {
            return ComposerState(isOpen: false, message: "Closed for tomorrow's briefing.")
        }
        return ComposerState(isOpen: true, message: "")
    }
}
