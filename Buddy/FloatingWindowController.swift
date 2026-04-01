// Buddy/Buddy/FloatingWindowController.swift
import AppKit
import SwiftUI

class FloatingWindowController {
    let window: FloatingWindow
    private var isDragging = false
    private var dragOffset: CGPoint = .zero
    private var localMonitor: Any?
    private var dragStartLocation: NSPoint?

    var onClicked: (() -> Void)?
    var onDragStarted: (() -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?
    var onDoubleClicked: (() -> Void)?

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

    func setupEventHandling() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            self?.handleMouseEvent(event) ?? event
        }
    }

    private func handleMouseEvent(_ event: NSEvent) -> NSEvent? {
        let windowFrame = window.frame
        let mouseLocation = NSEvent.mouseLocation

        switch event.type {
        case .leftMouseDown:
            if windowFrame.contains(mouseLocation) {
                if event.clickCount == 2 {
                    onDoubleClicked?()
                    return event
                }
                isDragging = true
                dragOffset = CGPoint(
                    x: mouseLocation.x - windowFrame.origin.x,
                    y: mouseLocation.y - windowFrame.origin.y
                )
                onDragStarted?()
                return event
            }

        case .leftMouseDragged:
            if isDragging {
                let newOrigin = NSPoint(
                    x: mouseLocation.x - dragOffset.x,
                    y: mouseLocation.y - dragOffset.y
                )
                window.setFrameOrigin(newOrigin)
                return event
            }

        case .leftMouseUp:
            if isDragging {
                isDragging = false
                let finalPos = CGPoint(x: window.frame.origin.x, y: window.frame.origin.y)
                onDragEnded?(finalPos)
                return event
            }
            if windowFrame.contains(mouseLocation) {
                onClicked?()
            }

        default:
            break
        }
        return event
    }

    func cleanup() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
