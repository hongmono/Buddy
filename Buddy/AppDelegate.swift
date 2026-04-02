// Buddy/Buddy/AppDelegate.swift
import AppKit
import SwiftUI

class CharacterInstance {
    let character: BuddyCharacter
    var windowController: FloatingWindowController
    var wanderEngine: WanderEngine
    var buddyState: BuddyState
    var aiService: AIService
    var currentLookOffset: CGPoint = .zero
    var lastInteractionTime: Date = Date()
    var resumeWalkTimer: Timer?

    init(character: BuddyCharacter, windowController: FloatingWindowController, wanderEngine: WanderEngine, buddyState: BuddyState, aiService: AIService) {
        self.character = character
        self.windowController = windowController
        self.wanderEngine = wanderEngine
        self.buddyState = buddyState
        self.aiService = aiService
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var instances: [UUID: CharacterInstance] = [:]
    let characterStore = CharacterStore()

    var displayTimer: Timer?
    var contextSensor = ContextSensor()
    private var idleTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // 자동 말풍선 (맥 활동 감지)
        contextSensor.onContextEvent = { [weak self] context in
            self?.handleContextEvent(context)
        }
        contextSensor.start()

        // 모든 캐릭터 스폰
        for character in characterStore.characters {
            spawnCharacter(character)
        }

        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }

