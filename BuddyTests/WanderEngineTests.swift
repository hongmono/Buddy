import XCTest
@testable import Buddy

final class WanderEngineTests: XCTestCase {
    func testMovesWhenUnpinned() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        var engine = WanderEngine(screenBounds: bounds, characterSize: CGSize(width: 60, height: 70))
        let startPos = engine.currentPosition
        // 충분히 틱을 돌려서 이동 확인
        for _ in 0..<60 {
            engine.tick(deltaTime: 0.016)
        }
        let newPos = engine.currentPosition
        let distance = sqrt(pow(newPos.x - startPos.x, 2) + pow(newPos.y - startPos.y, 2))
        XCTAssertGreaterThan(distance, 1, "Should have moved noticeably")
    }

    func testPinLimitsMovementToBobbing() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        var engine = WanderEngine(screenBounds: bounds, characterSize: CGSize(width: 60, height: 70))
        engine.pin()
        let startPos = engine.currentPosition
        for _ in 0..<60 {
            engine.tick(deltaTime: 0.016)
        }
        let newPos = engine.currentPosition
        // 보빙으로 약간 움직이지만 10pt 이내
        let distance = sqrt(pow(newPos.x - startPos.x, 2) + pow(newPos.y - startPos.y, 2))
        XCTAssertLessThan(distance, 10, "Pinned should only bob, not travel")
    }

    func testUnpinResumesMovement() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        var engine = WanderEngine(screenBounds: bounds, characterSize: CGSize(width: 60, height: 70))
        engine.pin()
        let pinnedPos = engine.currentPosition
        engine.unpin()
        for _ in 0..<300 {
            engine.tick(deltaTime: 0.016)
        }
        let newPos = engine.currentPosition
        let distance = sqrt(pow(newPos.x - pinnedPos.x, 2) + pow(newPos.y - pinnedPos.y, 2))
        XCTAssertGreaterThan(distance, 10, "Should have moved after unpin")
    }

    func testPositionStaysWithinBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        var engine = WanderEngine(screenBounds: bounds, characterSize: CGSize(width: 60, height: 70))
        for _ in 0..<10000 {
            engine.tick(deltaTime: 0.016)
        }
        let pos = engine.currentPosition
        // 보빙 마진 포함
        XCTAssertGreaterThan(pos.x, bounds.minX - 10)
        XCTAssertLessThan(pos.x, bounds.maxX + 10)
        XCTAssertGreaterThan(pos.y, bounds.minY - 10)
        XCTAssertLessThan(pos.y, bounds.maxY + 10)
    }
}
