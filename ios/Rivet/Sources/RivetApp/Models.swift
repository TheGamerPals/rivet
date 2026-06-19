import Foundation

public enum PairingState: String, Codable {
    case unpaired
    case paired
}

public struct TimelineMessage: Identifiable, Codable, Hashable, Sendable {
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

    enum CodingKeys: String, CodingKey {
        case id
        case serverSequence = "server_sequence"
        case localDate = "local_date"
        case kind
        case author
        case body
        case publishedAt = "published_at"
        case createdAt = "created_at"
        case sourceDeviceID = "source_device_id"
        case clientRequestID = "client_request_id"
    }
}

public enum MessageKind: String, Codable, Sendable {
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

public enum MessageAuthor: String, Codable, Sendable {
    case app
    case human
}

public struct ProgressWindow: Codable, Hashable, Sendable {
    public let id: String
    public let localDate: String
    public let opensAt: Date
    public let locksAt: Date
    public let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case localDate = "local_date"
        case opensAt = "opens_at"
        case locksAt = "locks_at"
        case status
    }
}

public struct AppSettings: Codable, Hashable, Sendable {
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
