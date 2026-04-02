// Buddy/Buddy/AppDelegate.swift
import AppKit
import SwiftUI

class CharacterInstance {
    var character: BuddyCharacter
    var windowController: FloatingWindowController
    var wanderEngine: WanderEngine
    var buddyState: BuddyState
    var aiService: AIService
    var chatWindowController: ChatWindowController?
    var onDeviceAI: Any?  // OnDeviceAIService (macOS 26+)
    var currentLookOffset: CGPoint = .zero
    var lastInteractionTime: Date = Date()
    var resumeWalkTimer: Timer?

    init(character: BuddyCharacter, windowController: FloatingWindowController, wanderEngine: WanderEngine, buddyState: BuddyState, aiService: AIService) {
        self.character = character
        self.windowController = windowController
        self.wanderEngine = wanderEngine
        self.buddyState = buddyState
        self.aiService = aiService

        if #available(macOS 26.0, *) {
            let ai = OnDeviceAIService()
            ai.createSession(characterName: character.name, personality: character.personality)
            self.onDeviceAI = ai
        }
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

        let windowController = FloatingWindowController(scale: CGFloat(character.scale))
        windowController.window.characterScale = CGFloat(character.scale)
        let buddyState = BuddyState()
        windowController.setContent(BuddyContentView(
            emotion: buddyState.emotion,
            bubbleText: nil,
            appearance: character.appearance,
            scale: character.scale,
            imageShape: character.imageShape,
            imageZoom: character.imageZoom,
            imageOffsetX: character.imageOffsetX,
            imageOffsetY: character.imageOffsetY
        ))
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
            characterSize: windowSize,
            profile: character.appearance.movementProfile
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

    /// 비주얼만 실시간 업데이트 (AI 재시작 없음)
    func previewCharacter(_ character: BuddyCharacter) {
        guard let instance = instances[character.id] else { return }
        instance.character = character
        instance.windowController.window.characterScale = CGFloat(character.scale)
        updateBlobView(for: character.id)
    }

    /// 저장 시 호출 — AI 성격 변경 반영
    func updateCharacter(_ character: BuddyCharacter) {
        guard let instance = instances[character.id] else { return }
        let oldName = instance.character.name
        let oldPersonality = instance.character.personality
        instance.character = character
        instance.windowController.window.characterScale = CGFloat(character.scale)
        // AI 성격이 바뀌었을 때만 재시작
        if oldName != character.name || oldPersonality != character.personality {
            instance.aiService.stop()
            let newAI = AIService(name: character.name, personality: character.personality)
            newAI.start { success in
                print("\(character.name) AI reconnected: \(success)")
            }
            instance.aiService = newAI
        }
        updateBlobView(for: character.id)
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
        // 말풍선 켜진 캐릭터 중 랜덤 하나
        let eligible = instances.filter { $0.value.character.bubbleEnabled }
        guard let (id, instance) = eligible.randomElement() else { return }
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
            // 채팅창 토글
            toggleChat(for: id)

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
        let dt: CGFloat = 1.0 / 60.0

        // 1) 각 캐릭터 이동
        for (_, instance) in instances {
            if instance.buddyState.isDragging {
                // 드래그 중: 윈도우 위치를 엔진에 동기화 (충돌 판정용)
                instance.wanderEngine.setPosition(instance.windowController.currentPosition())
            } else {
                instance.wanderEngine.tick(deltaTime: dt)
            }
        }

        // 2) 캐릭터 간 충돌 처리
        resolveCollisions()

        // 3) 위치 반영 + 눈 추적
        for (id, instance) in instances {
            if !instance.buddyState.isDragging {
                instance.windowController.moveTo(instance.wanderEngine.currentPosition)
            }
            updateLookDirection(for: id)
        }
    }

