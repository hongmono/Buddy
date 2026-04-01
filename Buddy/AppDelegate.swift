// Buddy/Buddy/AppDelegate.swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: FloatingWindowController?
    var wanderEngine: WanderEngine?
    var displayTimer: Timer?
    var buddyState = BuddyState()
    var aiService = AIService()
    var contextSensor = ContextSensor()
    private var lastInteractionTime = Date()
    private var idleTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Claude CLI 시작
        aiService.start { success in
            if success {
                print("Claude CLI connected")
            } else {
                print("Claude CLI not found — using fallback bubbles")
            }
        }

        // 자동 말풍선 (맥 활동 감지)
        contextSensor.onContextEvent = { [weak self] context in
            guard let self = self else { return }
            if self.aiService.isRunning {
                self.aiService.generateBubble(context: context) { [weak self] result in
                    guard let self = self, let result = result else { return }
                    DispatchQueue.main.async {
                        self.showBubble(text: result.text, emotion: result.emotion)
                    }
                }
            } else {
                let fallback = Self.fallbackBubble(for: context)
                self.showBubble(text: fallback.text, emotion: fallback.emotion)
            }
        }
        contextSensor.start()

        // 윈도우 설정
        windowController = FloatingWindowController()
        windowController?.setContent(BuddyContentView(emotion: buddyState.emotion, bubbleText: nil))
        windowController?.setupEventHandling()

        // 인터랙션 핸들링
        windowController?.onInteraction = { [weak self] interaction in
            self?.handleInteraction(interaction)
        }

        windowController?.show()

        if let screen = NSScreen.main?.visibleFrame {
            let windowSize = windowController?.window.frame.size ?? CGSize(width: 300, height: 200)
            wanderEngine = WanderEngine(
                screenBounds: screen,
                characterSize: windowSize
            )
        }

        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }

        // 방치 감지 타이머
        idleTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkIdle()
        }
    }

    // MARK: - Interaction Handling

    private func handleInteraction(_ interaction: PetInteraction) {
        lastInteractionTime = Date()

        switch interaction {
        case .tap:
            // 톡 — 가벼운 반응
            let reactions = [
                ("응?", Emotion.surprised),
                ("왜왜?", .happy),
                ("뭐야~", .idle),
                ("불렀어?", .happy),
            ]
            let reaction = reactions.randomElement()!
            showBubble(text: reaction.0, emotion: reaction.1)

        case .doubleTap:
            // 더블탭 — 고정 해제
            buddyState.unpin()
            wanderEngine?.unpin()
            showBubble(text: "다시 돌아다닐게~", emotion: .happy)

        case .tripleTap:
            // 세번 연속 — 짜증
            let reactions = [
                ("그만 찔러!! 😤", Emotion.surprised),
                ("아 왜!!!", .surprised),
                ("그만해~!!", .surprised),
            ]
            let reaction = reactions.randomElement()!
            showBubble(text: reaction.0, emotion: reaction.1)

        case .pet:
            // 쓰다듬기 — 기분 좋음
            let reactions = [
                ("헤헤~ 기분 좋다 ☺️", Emotion.happy),
                ("더 해줘~", .happy),
                ("으흐흐~", .happy),
                ("좋아좋아~", .happy),
            ]
            let reaction = reactions.randomElement()!
            showBubble(text: reaction.0, emotion: reaction.1)

        case .longPress:
            // 꾹 누르기 — 놀람
            let reactions = [
                ("으악!!", Emotion.surprised),
                ("깜짝이야!", .surprised),
                ("놀래키지 마... 😨", .surprised),
            ]
            let reaction = reactions.randomElement()!
            showBubble(text: reaction.0, emotion: reaction.1)

        case .dragStart:
            wanderEngine?.pin()
            buddyState.isDragging = true
            showBubble(text: "어디 데려가는 거야?!", emotion: .surprised)

        case .dragEnd(let position):
            buddyState.isDragging = false
            wanderEngine?.pin()
            wanderEngine?.setPosition(position)
            showBubble(text: "여기서 살면 되는 거야?", emotion: .idle)
            // 5초 후 다시 걷기
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.buddyState.unpin()
                self?.wanderEngine?.unpin()
            }

        case .hover:
            // 마우스 올려놓기 — 눈이 반응
            if buddyState.currentBubbleText == nil {
                buddyState.emotion = .happy
                updateBlobView()
            }

        case .hoverEnd:
            if buddyState.currentBubbleText == nil {
                buddyState.emotion = .idle
                updateBlobView()
            }
        }
    }

    // MARK: - Idle Detection

    private func checkIdle() {
        let elapsed = Date().timeIntervalSince(lastInteractionTime)
        if elapsed > 30 && buddyState.emotion != .sleepy && buddyState.currentBubbleText == nil {
            buddyState.emotion = .sleepy
            updateBlobView()
        }
        if elapsed > 60 && buddyState.currentBubbleText == nil {
            showBubble(text: "zzZ...", emotion: .sleepy)
            lastInteractionTime = Date() // 리셋해서 계속 뜨지 않게
        }
    }

    // MARK: - Tick

    private func tick() {
        guard !buddyState.isDragging else { return }
        wanderEngine?.tick(deltaTime: 1.0 / 60.0)
        if let pos = wanderEngine?.currentPosition {
            windowController?.moveTo(pos)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        displayTimer?.invalidate()
        idleTimer?.invalidate()
        windowController?.cleanup()
        contextSensor.stop()
        aiService.stop()
    }

    // MARK: - Bubble

    private func showBubble(text: String, emotion: Emotion) {
        buddyState.showBubble(text: text, emotion: emotion)
        updateBlobView()
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 3...5)) { [weak self] in
            self?.buddyState.dismissBubble()
            self?.updateBlobView()
        }
    }

    private func updateBlobView() {
        let content = BuddyContentView(
            emotion: buddyState.emotion,
            bubbleText: buddyState.currentBubbleText
        )
        windowController?.setContent(content)
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
