import CryptoKit
import Foundation

public struct APIConfiguration: Sendable {
    public let baseURL: URL
    public let activeSPKIPin: String?
    public let backupSPKIPin: String?

    public static let release = APIConfiguration(
        baseURL: URL(string: "https://rivetapp.duckdns.org")!,
        activeSPKIPin: nil,
        backupSPKIPin: nil
    )
}

public struct PairClaimResponse: Decodable, Sendable {
    public let deviceID: String
    public let deviceToken: String
    public let initialCursor: Int
    public let settings: RemoteSettings

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case deviceToken = "device_token"
        case initialCursor = "initial_cursor"
        case settings
    }
}

public struct RemoteSettings: Decodable, Sendable {
    public let version: Int
    public let morningTimeLocal: String
    public let eveningTimeLocal: String
    public let timezoneIdentifier: String
    public let notificationsEnabled: Bool
    public let themeMode: String
    public let styleExampleEgo: String
    public let styleExampleMotivational: String
    public let summaryMemory: String
    public let summaryAutoUpdateEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case version
        case morningTimeLocal = "morning_time_local"
        case eveningTimeLocal = "evening_time_local"
        case timezoneIdentifier = "timezone_identifier"
        case notificationsEnabled = "notifications_enabled"
        case themeMode = "theme_mode"
        case styleExampleEgo = "style_example_ego"
        case styleExampleMotivational = "style_example_motivational"
        case summaryMemory = "summary_memory"
        case summaryAutoUpdateEnabled = "summary_auto_update_enabled"
    }
}

public struct SyncResponse: Decodable, Sendable {
    public let cursor: Int
    public let events: [SyncEvent]
    public let settings: RemoteSettings
    public let progressWindow: ProgressWindow?

    enum CodingKeys: String, CodingKey {
        case cursor, events, settings
        case progressWindow = "progress_window"
    }
}

public struct SyncEvent: Decodable, Sendable {
    public let sequence: Int
    public let eventType: String
    public let entityTable: String
    public let payload: [String: JSONValue]

    enum CodingKeys: String, CodingKey {
        case sequence, payload
        case eventType = "event_type"
        case entityTable = "entity_table"
    }
}

public enum JSONValue: Decodable, Hashable, Sendable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Int.self) { self = .int(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([String: JSONValue].self) { self = .object(value) }
        else { self = .array(try container.decode([JSONValue].self)) }
    }
}

public final class APIClient: NSObject, URLSessionDelegate {
    public let configuration: APIConfiguration
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(configuration: APIConfiguration) {
        self.configuration = configuration
        encoder.keyEncodingStrategy = .convertToSnakeCase
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601
        super.init()
    }

    public func claimPairing(code: String, displayName: String, publicKey: String) async throws -> PairClaimResponse {
        let body = ["pairing_code": code, "device_display_name": displayName, "device_public_key": publicKey]
        return try await sendUnsigned(path: "/v1/pair/claim", method: "POST", body: body)
    }

    public func sync(cursor: Int, credentials: DeviceCredentials) async throws -> SyncResponse {
        try await sendSigned(path: "/v1/sync", query: "cursor=\(cursor)", method: "GET", body: Optional<String>.none, credentials: credentials)
    }

    private func sendUnsigned<T: Decodable, Body: Encodable>(path: String, method: String, body: Body) async throws -> T {
        var request = URLRequest(url: configuration.baseURL.appending(path: path))
        request.httpMethod = method
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await session().data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func sendSigned<T: Decodable, Body: Encodable>(path: String, query: String = "", method: String, body: Body?, credentials: DeviceCredentials) async throws -> T {
        var components = URLComponents(url: configuration.baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
        components.percentEncodedQuery = query.isEmpty ? nil : query
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        let bodyData = body == nil ? Data() : try encoder.encode(body)
        if body != nil { request.httpBody = bodyData }
        try RequestSigner.sign(request: &request, body: bodyData, credentials: credentials)
        let (data, response) = try await session().data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func session() -> URLSession {
        URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Request failed"
            throw APIError.server(message)
        }
    }
}

public enum APIError: Error, LocalizedError {
    case server(String)
    public var errorDescription: String? {
        switch self { case .server(let message): message }
    }
}