    private func resolveCollisions() {
        let ids = Array(instances.keys)
        guard ids.count > 1 else { return }

        for i in 0..<ids.count {
            for j in (i + 1)..<ids.count {
                guard let a = instances[ids[i]], let b = instances[ids[j]] else { continue }

                let centerA = a.wanderEngine.center
                let centerB = b.wanderEngine.center
                let minDist = a.wanderEngine.collisionRadius + b.wanderEngine.collisionRadius

                let dx = centerB.x - centerA.x
                let dy = centerB.y - centerA.y
                let dist = sqrt(dx * dx + dy * dy)

                guard dist < minDist && dist > 0.01 else { continue }

                let overlap = minDist - dist
                let nx = dx / dist
                let ny = dy / dist

                let aDragging = a.buddyState.isDragging
                let bDragging = b.buddyState.isDragging

                // 부드러운 밀어내기 (프레임당 30%씩 해소 → 자연스러운 애니메이션)
                let pushStrength: CGFloat = 0.3
                let push = overlap * pushStrength

                if aDragging && !bDragging {
                    // A가 드래그 중 → B만 밀려남
                    b.wanderEngine.applyForce(CGPoint(x: nx * push * 2, y: ny * push * 2))
                } else if bDragging && !aDragging {
                    // B가 드래그 중 → A만 밀려남
                    a.wanderEngine.applyForce(CGPoint(x: -nx * push * 2, y: -ny * push * 2))
                } else {
                    // 둘 다 자유 이동 → 반반 밀어냄
                    a.wanderEngine.applyForce(CGPoint(x: -nx * push, y: -ny * push))
                    b.wanderEngine.applyForce(CGPoint(x: nx * push, y: ny * push))
                }
            }
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
            let char = instance.character
            let content = BuddyContentView(
                emotion: instance.buddyState.emotion,
                bubbleText: nil,
                lookOffset: instance.currentLookOffset,
                appearance: char.appearance,
                scale: char.scale,
                imageShape: char.imageShape,
                imageZoom: char.imageZoom,
                imageOffsetX: char.imageOffsetX,
                imageOffsetY: char.imageOffsetY
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
        guard instance.character.bubbleEnabled else {
            // 말풍선 꺼져있으면 감정만 변경
            instance.buddyState.emotion = emotion
            updateBlobView(for: id)
            return
        }
        instance.buddyState.showBubble(text: text, emotion: emotion)
        updateBlobView(for: id)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 3...5)) { [weak self] in
            self?.instances[id]?.buddyState.dismissBubble()
            self?.updateBlobView(for: id)
        }
    }

