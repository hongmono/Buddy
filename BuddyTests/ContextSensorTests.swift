// BuddyTests/ContextSensorTests.swift
import XCTest
@testable import Buddy

final class ContextSensorTests: XCTestCase {
    func testTimeOfDayContext() {
        let morning = ContextSensor.timeOfDayContext(hour: 8)
        XCTAssertEqual(morning, "아침 시간대 (8시)")

        let night = ContextSensor.timeOfDayContext(hour: 23)
        XCTAssertEqual(night, "늦은 밤 시간대 (23시)")

        let afternoon = ContextSensor.timeOfDayContext(hour: 14)
        XCTAssertEqual(afternoon, "오후 시간대 (14시)")
    }

    func testShouldTriggerRandomBubble() {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        let tooSoon = ContextSensor.shouldTriggerRandom(
            lastBubbleTime: oneMinuteAgo,
            minInterval: 5 * 60,
            maxInterval: 15 * 60
        )
        XCTAssertFalse(tooSoon)
    }
}
