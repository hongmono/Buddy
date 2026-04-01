// Buddy/Views/SpeechBubbleView.swift
import SwiftUI

struct SpeechBubbleView: View {
    let text: String
    let isVisible: Bool

    var body: some View {
        if isVisible {
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "1a1a2e"))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    BubbleShape()
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
                )
                .frame(maxWidth: 280)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
        }
    }
}

struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius: CGFloat = 14
        let tailSize: CGFloat = 8
        let mainRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height - tailSize)
        path.addRoundedRect(in: mainRect, cornerSize: CGSize(width: radius, height: radius))
        let tailX = rect.width - 20
        path.move(to: CGPoint(x: tailX, y: mainRect.maxY))
        path.addLine(to: CGPoint(x: tailX + tailSize, y: rect.height))
        path.addLine(to: CGPoint(x: tailX + tailSize * 2, y: mainRect.maxY))
        return path
    }
}
