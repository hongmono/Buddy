// Buddy/Buddy/FloatingWindowController.swift
import AppKit
import SwiftUI

enum PetInteraction {
    case tap                // 한번 클릭
    case doubleTap          // 더블 클릭
    case tripleTap          // 세번 연속 클릭
    case pet(direction: PetDirection) // 쓰다듬기 (좌우 반복 드래그)
    case longPress          // 꾹 누르기
    case dragStart          // 드래그 시작 (이동)
    case dragEnd(CGPoint)   // 드래그 끝 (이동)
    case hover              // 마우스 올려놓기
    case hoverEnd           // 마우스 나감
}

enum PetDirection {
    case leftRight
}

class FloatingWindowController {
    let window: FloatingWindow
    private var isDragging = false
    private var didDrag = false
    private var dragOffset: CGPoint = .zero
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var hostingView: NSView?

    // 쓰다듬기 감지용
    private var petDragPositions: [CGFloat] = []
    private var petDragTimer: Timer?
    private var isPetting = false

    // 롱프레스 감지용
    private var longPressTimer: Timer?
    private var didLongPress = false

    // 연속 클릭 감지용
    private var clickCount = 0
    private var clickTimer: Timer?

    // 마우스 hover 감지용
    private var isHovering = false
    private var hoverTrackingArea: NSTrackingArea?

    var onInteraction: ((PetInteraction) -> Void)?

    init() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowSize = NSRect(x: screen.maxX - 300, y: screen.minY + 20, width: 300, height: 200)
        self.window = FloatingWindow(contentRect: windowSize)
        setupHoverTracking()
    }

    func setContent<V: View>(_ view: V) {
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

    // MARK: - Event Handling

    func setupEventHandling() {
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .mouseMoved]
        ) { [weak self] event in
            self?.handleMouseEvent(event) ?? event
        }

        // 글로벌 마우스 이동 감지 (hover용)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.checkHover()
        }
    }

    private func handleMouseEvent(_ event: NSEvent) -> NSEvent? {
        let windowFrame = window.frame
        let mouseLocation = NSEvent.mouseLocation

        switch event.type {
        case .leftMouseDown:
            if window.isPointInCharacter(mouseLocation) {
                // 롱프레스 타이머 시작
                didLongPress = false
                longPressTimer?.invalidate()
                longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
                    self?.didLongPress = true
                    self?.onInteraction?(.longPress)
                }

                isDragging = true
                didDrag = false
                isPetting = false
                petDragPositions = [mouseLocation.x]
                dragOffset = CGPoint(
                    x: mouseLocation.x - windowFrame.origin.x,
                    y: mouseLocation.y - windowFrame.origin.y
                )
                return event
            }

        case .leftMouseDragged:
            if isDragging {
                longPressTimer?.invalidate()

                // 쓰다듬기 감지: 윈도우 안에서 좌우 움직임 추적
                petDragPositions.append(mouseLocation.x)
                if petDragPositions.count > 6 {
                    if detectPetting() {
                        if !isPetting {
                            isPetting = true
                        }
                        onInteraction?(.pet(direction: .leftRight))
                        petDragPositions = [mouseLocation.x]
                        return event
                    }
                }

                if !isPetting {
                    if !didDrag {
                        didDrag = true
                        onInteraction?(.dragStart)
                    }
                    let newOrigin = NSPoint(
                        x: mouseLocation.x - dragOffset.x,
                        y: mouseLocation.y - dragOffset.y
                    )
                    window.setFrameOrigin(newOrigin)
                }
                return event
            }

        case .leftMouseUp:
            longPressTimer?.invalidate()
            if isDragging {
                isDragging = false
                if isPetting {
                    isPetting = false
                    petDragPositions = []
                } else if didDrag {
                    let finalPos = CGPoint(x: window.frame.origin.x, y: window.frame.origin.y)
                    onInteraction?(.dragEnd(finalPos))
                } else if !didLongPress {
                    // 클릭 — 연속 클릭 감지
                    clickCount += 1
                    clickTimer?.invalidate()
                    clickTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        switch self.clickCount {
                        case 1: self.onInteraction?(.tap)
                        case 2: self.onInteraction?(.doubleTap)
                        default: self.onInteraction?(.tripleTap)
                        }
                        self.clickCount = 0
                    }
                }
                return event
            }

        case .mouseMoved:
            checkHover()

        default:
            break
        }
        return event
    }

    // MARK: - Petting Detection

    private func detectPetting() -> Bool {
        // 방향 전환이 2번 이상이면 쓰다듬기
        var directionChanges = 0
        var lastDirection: Int = 0 // -1: left, 1: right

        for i in 1..<petDragPositions.count {
            let diff = petDragPositions[i] - petDragPositions[i - 1]
            let direction = diff > 0 ? 1 : (diff < 0 ? -1 : 0)
            if direction != 0 && direction != lastDirection && lastDirection != 0 {
                directionChanges += 1
            }
            if direction != 0 {
                lastDirection = direction
            }
        }
        return directionChanges >= 2
    }

    // MARK: - Hover Detection

    private func setupHoverTracking() {
        // Timer로 주기적 체크 (NSTrackingArea는 floating window에서 불안정)
    }

    private func checkHover() {
        let mouseLocation = NSEvent.mouseLocation
        let windowFrame = window.frame
        let wasHovering = isHovering
        isHovering = window.isPointInCharacter(mouseLocation)

        if isHovering && !wasHovering {
            onInteraction?(.hover)
        } else if !isHovering && wasHovering {
            onInteraction?(.hoverEnd)
        }
    }

    func cleanup() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        longPressTimer?.invalidate()
        clickTimer?.invalidate()
        petDragTimer?.invalidate()
    }
}
