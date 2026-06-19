import SwiftUI

struct MonthlyCalendarView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        let isFuture = Calendar.current.startOfDay(for: date) > Calendar.current.startOfDay(for: Date())
                        Button {
                            services.timeline.selectedDate = date
                            dismiss()
                        } label: {
                            Text(date.formatted(.dateTime.day()))
                                .frame(minWidth: 44, minHeight: 44)
                                .background(RivetTheme.primarySurface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(isFuture)
                        .foregroundStyle(isFuture ? RivetTheme.disabled : RivetTheme.primaryText)
                    }
                }
                .padding()
            }
            .navigationTitle("Calendar")
            .toolbar { Button("Done") { dismiss() } }
            .background(RivetTheme.background)
        }
    }

    private func daysInMonth() -> [Date] {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let range = calendar.range(of: .day, in: .month, for: start) ?? 1..<31
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }
}
