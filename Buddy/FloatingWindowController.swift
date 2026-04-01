// Buddy/Buddy/FloatingWindowController.swift
import AppKit
import SwiftUI

class FloatingWindowController {
    let window: FloatingWindow
    private var isDragging = false
    private var didDrag = false
    private var dragOffset: CGPoint = .zero
    private var localMonitor: Any?
    private var hostingView: NSView?

    var onClicked: (() -> Void)?
    var onDragStarted: (() -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?
    var onDoubleClicked: (() -> Void)?

    init() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowSize = NSRect(x: screen.maxX - 300, y: screen.minY + 20, width: 300, height: 200)
        self.window = FloatingWindow(contentRect: windowSize)
    }

    func setContent<V: View>(_ view: V) {
        // 기존 호스팅 뷰 제거 (서브뷰 쌓임 방지)
        hostingView?.removeFromSuperview()
        let newHostingView = NSHostingView(rootView: view)
        newHostingView.frame = window.contentView?.bounds ?? .zero
        newHostingView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(newHostingView)
        hostingView = newHostingView
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
                didDrag = false
                dragOffset = CGPoint(
                    x: mouseLocation.x - windowFrame.origin.x,
                    y: mouseLocation.y - windowFrame.origin.y
                )
                return event
            }

        case .leftMouseDragged:
            if isDragging {
                if !didDrag {
                    didDrag = true
                    onDragStarted?()
                }
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
                if didDrag {
                    // 실제 드래그가 있었으면 → 고정
                    let finalPos = CGPoint(x: window.frame.origin.x, y: window.frame.origin.y)
                    onDragEnded?(finalPos)
                } else {
                    // 드래그 없이 mouseDown→mouseUp → 클릭
                    onClicked?()
                }
                return event
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
