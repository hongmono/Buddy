// Buddy/Views/SlimeView.swift
import SwiftUI

struct SlimeView: View {
    let emotion: Emotion
    var lookOffset: CGPoint = .zero

    @State private var squishPhase: CGFloat = 0
    @State private var isBlinking: Bool = false

    var body: some View {
        ZStack {
            // 몸체
            SlimeBodyShape(squish: squishPhase)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "81c784"), Color(hex: "4caf50")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 60, height: 55)

            // 하이라이트
            Ellipse()
                .fill(Color.white.opacity(0.3))
                .frame(width: 14, height: 10)
                .offset(x: -10, y: -14)

            // 눈
            slimeEyes
                .offset(y: -4)

            // 입
            slimeMouth
                .offset(y: 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                squishPhase = 1
            }
            startBlinkTimer()
        }
    }

    private var pupilOffset: CGPoint {
        CGPoint(x: lookOffset.x * 3, y: lookOffset.y * -2)
    }

    @ViewBuilder
    private var slimeEyes: some View {
        HStack(spacing: 14) {
            switch emotion {
            case .idle:
                slimeEye(size: 8)
                slimeEye(size: 8)
            case .happy:
                SmileEyeShape().stroke(lineWidth: 2).frame(width: 9, height: 5)
                    .foregroundColor(Color(hex: "1a1a2e"))
                SmileEyeShape().stroke(lineWidth: 2).frame(width: 9, height: 5)
                    .foregroundColor(Color(hex: "1a1a2e"))
            case .surprised:
                slimeEye(size: 12)
                slimeEye(size: 12)
            case .sleepy:
                Capsule().frame(width: 8, height: 2).foregroundColor(Color(hex: "1a1a2e"))
                Capsule().frame(width: 8, height: 2).foregroundColor(Color(hex: "1a1a2e"))
            }
        }
    }

    @ViewBuilder
    private func slimeEye(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .frame(width: size, height: isBlinking ? 1 : size)
                .foregroundColor(Color(hex: "1a1a2e"))
            if !isBlinking {
                // 하이라이트
                Circle()
                    .frame(width: size * 0.3, height: size * 0.3)
                    .foregroundColor(.white)
                    .offset(x: -size * 0.15 + pupilOffset.x * 0.3, y: -size * 0.15 + pupilOffset.y * 0.2)
            }
        }
    }

    @ViewBuilder
    private var slimeMouth: some View {
        switch emotion {
        case .idle, .sleepy:
            Circle()
                .frame(width: 4, height: 4)
                .foregroundColor(Color(hex: "1a1a2e").opacity(0.4))
        case .happy:
            SmileEyeShape().stroke(lineWidth: 1.5).frame(width: 10, height: 5)
                .foregroundColor(Color(hex: "1a1a2e").opacity(0.5))
        case .surprised:
            Ellipse()
                .frame(width: 7, height: 9)
                .foregroundColor(Color(hex: "1a1a2e").opacity(0.5))
        }
    }

    private func startBlinkTimer() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...6), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.12)) { isBlinking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.12)) { isBlinking = false }
            }
        }
    }
}

// MARK: - Shapes

struct SlimeBodyShape: Shape {
    var squish: CGFloat

    var animatableData: CGFloat {
        get { squish }
        set { squish = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let squishX = squish * 3  // 좌우로 약간 늘어남
        let squishY = squish * 2  // 위아래로 약간 줄어듦

        // 반원형 상단 + 넓은 하단 (물방울 느낌)
        path.move(to: CGPoint(x: -squishX, y: h * 0.9))

        // 왼쪽
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: -squishY),
            control1: CGPoint(x: -squishX - w * 0.1, y: h * 0.3),
            control2: CGPoint(x: w * 0.15, y: -squishY)
        )

        // 오른쪽
        path.addCurve(
            to: CGPoint(x: w + squishX, y: h * 0.9),
            control1: CGPoint(x: w * 0.85, y: -squishY),
            control2: CGPoint(x: w + squishX + w * 0.1, y: h * 0.3)
        )

        // 하단 (평평하게)
        path.addQuadCurve(
            to: CGPoint(x: -squishX, y: h * 0.9),
            control: CGPoint(x: w * 0.5, y: h + squishY)
        )

        path.closeSubpath()
        return path
    }
}
