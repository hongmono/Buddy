import Foundation

struct BuddyState {
    var position: CGPoint = .zero
    var emotion: Emotion = .idle
    var isDragging: Bool = false
    var isPinned: Bool = false
    var currentBubbleText: String? = nil
    var isChatOpen: Bool = false

    mutating func showBubble(text: String, emotion: Emotion) {
        self.currentBubbleText = text
        self.emotion = emotion
    }

    mutating func dismissBubble() {
        self.currentBubbleText = nil
        self.emotion = .idle
    }

    mutating func pin() {
        isPinned = true
    }

    mutating func unpin() {
        isPinned = false
    }
}