    private func updateBlobView(for id: UUID) {
        guard let instance = instances[id] else { return }
        let char = instance.character
        let content = BuddyContentView(
            emotion: instance.buddyState.emotion,
            bubbleText: instance.buddyState.currentBubbleText,
            lookOffset: instance.currentLookOffset,
            appearance: char.appearance,
            scale: char.scale,
            imageShape: char.imageShape,
            imageZoom: char.imageZoom,
            imageOffsetX: char.imageOffsetX,
            imageOffsetY: char.imageOffsetY
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

    // MARK: - Chat

    private func toggleChat(for id: UUID) {
        guard let instance = instances[id] else { return }

        if let chat = instance.chatWindowController, chat.isVisible {
            chat.close()
            instance.chatWindowController = nil
        } else {
            let chat = ChatWindowController()
            chat.onSendMessage = { [weak self] text in
                self?.handleChatMessage(text, for: id)
            }
            let frame = instance.windowController.window.frame
            chat.show(near: frame)
            instance.chatWindowController = chat

            chat.addMessage(ChatMessage(role: .assistant, content: "뭐 할까? 😊"))
        }
    }

    private func handleChatMessage(_ text: String, for id: UUID) {
        guard let instance = instances[id] else { return }

        // 사용자 메시지 표시
        instance.chatWindowController?.addMessage(ChatMessage(role: .user, content: text))

        let characterNames = characterStore.characters.map { $0.name }

        // Apple Intelligence로 의도 분석
        if #available(macOS 26.0, *), let onDeviceAI = instance.onDeviceAI as? OnDeviceAIService {
            Task { @MainActor in
                let result = await onDeviceAI.analyzeIntent(text)

                switch result {
                case .command(let command, let targetName, let reaction):
                    // 명령 실행
                    self.executeCommand(command, for: id, targetName: targetName)
                    let response = reaction ?? command.reaction.text
                    instance.chatWindowController?.addMessage(ChatMessage(role: .assistant, content: response))
                    self.showBubble(text: response, emotion: command.reaction.emotion, for: id)

                case .chat(let needsComplexAI, let simpleResponse):
                    if needsComplexAI && instance.aiService.isRunning {
                        // Claude CLI로 전달
                        instance.aiService.chat(message: text) { [weak self] response in
                            DispatchQueue.main.async {
                                let reply = response ?? "음... 잘 모르겠어"
                                instance.chatWindowController?.addMessage(ChatMessage(role: .assistant, content: reply))
                                self?.showBubble(text: String(reply.prefix(50)), emotion: .idle, for: id)
                            }
                        }
                    } else if let response = simpleResponse {
                        // Apple AI 응답
                        instance.chatWindowController?.addMessage(ChatMessage(role: .assistant, content: response))
                        self.showBubble(text: String(response.prefix(50)), emotion: .happy, for: id)
                    } else {
                        // 둘 다 안 되면 fallback
                        let fallback = "흐음... 잘 모르겠어~ 😅"
                        instance.chatWindowController?.addMessage(ChatMessage(role: .assistant, content: fallback))
                    }
                }
            }
        } else if instance.aiService.isRunning {
            // Apple AI 없으면 Claude CLI 직접
            instance.aiService.chat(message: text) { [weak self] response in
                DispatchQueue.main.async {
                    let reply = response ?? "음... 잘 모르겠어"
                    instance.chatWindowController?.addMessage(ChatMessage(role: .assistant, content: reply))
                    self?.showBubble(text: String(reply.prefix(50)), emotion: .idle, for: id)
                }
            }
        } else {
            let fallback = "아직 AI가 연결 안 됐어~ 명령어는 사용할 수 있어!"
            instance.chatWindowController?.addMessage(ChatMessage(role: .assistant, content: fallback))
        }
    }

    // MARK: - Command Execution

    private func executeCommand(_ command: BuddyCommand, for id: UUID, targetName: String? = nil) {
        guard let instance = instances[id] else { return }

        switch command {
        case .comeHere:
            let mouse = NSEvent.mouseLocation
            instance.wanderEngine.moveTo(target: CGPoint(x: mouse.x - 30, y: mouse.y - 35))

        case .goAway:
            let mouse = NSEvent.mouseLocation
            let center = instance.wanderEngine.center
            let dx = center.x - mouse.x
            let dy = center.y - mouse.y
            let dist = max(sqrt(dx * dx + dy * dy), 1)
            let target = CGPoint(
                x: center.x + (dx / dist) * 200,
                y: center.y + (dy / dist) * 200
            )
            instance.wanderEngine.moveTo(target: target)

        case .stop:
            instance.wanderEngine.pin()
            instance.wanderEngine.cancelMoveTarget()

        case .wander:
            instance.wanderEngine.unpin()
            instance.wanderEngine.cancelMoveTarget()

        case .sleep:
            instance.wanderEngine.pin()
            instance.wanderEngine.cancelMoveTarget()
            instance.buddyState.emotion = .sleepy
            updateBlobView(for: id)

        case .wakeUp:
            instance.wanderEngine.unpin()
            instance.buddyState.emotion = .happy
            updateBlobView(for: id)

        case .dance:
            // 빠른 보빙으로 춤 효과 (3초 후 복귀)
            instance.wanderEngine.pin()
            instance.buddyState.emotion = .happy
            updateBlobView(for: id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.instances[id]?.wanderEngine.unpin()
                self?.instances[id]?.buddyState.emotion = .idle
                self?.updateBlobView(for: id)
            }

        case .gather:
            // 모든 캐릭터를 이 캐릭터 위치로 모음
            let target = instance.wanderEngine.center
            for (otherId, otherInstance) in instances where otherId != id {
                otherInstance.wanderEngine.moveTo(target: target)
                showBubble(text: "가는 중~!", emotion: .happy, for: otherId)
            }

        case .scatter:
            let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
            for (otherId, otherInstance) in instances {
                let randomTarget = CGPoint(
                    x: CGFloat.random(in: screen.minX...screen.maxX - 100),
                    y: CGFloat.random(in: screen.minY...screen.maxY - 100)
                )
                otherInstance.wanderEngine.moveTo(target: randomTarget)
                if otherId != id {
                    showBubble(text: "흩어져~!", emotion: .surprised, for: otherId)
                }
            }

        case .goToCharacter:
            if let name = targetName,
               let target = instances.values.first(where: { $0.character.name == name }) {
                instance.wanderEngine.moveTo(target: target.wanderEngine.center)
            }
        }
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
