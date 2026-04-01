// Buddy/Views/ChatWindowController.swift
import AppKit
import SwiftUI

// Borderless 윈도우가 키보드 입력을 받으려면 canBecomeKey 필요
class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class ChatWindowController {
    private var window: NSWindow?
    private var messages: [ChatMessage] = []

    var onSendMessage: ((String) -> Void)?

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

        let origin = NSPoint(
            x: characterFrame.midX - 140,
            y: characterFrame.maxY + 10
        )
        chatWindow.setFrameOrigin(origin)

        updateContent(in: chatWindow)
        chatWindow.orderFront(nil)
        chatWindow.makeKey()
        self.window = chatWindow
    }

    func close() {
        window?.orderOut(nil)
        window = nil
    }

    var isVisible: Bool {
        window != nil
    }

    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        if let window = window {
            updateContent(in: window)
        }
    }

    private func updateContent(in window: NSWindow) {
        let chatView = ChatView(messages: .constant(messages)) { [weak self] text in
            self?.onSendMessage?(text)
        }
        let hostingView = NSHostingView(rootView: chatView)
        window.contentView = hostingView
    }
}
