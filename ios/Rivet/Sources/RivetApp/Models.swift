import Foundation

public enum PairingState: String, Codable {
    case unpaired
    case paired
}

public struct TimelineMessage: Identifiable, Codable, Hashable {
    public let id: String
    public let serverSequence: Int
    public let localDate: String
    public let kind: MessageKind
    public let author: MessageAuthor
    public let body: String
    public let publishedAt: Date?
    public let createdAt: Date
    public let sourceDeviceID: String?
    public let clientRequestID: String?
}

public enum MessageKind: String, Codable {
    case briefing
    case checkin
    case progress

    var displayName: String {
        switch self {
        case .briefing: "Briefing"
        case .checkin: "Check-in"
        case .progress: "Progress"
        }
    }
}

public enum MessageAuthor: String, Codable {
    case app
    case human
}

public struct ProgressWindow: Codable, Hashable {
    public let id: String
    public let localDate: String
    public let opensAt: Date
    public let locksAt: Date
    public let status: String
}

public struct AppSettings: Codable, Hashable {
    public var version: Int = 1
    public var morningTimeLocal: String = "09:00"
    public var eveningTimeLocal: String = "21:00"
    public var timezoneIdentifier: String = TimeZone.current.identifier
    public var notificationsEnabled: Bool = true
    public var theme: ThemeMode = .dark
    public var styleExampleEgo: String = ""
    public var styleExampleMotivational: String = ""
    public var summaryMemory: String = ""
    public var summaryAutoUpdateEnabled: Bool = false
}
