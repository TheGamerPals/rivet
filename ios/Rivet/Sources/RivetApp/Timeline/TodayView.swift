import SwiftUI

struct TodayView: View {
    @Environment(AppServices.self) private var services
    @Environment(RouterPath.self) private var router

    var body: some View {
        VStack(spacing: 0) {
            DayStripView(selectedDate: Bindable(services.timeline).selectedDate)
            Divider().overlay(RivetTheme.secondarySurface)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(services.timeline.messages(on: services.timeline.selectedDate)) { message in
                        MessageRow(message: message)
                    }
                    if services.timeline.messages(on: services.timeline.selectedDate).isEmpty {
                        ContentUnavailableView("No record for this day.", systemImage: "calendar")
                            .foregroundStyle(RivetTheme.secondaryText)
                    }
                }
                .padding()
            }
            ComposerView()
        }
        .navigationTitle("Today")
        .toolbar {
            Button {
                router.presentedSheet = .monthlyCalendar
            } label: {
                Image(systemName: "calendar")
            }
            .accessibilityLabel("Open monthly calendar")
        }
        .background(RivetTheme.background)
        .refreshable { await services.sync.sync(reason: "manual") }
    }
}

struct MessageRow: View {
    let message: TimelineMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.kind.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
            Text(message.body)
                .font(.body)
                .foregroundStyle(RivetTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RivetTheme.primarySurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel("\(message.kind.displayName). \(message.body)")
    }

    private var accent: Color {
        switch message.kind {
        case .briefing: RivetTheme.accent
        case .checkin: RivetTheme.secondaryText
        case .progress: RivetTheme.progress
        }
    }
}
