// Buddy/Buddy/AppDelegate.swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: FloatingWindowController?
    var wanderEngine: WanderEngine?
    var displayTimer: Timer?
    var buddyState = BuddyState()
    var chatWindowController = ChatWindowController()
    var aiService: AIService?
    var contextSensor = ContextSensor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let apiKey = KeychainHelper.load(key: "claude-api-key") {
            aiService = AIService(apiKey: apiKey)
        }

        contextSensor.onContextEvent = { [weak self] context in
            guard let self = self else { return }

            // AI 서비스가 있으면 Claude API로 생성
            if let aiService = self.aiService {
                Task {
                    if let result = await aiService.generateBubble(context: context) {
                        await MainActor.run {
                            self.showBubble(text: result.text, emotion: result.emotion)
                        }
                    }
                }
            } else {
                // API 키가 없으면 기본 대사 사용
                let fallback = Self.fallbackBubble(for: context)
                self.showBubble(text: fallback.text, emotion: fallback.emotion)
            }
        }
        contextSensor.start()

        windowController = FloatingWindowController()
        windowController?.setContent(BuddyContentView(emotion: buddyState.emotion, bubbleText: nil))

        windowController?.setupEventHandling()

        windowController?.onDragStarted = { [weak self] in
            self?.wanderEngine?.pin()
            self?.buddyState.isDragging = true
        }

        windowController?.onDragEnded = { [weak self] position in
            self?.buddyState.isDragging = false
            self?.buddyState.pin()
            self?.wanderEngine?.pin()
            self?.wanderEngine?.setPosition(position)
        }

        windowController?.onClicked = { [weak self] in
            guard let self = self else { return }
            if self.chatWindowController.isVisible {
                self.chatWindowController.close()
                self.buddyState.isChatOpen = false
            } else {
                let frame = self.windowController?.window.frame ?? .zero
                self.chatWindowController.show(near: frame)
                self.buddyState.isChatOpen = true
            }
        }

        chatWindowController.onSendMessage = { [weak self] text in
            guard let self = self else { return }
            let userMsg = ChatMessage(role: .user, content: text)
            self.chatWindowController.addMessage(userMsg)

            Task {
                if let response = await self.aiService?.chat(
                    messages: [],
                    newMessage: text
                ) {
                    await MainActor.run {
                        let assistantMsg = ChatMessage(role: .assistant, content: response)
                        self.chatWindowController.addMessage(assistantMsg)
                    }
                }
            }
        }

        windowController?.onDoubleClicked = { [weak self] in
            self?.buddyState.unpin()
            self?.wanderEngine?.unpin()
        }

        windowController?.show()

        if let screen = NSScreen.main?.visibleFrame {
            wanderEngine = WanderEngine(
                screenBounds: screen,
                characterSize: CGSize(width: 80, height: 90)
            )
        }

        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard !buddyState.isDragging else { return }
        wanderEngine?.tick(deltaTime: 1.0 / 60.0)
        if let pos = wanderEngine?.currentPosition {
            windowController?.moveTo(pos)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        displayTimer?.invalidate()
        windowController?.cleanup()
        contextSensor.stop()
    }

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
