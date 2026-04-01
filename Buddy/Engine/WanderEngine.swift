import Foundation

struct WanderEngine {
    private let screenBounds: CGRect
    private let characterSize: CGSize
    private let speed: CGFloat = 20.0 // points per second (느릿느릿 둥둥)

    private(set) var currentPosition: CGPoint
    private var velocity: CGPoint
    private var isPinnedState: Bool = false

    // 방향 전환 타이밍
    private var nextDirectionChange: CGFloat = 0
    private var timeSinceLastChange: CGFloat = 0

    init(screenBounds: CGRect, characterSize: CGSize) {
        self.screenBounds = screenBounds
        self.characterSize = characterSize
        // 화면 중앙 부근에서 시작
        self.currentPosition = CGPoint(
            x: screenBounds.midX - characterSize.width / 2,
            y: screenBounds.midY - characterSize.height / 2
        )
        // 랜덤 초기 방향
        self.velocity = Self.randomDirection()
        self.nextDirectionChange = CGFloat.random(in: 3...8)
    }

    mutating func tick(deltaTime: CGFloat) {
        guard !isPinnedState else { return }

        timeSinceLastChange += deltaTime

        // 주기적으로 방향 살짝 변경 (부드러운 커브)
        if timeSinceLastChange >= nextDirectionChange {
            let newDir = Self.randomDirection()
            // 급격한 전환 대신 현재 방향과 섞기
            velocity.x = velocity.x * 0.3 + newDir.x * 0.7
            velocity.y = velocity.y * 0.3 + newDir.y * 0.7
            // 정규화
            let len = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
            if len > 0 {
                velocity.x /= len
                velocity.y /= len
            }
            timeSinceLastChange = 0
            nextDirectionChange = CGFloat.random(in: 3...8)
        }

        // 이동
        var newX = currentPosition.x + velocity.x * speed * deltaTime
        var newY = currentPosition.y + velocity.y * speed * deltaTime

        // 경계 반사 (부드럽게)
        let minX = screenBounds.minX
        let minY = screenBounds.minY
        let maxX = screenBounds.maxX - characterSize.width
        let maxY = screenBounds.maxY - characterSize.height

        if newX <= minX {
            newX = minX
            velocity.x = abs(velocity.x)
            nudgeDirection()
        } else if newX >= maxX {
            newX = maxX
            velocity.x = -abs(velocity.x)
            nudgeDirection()
        }

        if newY <= minY {
            newY = minY
            velocity.y = abs(velocity.y)
            nudgeDirection()
        } else if newY >= maxY {
            newY = maxY
            velocity.y = -abs(velocity.y)
            nudgeDirection()
        }

        currentPosition = CGPoint(x: newX, y: newY)
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

    // 벽에 닿았을 때 약간 랜덤하게 틀어줌
    private mutating func nudgeDirection() {
        velocity.x += CGFloat.random(in: -0.3...0.3)
        velocity.y += CGFloat.random(in: -0.3...0.3)
        let len = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
        if len > 0 {
            velocity.x /= len
            velocity.y /= len
        }
    }

    private static func randomDirection() -> CGPoint {
        let angle = CGFloat.random(in: 0...(2 * .pi))
        return CGPoint(x: cos(angle), y: sin(angle))
    }
}
