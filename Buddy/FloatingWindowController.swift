// Buddy/Buddy/FloatingWindowController.swift
import AppKit
import SwiftUI

class FloatingWindowController {
    let window: FloatingWindow
    private var isDragging = false
    private var dragOffset: CGPoint = .zero

    var onClicked: (() -> Void)?
    var onDragStarted: (() -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?

    init() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowSize = NSRect(x: screen.maxX - 100, y: screen.minY + 20, width: 80, height: 90)
        self.window = FloatingWindow(contentRect: windowSize)
    }

    func setContent<V: View>(_ view: V) {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = window.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(hostingView)
    }

    func show() {
        window.orderFront(nil)
    }

    func moveTo(_ point: CGPoint) {
        window.setFrameOrigin(NSPoint(x: point.x, y: point.y))
    }

    func currentPosition() -> CGPoint {
        let frame = window.frame
        return CGPoint(x: frame.origin.x, y: frame.origin.y)
    }
}
