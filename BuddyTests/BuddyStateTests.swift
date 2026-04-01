import XCTest
@testable import Buddy

final class BuddyStateTests: XCTestCase {
    func testInitialState() {
        let state = BuddyState()
        XCTAssertEqual(state.emotion, .idle)
        XCTAssertFalse(state.isDragging)
        XCTAssertFalse(state.isPinned)
        XCTAssertNil(state.currentBubbleText)
    }

    func testShowBubble() {
        var state = BuddyState()
        state.showBubble(text: "안녕!", emotion: .happy)
        XCTAssertEqual(state.currentBubbleText, "안녕!")
        XCTAssertEqual(state.emotion, .happy)
    }

    func testDismissBubble() {
        var state = BuddyState()
        state.showBubble(text: "안녕!", emotion: .happy)
        state.dismissBubble()
        XCTAssertNil(state.currentBubbleText)
        XCTAssertEqual(state.emotion, .idle)
    }

    func testPinAndUnpin() {
        var state = BuddyState()
        state.pin()
        XCTAssertTrue(state.isPinned)
        state.unpin()
        XCTAssertFalse(state.isPinned)
    }
}
