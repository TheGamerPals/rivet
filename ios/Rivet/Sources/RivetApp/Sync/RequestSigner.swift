import CryptoKit
import Foundation

public struct DeviceCredentials: Codable, Hashable {
    public let deviceID: String
    public let token: String
    public let signingPrivateKeyData: Data
}

public enum RequestSigner {
    public static func canonicalString(method: String, path: String, query: String, deviceID: String, timestamp: String, nonce: String, bodyHash: String) -> String {
        [method.uppercased(), path, canonicalQuery(query), deviceID, timestamp, nonce, bodyHash].joined(separator: "\n")
    }

    public static func canonicalQuery(_ query: String) -> String {
        URLComponents(string: "?\(query)")?.queryItems?
            .sorted { ($0.name, $0.value ?? "") < ($1.name, $1.value ?? "") }
            .map { "\($0.name)=\($0.value ?? "")" }
            .joined(separator: "&") ?? ""
    }

    public static func sign(request: inout URLRequest, body: Data, credentials: DeviceCredentials) throws {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonceData = SymmetricKey(size: .bits128).withUnsafeBytes { Data($0) }
        let nonce = nonceData.base64URLEncodedString()
        let bodyHash = SHA256.hash(data: body).map { String(format: "%02x", $0) }.joined()
        let path = request.url?.path(percentEncoded: false) ?? "/"
        let query = request.url?.query(percentEncoded: true) ?? ""
        let canonical = canonicalString(
            method: request.httpMethod ?? "GET",
            path: path,
            query: query,
            deviceID: credentials.deviceID,
            timestamp: timestamp,
            nonce: nonce,
            bodyHash: bodyHash
        )
        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: credentials.signingPrivateKeyData)
        let signature = try key.signature(for: Data(canonical.utf8)).base64URLEncodedString()
        request.setValue("Bearer \(credentials.token)", forHTTPHeaderField: "Authorization")
        request.setValue(credentials.deviceID, forHTTPHeaderField: "X-Rivet-Device-Id")
        request.setValue(timestamp, forHTTPHeaderField: "X-Rivet-Timestamp")
        request.setValue(nonce, forHTTPHeaderField: "X-Rivet-Nonce")
        request.setValue(bodyHash, forHTTPHeaderField: "X-Rivet-Body-SHA256")
        request.setValue(signature, forHTTPHeaderField: "X-Rivet-Signature")
    }
}

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
