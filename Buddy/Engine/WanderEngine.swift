import Foundation

struct WanderEngine {
    private let screenBounds: CGRect
    private let characterSize: CGSize
    private let profile: MovementProfile

    private(set) var currentPosition: CGPoint
    private var basePosition: CGPoint
    private var velocity: CGPoint
    private var isPinnedState: Bool = false

    // 방향 전환
    private var nextDirectionChange: CGFloat = 0
    private var timeSinceLastChange: CGFloat = 0

    // 보빙
    private var totalTime: CGFloat = 0
    private var bobPhase: CGFloat

    // 속도 변화
    private var currentSpeed: CGFloat
    private var targetSpeed: CGFloat

    // 멈추기
    private var pauseTimer: CGFloat = 0
    private var isPaused: Bool = false

    init(screenBounds: CGRect, characterSize: CGSize, profile: MovementProfile = .ghost) {
        self.screenBounds = screenBounds
        self.characterSize = characterSize
        self.profile = profile

        let startPos = CGPoint(
            x: CGFloat.random(in: screenBounds.minX...(screenBounds.maxX - characterSize.width)),
            y: CGFloat.random(in: screenBounds.minY...(screenBounds.maxY - characterSize.height))
        )
        self.currentPosition = startPos
        self.basePosition = startPos
        self.velocity = Self.randomDirection()
        self.nextDirectionChange = CGFloat.random(in: profile.minDirectionInterval...profile.maxDirectionInterval)
        self.bobPhase = CGFloat.random(in: 0...(2 * .pi))
        self.currentSpeed = CGFloat.random(in: profile.minSpeed...profile.maxSpeed)
        self.targetSpeed = currentSpeed
    }

    mutating func tick(deltaTime: CGFloat) {
        guard !isPinnedState else {
            // 고정 중에도 보빙은 유지
            totalTime += deltaTime
            applyBob()
            return
        }

        totalTime += deltaTime
        timeSinceLastChange += deltaTime

        // 멈추기
        if isPaused {
            pauseTimer -= deltaTime
            if pauseTimer <= 0 {
                isPaused = false
                velocity = Self.randomDirection()
                targetSpeed = CGFloat.random(in: profile.minSpeed...profile.maxSpeed)
            }
            applyBob()
            return
        }

        // 주기적 방향 전환
        if timeSinceLastChange >= nextDirectionChange {
            // 멈추기 확률 체크
            if CGFloat.random(in: 0...1) < profile.pauseProbability {
                isPaused = true
                pauseTimer = CGFloat.random(in: profile.minPauseDuration...profile.maxPauseDuration)
                timeSinceLastChange = 0
                nextDirectionChange = CGFloat.random(in: profile.minDirectionInterval...profile.maxDirectionInterval)
                return
            }

            let newDir = Self.randomDirection()
            velocity.x = velocity.x * 0.2 + newDir.x * 0.8
            velocity.y = velocity.y * 0.2 + newDir.y * 0.8
            normalizeVelocity()

            // 대시 확률 체크
            if CGFloat.random(in: 0...1) < profile.dashProbability {
                targetSpeed = profile.maxSpeed * profile.dashSpeedMultiplier
            } else {
                targetSpeed = CGFloat.random(in: profile.minSpeed...profile.maxSpeed)
            }

            timeSinceLastChange = 0
            nextDirectionChange = CGFloat.random(in: profile.minDirectionInterval...profile.maxDirectionInterval)
        }

        // 속도 부드럽게 보간
        currentSpeed += (targetSpeed - currentSpeed) * profile.speedLerpRate

        // 대시 후 감속
        if currentSpeed > profile.maxSpeed {
            targetSpeed = CGFloat.random(in: profile.minSpeed...profile.maxSpeed)
        }

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
        applyBob()
    }

    // MARK: - Bob

    private mutating func applyBob() {
        let bobY = sin(totalTime * profile.bobFrequencyY + bobPhase) * profile.bobAmplitudeY
        let bobX = sin(totalTime * profile.bobFrequencyX + bobPhase + 1.5) * profile.bobAmplitudeX
        currentPosition = CGPoint(x: basePosition.x + bobX, y: basePosition.y + bobY)
    }

    // MARK: - Controls

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

    // MARK: - Internal

    private mutating func nudgeDirection() {
        let nudge = profile.bounceNudge
        velocity.x += CGFloat.random(in: -nudge...nudge)
        velocity.y += CGFloat.random(in: -nudge...nudge)
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
