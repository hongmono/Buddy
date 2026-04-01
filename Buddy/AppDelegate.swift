// Buddy/Buddy/AppDelegate.swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: FloatingWindowController?
    var wanderEngine: WanderEngine?
    var displayTimer: Timer?
    var buddyState = BuddyState()
    var chatWindowController = ChatWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        windowController = FloatingWindowController()
        windowController?.setContent(BlobView(emotion: buddyState.emotion))

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
            let userMsg = ChatMessage(role: .user, content: text)
            self?.chatWindowController.addMessage(userMsg)
            // AI response will be connected in Task 8
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
        wanderEngine?.tick(deltaTime: 1.0 / 60.0)
        if let pos = wanderEngine?.currentPosition {
            windowController?.moveTo(pos)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        displayTimer?.invalidate()
        windowController?.cleanup()
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
