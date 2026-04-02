// Buddy/Views/ChatWindowController.swift
import AppKit
import SwiftUI

class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// 채팅 메시지를 관리하는 Observable 모델
class ChatMessageStore: ObservableObject {
    @Published var messages: [ChatMessage] = []
    let maxMessages = 100

    func add(_ message: ChatMessage) {
        messages.append(message)
        if messages.count > maxMessages {
            messages.removeFirst(messages.count - maxMessages)
        }
    }
}

class ChatWindowController {
    private var window: NSWindow?
    let messageStore: ChatMessageStore

    init(messageStore: ChatMessageStore) {
        self.messageStore = messageStore
    }
    private var globalClickMonitor: Any?

    var onSendMessage: ((String) -> Void)?
    var onClose: (() -> Void)?

    func show(near characterFrame: NSRect) {
        guard window == nil else { return }

        let chatWindow = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        chatWindow.level = .floating
        chatWindow.isOpaque = false
        chatWindow.backgroundColor = .clear
        chatWindow.hasShadow = true
        chatWindow.isMovableByWindowBackground = true  // 드래그로 이동

        let origin = NSPoint(
            x: characterFrame.midX - 140,
            y: characterFrame.maxY + 10
        )
        chatWindow.setFrameOrigin(origin)

        let chatView = ChatView(messageStore: messageStore) { [weak self] text in
            self?.onSendMessage?(text)
        }
        chatWindow.contentView = NSHostingView(rootView: chatView)
        chatWindow.orderFront(nil)
        chatWindow.makeKey()
        self.window = chatWindow

        // 외부 클릭 감지 → 닫기
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.handleGlobalClick()
        }
    }

    func close() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        window?.orderOut(nil)
        window = nil
    }

    var isVisible: Bool {
        window != nil
    }

    func addMessage(_ message: ChatMessage) {
        messageStore.add(message)
    }

    private func handleGlobalClick() {
        // 외부 클릭 시 닫기
        close()
        onClose?()
    }
}
