import XCTest
@testable import Buddy

final class WanderEngineTests: XCTestCase {
    func testNextPositionMovesAlongEdge() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        var engine = WanderEngine(screenBounds: bounds, characterSize: CGSize(width: 60, height: 70))
        let startPos = engine.currentPosition
        engine.tick(deltaTime: 1.0)
        let newPos = engine.currentPosition
        XCTAssertNotEqual(startPos, newPos)
    }

    func testPinStopsMovement() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        var engine = WanderEngine(screenBounds: bounds, characterSize: CGSize(width: 60, height: 70))
        engine.pin()
        let startPos = engine.currentPosition
        engine.tick(deltaTime: 1.0)
        XCTAssertEqual(engine.currentPosition, startPos)
    }

    func testUnpinResumesMovement() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        var engine = WanderEngine(screenBounds: bounds, characterSize: CGSize(width: 60, height: 70))
        engine.pin()
        engine.unpin()
        let startPos = engine.currentPosition
        engine.tick(deltaTime: 1.0)
        XCTAssertNotEqual(startPos, engine.currentPosition)
    }

    func testPositionStaysWithinBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        var engine = WanderEngine(screenBounds: bounds, characterSize: CGSize(width: 60, height: 70))
        for _ in 0..<10000 {
            engine.tick(deltaTime: 0.016)
        }
        let pos = engine.currentPosition
        XCTAssertTrue(bounds.contains(CGPoint(x: pos.x + 30, y: pos.y + 35)),
                      "Position \(pos) is outside bounds \(bounds)")
    }
}
