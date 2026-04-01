import XCTest
@testable import Buddy

final class AIServiceTests: XCTestCase {
    func testFallbackBubbleForMorning() {
        let result = AppDelegate.fallbackBubble(for: "아침 시간대 (8시)")
        XCTAssertEqual(result.text, "좋은 아침~ ☀️")
        XCTAssertEqual(result.emotion, .happy)
    }

    func testFallbackBubbleForNight() {
        let result = AppDelegate.fallbackBubble(for: "늦은 밤 시간대 (23시)")
        XCTAssertTrue(result.text.contains("자야"))
        XCTAssertEqual(result.emotion, .sleepy)
    }

    func testFallbackBubbleForAppSwitch() {
        let result = AppDelegate.fallbackBubble(for: "사용자가 Xcode 앱으로 전환했음")
        XCTAssertEqual(result.emotion, .surprised)
    }

    func testAIServiceInitialState() {
        let service = AIService()
        XCTAssertFalse(service.isRunning)
    }
}
