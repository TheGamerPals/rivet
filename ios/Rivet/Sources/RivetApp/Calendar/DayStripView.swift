import SwiftUI

struct DayStripView: View {
    @Binding var selectedDate: Date
    let calendar = Calendar.current

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(offsets, id: \.self) { offset in
                    let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    let isFuture = calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
                    Button {
                        guard !isFuture else { return }
                        selectedDate = date
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 4) {
                            Text(weekday(date)).font(.caption2)
                            Text(day(date)).font(.system(.headline, design: .monospaced))
                        }
                        .frame(width: 52, height: 58)
                        .background(calendar.isDate(date, inSameDayAs: selectedDate) ? RivetTheme.secondarySurface : RivetTheme.primarySurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(isFuture)
                    .foregroundStyle(isFuture ? RivetTheme.disabled : RivetTheme.primaryText)
                    .accessibilityLabel(accessibility(date: date, isFuture: isFuture))
                }
            }
            .padding(.horizontal)
        }
    }

    private var offsets: [Int] { Array(-21...3) }
    private func weekday(_ date: Date) -> String { date.formatted(.dateTime.weekday(.abbreviated)) }
    private func day(_ date: Date) -> String { date.formatted(.dateTime.day()) }
    private func accessibility(date: Date, isFuture: Bool) -> String {
        "\(date.formatted(date: .complete, time: .omitted))\(isFuture ? ", future day disabled" : "")"
    }
}
