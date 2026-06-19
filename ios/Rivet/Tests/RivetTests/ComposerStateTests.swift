import XCTest
@testable import RivetApp

final class ComposerStateTests: XCTestCase {
    func testFutureDayIsLocked() {
        let future = Date(timeIntervalSinceNow: 86_400)
        let state = ComposerState.resolve(selectedDate: future, window: nil, messages: [], now: Date())
        XCTAssertFalse(state.isOpen)
    }

    func testRequiresCheckinMessage() {
        let now = Date()
        let window = ProgressWindow(id: "w", localDate: "2026-06-19", opensAt: now.addingTimeInterval(-60), locksAt: now.addingTimeInterval(3600), status: "open")
        let state = ComposerState.resolve(selectedDate: now, window: window, messages: [], now: now)
        XCTAssertFalse(state.isOpen)
    }

    func testOpenAfterCheckinBeforeLock() {
        let now = Date()
        let window = ProgressWindow(id: "w", localDate: "2026-06-19", opensAt: now.addingTimeInterval(-60), locksAt: now.addingTimeInterval(3600), status: "open")
        let message = TimelineMessage(id: "m", serverSequence: 1, localDate: "2026-06-19", kind: .checkin, author: .app, body: "Report.", publishedAt: now, createdAt: now, sourceDeviceID: nil, clientRequestID: nil)
        let state = ComposerState.resolve(selectedDate: now, window: window, messages: [message], now: now)
        XCTAssertTrue(state.isOpen)
    }
}
