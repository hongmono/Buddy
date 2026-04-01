// Buddy/Views/SpeechBubbleView.swift
import SwiftUI

struct SpeechBubbleView: View {
    let text: String
    let isVisible: Bool

    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                Text(text)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineSpacing(3)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "2d3250"),
                                        Color(hex: "374058")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "a8edea").opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 4)
                    )
                    .frame(maxWidth: 260)

                // 꼬리 삼각형 (캐릭터 중앙 정렬)
                BubbleTail()
                    .fill(Color(hex: "374058"))
                    .frame(width: 14, height: 8)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .bottom)))
        }
    }
}

// 말풍선 아래 꼬리
struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.closeSubpath()
        return path
    }
}
