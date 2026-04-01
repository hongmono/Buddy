import Foundation

struct WanderEngine {
    enum Edge: CaseIterable {
        case bottom, right, top, left
    }

    private let screenBounds: CGRect
    private let characterSize: CGSize
    private let speed: CGFloat = 30.0 // points per second

    private(set) var currentPosition: CGPoint
    private var currentEdge: Edge = .bottom
    private var progress: CGFloat = 0.8
    private var isPinnedState: Bool = false

    init(screenBounds: CGRect, characterSize: CGSize) {
        self.screenBounds = screenBounds
        self.characterSize = characterSize
        self.currentPosition = CGPoint(
            x: screenBounds.maxX - characterSize.width - 20,
            y: screenBounds.minY
        )
    }

    mutating func tick(deltaTime: CGFloat) {
        guard !isPinnedState else { return }

        let edgeLength = length(of: currentEdge)
        let progressDelta = (speed * deltaTime) / edgeLength
        progress += progressDelta

        if progress >= 1.0 {
            progress = progress - 1.0
            currentEdge = nextEdge(after: currentEdge)
        }

        currentPosition = position(on: currentEdge, at: progress)
    }

    mutating func pin() {
        isPinnedState = true
    }

    mutating func unpin() {
        isPinnedState = false
    }

    mutating func setPosition(_ point: CGPoint) {
        currentPosition = point
    }

    private func length(of edge: Edge) -> CGFloat {
        switch edge {
        case .bottom, .top:
            return screenBounds.width - characterSize.width
        case .left, .right:
            return screenBounds.height - characterSize.height
        }
    }

    private func nextEdge(after edge: Edge) -> Edge {
        switch edge {
        case .bottom: return .right
        case .right: return .top
        case .top: return .left
        case .left: return .bottom
        }
    }

    private func position(on edge: Edge, at t: CGFloat) -> CGPoint {
        let minX = screenBounds.minX
        let minY = screenBounds.minY
        let maxX = screenBounds.maxX - characterSize.width
        let maxY = screenBounds.maxY - characterSize.height

        switch edge {
        case .bottom:
            return CGPoint(x: minX + (maxX - minX) * t, y: minY)
        case .right:
            return CGPoint(x: maxX, y: minY + (maxY - minY) * t)
        case .top:
            return CGPoint(x: maxX - (maxX - minX) * t, y: maxY)
        case .left:
            return CGPoint(x: minX, y: maxY - (maxY - minY) * t)
        }
    }
}
