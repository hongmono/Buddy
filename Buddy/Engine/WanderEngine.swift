import Foundation

struct WanderEngine {
    private let screenBounds: CGRect
    private let characterSize: CGSize

    private(set) var currentPosition: CGPoint
    private var basePosition: CGPoint  // 보빙 제외한 기본 위치
    private var velocity: CGPoint
    private var isPinnedState: Bool = false

    // 방향 전환
    private var nextDirectionChange: CGFloat = 0
    private var timeSinceLastChange: CGFloat = 0

    // 유령 보빙 (둥실둥실)
    private var totalTime: CGFloat = 0
    private var bobPhase: CGFloat   // 각 유령마다 다른 보빙 위상

    // 속도 변화 (가끔 느려졌다 빨라졌다)
    private var currentSpeed: CGFloat = 15
    private var targetSpeed: CGFloat = 15

    // 가끔 멈추기
    private var pauseTimer: CGFloat = 0
    private var isPaused: Bool = false

    init(screenBounds: CGRect, characterSize: CGSize) {
        self.screenBounds = screenBounds
        self.characterSize = characterSize
        let startPos = CGPoint(
            x: screenBounds.midX - characterSize.width / 2,
            y: screenBounds.midY - characterSize.height / 2
        )
        self.currentPosition = startPos
        self.basePosition = startPos
        self.velocity = Self.randomDirection()
        self.nextDirectionChange = CGFloat.random(in: 4...10)
        self.bobPhase = CGFloat.random(in: 0...(2 * .pi))
    }

    mutating func tick(deltaTime: CGFloat) {
        guard !isPinnedState else {
            // 고정 중에도 보빙은 유지
            totalTime += deltaTime
            let bobY = sin(totalTime * 1.2 + bobPhase) * 6
            let bobX = sin(totalTime * 0.7 + bobPhase + 1.5) * 3
            currentPosition = CGPoint(x: basePosition.x + bobX, y: basePosition.y + bobY)
            return
        }

        totalTime += deltaTime
        timeSinceLastChange += deltaTime

        // 가끔 멈추기 (유령이 두리번거리는 느낌)
        if isPaused {
            pauseTimer -= deltaTime
            if pauseTimer <= 0 {
                isPaused = false
                // 멈춘 후 새 방향
                velocity = Self.randomDirection()
                targetSpeed = CGFloat.random(in: 10...25)
            }
            // 멈춰있어도 보빙은 함
            let bobY = sin(totalTime * 1.2 + bobPhase) * 6
            let bobX = sin(totalTime * 0.7 + bobPhase + 1.5) * 3
            currentPosition = CGPoint(x: basePosition.x + bobX, y: basePosition.y + bobY)
            return
        }

        // 주기적 방향 전환 (부드럽게)
        if timeSinceLastChange >= nextDirectionChange {
            // 가끔 멈추기 (20% 확률)
            if CGFloat.random(in: 0...1) < 0.2 {
                isPaused = true
                pauseTimer = CGFloat.random(in: 1.5...4)
                timeSinceLastChange = 0
                nextDirectionChange = CGFloat.random(in: 4...10)
                return
            }

            let newDir = Self.randomDirection()
            velocity.x = velocity.x * 0.2 + newDir.x * 0.8
            velocity.y = velocity.y * 0.2 + newDir.y * 0.8
            normalizeVelocity()

            targetSpeed = CGFloat.random(in: 8...25)
            timeSinceLastChange = 0
            nextDirectionChange = CGFloat.random(in: 4...10)
        }

        // 속도 부드럽게 보간
        currentSpeed += (targetSpeed - currentSpeed) * 0.02

        // 기본 위치 이동
        var newX = basePosition.x + velocity.x * currentSpeed * deltaTime
        var newY = basePosition.y + velocity.y * currentSpeed * deltaTime

        // 경계 반사
        let minX = screenBounds.minX
        let minY = screenBounds.minY
        let maxX = screenBounds.maxX - characterSize.width
        let maxY = screenBounds.maxY - characterSize.height

        if newX <= minX {
            newX = minX; velocity.x = abs(velocity.x); nudgeDirection()
        } else if newX >= maxX {
            newX = maxX; velocity.x = -abs(velocity.x); nudgeDirection()
        }
        if newY <= minY {
            newY = minY; velocity.y = abs(velocity.y); nudgeDirection()
        } else if newY >= maxY {
            newY = maxY; velocity.y = -abs(velocity.y); nudgeDirection()
        }

        basePosition = CGPoint(x: newX, y: newY)

        // 보빙 오프셋 (위아래 + 좌우 살짝)
        let bobY = sin(totalTime * 1.2 + bobPhase) * 6
        let bobX = sin(totalTime * 0.7 + bobPhase + 1.5) * 3
        currentPosition = CGPoint(x: basePosition.x + bobX, y: basePosition.y + bobY)
    }

    mutating func pin() {
        isPinnedState = true
        basePosition = currentPosition
    }

    mutating func unpin() {
        isPinnedState = false
        basePosition = currentPosition
    }

    mutating func setPosition(_ point: CGPoint) {
        currentPosition = point
        basePosition = point
    }

    private mutating func nudgeDirection() {
        velocity.x += CGFloat.random(in: -0.4...0.4)
        velocity.y += CGFloat.random(in: -0.4...0.4)
        normalizeVelocity()
    }

    private mutating func normalizeVelocity() {
        let len = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
        if len > 0 { velocity.x /= len; velocity.y /= len }
    }

    private static func randomDirection() -> CGPoint {
        let angle = CGFloat.random(in: 0...(2 * .pi))
        return CGPoint(x: cos(angle), y: sin(angle))
    }
}