        // 방치 감지 타이머
        idleTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkIdle()
        }
    }

    // MARK: - Character Lifecycle

    func spawnCharacter(_ character: BuddyCharacter) {
        let aiService = AIService(name: character.name, personality: character.personality)
        aiService.start { success in
            if success {
                print("Claude CLI connected for \(character.name)")
            } else {
                print("Claude CLI not found for \(character.name) — using fallback bubbles")
            }
        }

        let windowController = FloatingWindowController()
        windowController.window.characterScale = CGFloat(character.scale)
        let buddyState = BuddyState()
        windowController.setContent(BuddyContentView(emotion: buddyState.emotion, bubbleText: nil, appearance: character.appearance, scale: character.scale))
        windowController.setupEventHandling()

        let characterID = character.id
        windowController.onInteraction = { [weak self] interaction in
            self?.handleInteraction(interaction, for: characterID)
        }

        windowController.show()

        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowSize = windowController.window.frame.size
        let wanderEngine = WanderEngine(
            screenBounds: screen,
            characterSize: windowSize
        )

        let instance = CharacterInstance(
            character: character,
            windowController: windowController,
            wanderEngine: wanderEngine,
            buddyState: buddyState,
            aiService: aiService
        )
        instances[character.id] = instance
    }

    func setCharacterWindowsFloating(_ floating: Bool) {
        let level: NSWindow.Level = floating ? .floating : .normal
        for (_, instance) in instances {
            instance.windowController.window.level = level
        }
    }

    func despawnCharacter(id: UUID) {
        guard let instance = instances[id] else { return }
        instance.resumeWalkTimer?.invalidate()
        instance.windowController.cleanup()
        instance.windowController.window.orderOut(nil)
        instance.aiService.stop()
        instances.removeValue(forKey: id)
    }

    // MARK: - Context Event

    private func handleContextEvent(_ context: String) {
        // 랜덤 캐릭터 하나를 골라서 반응
        guard let (id, instance) = instances.randomElement() else { return }
        if instance.aiService.isRunning {
            instance.aiService.generateBubble(context: context) { [weak self] result in
                guard let self = self, let result = result else { return }
                DispatchQueue.main.async {
                    self.showBubble(text: result.text, emotion: result.emotion, for: id)
                }
            }
        } else {
            let fallback = Self.fallbackBubble(for: context)
            showBubble(text: fallback.text, emotion: fallback.emotion, for: id)
        }
    }

    // MARK: - Interaction Handling

    private func pauseAndResumeWalk(for id: UUID, after delay: TimeInterval = 5) {
        guard let instance = instances[id] else { return }
        instance.wanderEngine.pin()
        instance.resumeWalkTimer?.invalidate()
        instance.resumeWalkTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, let inst = self.instances[id], !inst.buddyState.isPinned else { return }
            self.instances[id]?.wanderEngine.unpin()
        }
    }

    private func handleInteraction(_ interaction: PetInteraction, for id: UUID) {
        guard let instance = instances[id] else { return }
        instance.lastInteractionTime = Date()

        switch interaction {
        case .tap:
            pauseAndResumeWalk(for: id)
            let reactions = [
                ("응?", Emotion.surprised),
                ("왜왜?", .happy),
                ("뭐야~", .idle),
                ("불렀어?", .happy),
            ]
            let reaction = reactions.randomElement()!
            showBubble(text: reaction.0, emotion: reaction.1, for: id)

        case .doubleTap:
            instance.resumeWalkTimer?.invalidate()
            instance.buddyState.unpin()
            instance.wanderEngine.unpin()
            showBubble(text: "다시 돌아다닐게~", emotion: .happy, for: id)

        case .tripleTap:
            pauseAndResumeWalk(for: id)
            let reactions = [
                ("그만 찔러!! 😤", Emotion.surprised),
                ("아 왜!!!", .surprised),
                ("그만해~!!", .surprised),
            ]
            let reaction = reactions.randomElement()!
            showBubble(text: reaction.0, emotion: reaction.1, for: id)

        case .pet:
            pauseAndResumeWalk(for: id)
            let reactions = [
                ("헤헤~ 기분 좋다 ☺️", Emotion.happy),
                ("더 해줘~", .happy),
                ("으흐흐~", .happy),
                ("좋아좋아~", .happy),
            ]
            let reaction = reactions.randomElement()!
            showBubble(text: reaction.0, emotion: reaction.1, for: id)

        case .longPress:
            pauseAndResumeWalk(for: id)
            let reactions = [
                ("으악!!", Emotion.surprised),
                ("깜짝이야!", .surprised),
                ("놀래키지 마... 😨", .surprised),
            ]
            let reaction = reactions.randomElement()!
            showBubble(text: reaction.0, emotion: reaction.1, for: id)

        case .dragStart:
            instance.wanderEngine.pin()
            instance.buddyState.isDragging = true
            showBubble(text: "어디 데려가는 거야?!", emotion: .surprised, for: id)

        case .dragEnd(let position):
            instance.buddyState.isDragging = false
            instance.wanderEngine.pin()
            instance.wanderEngine.setPosition(position)
            showBubble(text: "여기서 살면 되는 거야?", emotion: .idle, for: id)
            // 5초 후 다시 걷기
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.instances[id]?.buddyState.unpin()
                self?.instances[id]?.wanderEngine.unpin()
            }

        case .hover:
            if instance.buddyState.currentBubbleText == nil {
                instance.buddyState.emotion = .happy
                updateBlobView(for: id)
            }

        case .hoverEnd:
            if instance.buddyState.currentBubbleText == nil {
                instance.buddyState.emotion = .idle
                updateBlobView(for: id)
            }
        }
    }

    // MARK: - Idle Detection

    private func checkIdle() {
        for (id, instance) in instances {
            let elapsed = Date().timeIntervalSince(instance.lastInteractionTime)
            if elapsed > 30 && instance.buddyState.emotion != .sleepy && instance.buddyState.currentBubbleText == nil {
                instance.buddyState.emotion = .sleepy
                updateBlobView(for: id)
            }
            if elapsed > 60 && instance.buddyState.currentBubbleText == nil {
                showBubble(text: "zzZ...", emotion: .sleepy, for: id)
                instance.lastInteractionTime = Date() // 리셋해서 계속 뜨지 않게
            }
        }
    }

    // MARK: - Tick

    private func tick() {
        for (id, instance) in instances {
            guard !instance.buddyState.isDragging else { continue }
            instance.wanderEngine.tick(deltaTime: 1.0 / 60.0)
            let pos = instance.wanderEngine.currentPosition
            instance.windowController.moveTo(pos)
            updateLookDirection(for: id)
        }
    }

    private func updateLookDirection(for id: UUID) {
        guard let instance = instances[id] else { return }
        let windowFrame = instance.windowController.window.frame
        let mouseLocation = NSEvent.mouseLocation

        // 캐릭터 중심 기준 커서 방향 계산
        let center = CGPoint(x: windowFrame.midX, y: windowFrame.midY)
        let dx = mouseLocation.x - center.x
        let dy = mouseLocation.y - center.y
        let distance = sqrt(dx * dx + dy * dy)

        // 거리가 가까울수록 더 강하게 바라봄, 너무 멀면 약하게
        let maxDistance: CGFloat = 500
        let intensity = min(distance / maxDistance, 1.0)

        let targetX = (dx / max(distance, 1)) * intensity
        let targetY = (dy / max(distance, 1)) * intensity

        // 부드럽게 보간
        instance.currentLookOffset.x += (targetX - instance.currentLookOffset.x) * 0.1
        instance.currentLookOffset.y += (targetY - instance.currentLookOffset.y) * 0.1

        // 뷰 업데이트 (말풍선 없을 때만 매 프레임 갱신, 있으면 showBubble이 처리)
        if instance.buddyState.currentBubbleText == nil {
            let content = BuddyContentView(
                emotion: instance.buddyState.emotion,
                bubbleText: nil,
                lookOffset: instance.currentLookOffset,
                appearance: instance.character.appearance,
                scale: instance.character.scale
            )
            instance.windowController.setContent(content)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        displayTimer?.invalidate()
        idleTimer?.invalidate()
        for (_, instance) in instances {
            instance.resumeWalkTimer?.invalidate()
            instance.windowController.cleanup()
            instance.aiService.stop()
        }
        instances.removeAll()
        contextSensor.stop()
    }

    // MARK: - Bubble

    private func showBubble(text: String, emotion: Emotion, for id: UUID) {
        guard let instance = instances[id] else { return }
        instance.buddyState.showBubble(text: text, emotion: emotion)
        updateBlobView(for: id)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 3...5)) { [weak self] in
            self?.instances[id]?.buddyState.dismissBubble()
            self?.updateBlobView(for: id)
        }
    }

    private func updateBlobView(for id: UUID) {
        guard let instance = instances[id] else { return }
        let content = BuddyContentView(
            emotion: instance.buddyState.emotion,
            bubbleText: instance.buddyState.currentBubbleText,
            lookOffset: instance.currentLookOffset,
            appearance: instance.character.appearance,
            scale: instance.character.scale
        )
        instance.windowController.setContent(content)
    }

    static func fallbackBubble(for context: String) -> (text: String, emotion: Emotion) {
        if context.contains("아침") { return ("좋은 아침~ ☀️", .happy) }
        if context.contains("늦은 밤") { return ("늦었다... 자야 하는 거 아냐?", .sleepy) }
        if context.contains("점심") { return ("밥 먹었어?", .happy) }
        if context.contains("저녁") { return ("오늘도 수고했어~", .happy) }
        if context.contains("자리를 비웠") { return ("어디 갔어...?", .surprised) }
        if context.contains("앱으로 전환") { return ("오 뭐 하려고?", .surprised) }
        if context.contains("쉬지 않고") { return ("좀 쉬어가~ 👻", .sleepy) }

        let randomLines = [
            ("나 심심해~", Emotion.idle),
            ("뭐 하고 있어?", .idle),
            ("오늘 날씨 어떨까~", .happy),
            ("... 👻", .sleepy),
            ("같이 놀자~", .happy),
        ]
        return randomLines.randomElement()!
    }
}

// Color hex extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
