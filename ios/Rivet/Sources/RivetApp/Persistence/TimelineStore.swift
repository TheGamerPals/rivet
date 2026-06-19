import Foundation

@MainActor
@Observable
public final class TimelineStore {
    public var selectedDate: Date = .now
    public var messagesByDate: [String: [TimelineMessage]] = [:]
    public var currentWindow: ProgressWindow?
    public var syncCursor: Int = 0
    public var queuedProgress: [String: String] = [:]

    public func messages(on date: Date) -> [TimelineMessage] {
        messagesByDate[Self.key(for: date), default: []].sorted { $0.createdAt < $1.createdAt }
    }

    public func apply(message: TimelineMessage) {
        var messages = messagesByDate[message.localDate, default: []]
        if !messages.contains(where: { $0.id == message.id }) {
            messages.append(message)
        }
        messagesByDate[message.localDate] = messages
    }

    public static func key(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
