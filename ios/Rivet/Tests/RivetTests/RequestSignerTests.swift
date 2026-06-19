import XCTest
@testable import RivetApp

final class RequestSignerTests: XCTestCase {
    func testCanonicalStringOrder() {
        let value = RequestSigner.canonicalString(
            method: "get",
            path: "/v1/sync",
            query: "b=2&a=1",
            deviceID: "dev",
            timestamp: "10",
            nonce: "nonce",
            bodyHash: "hash"
        )
        XCTAssertEqual(value, "GET\n/v1/sync\na=1&b=2\ndev\n10\nnonce\nhash")
    }
}
