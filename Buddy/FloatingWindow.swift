// Buddy/Buddy/FloatingWindow.swift
import AppKit

class FloatingWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.isMovableByWindowBackground = false
    }

    /// 캐릭터 본체 영역 (윈도우 좌표 기준, 하단 중앙)
    var characterHitRect: NSRect {
        let charWidth: CGFloat = 80
        let charHeight: CGFloat = 90
        let frameW = frame.width
        return NSRect(
            x: (frameW - charWidth) / 2,
            y: 0,
            width: charWidth,
            height: charHeight
        )
    }

    func isPointInCharacter(_ screenPoint: NSPoint) -> Bool {
        let localPoint = NSPoint(
            x: screenPoint.x - frame.origin.x,
            y: screenPoint.y - frame.origin.y
        )
        return characterHitRect.contains(localPoint)
    }
}
