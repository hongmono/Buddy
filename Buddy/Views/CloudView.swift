// Buddy/Views/CloudView.swift
import SwiftUI

struct CloudView: View {
    let emotion: Emotion
    var lookOffset: CGPoint = .zero

    @State private var puffPhase: CGFloat = 0
    @State private var isBlinking: Bool = false

    var body: some View {
        ZStack {
            // 몸체
            CloudBodyShape(puff: puffPhase)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(hex: "e0e7ff")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 70, height: 50)

            // 하이라이트
            Ellipse()
                .fill(Color.white.opacity(0.6))
                .frame(width: 18, height: 10)
                .offset(x: -12, y: -12)

            // 볼 터치
            Circle()
                .fill(Color(hex: "ffcdd2").opacity(0.4))
                .frame(width: 10, height: 10)
                .offset(x: -20, y: 4)
            Circle()
                .fill(Color(hex: "ffcdd2").opacity(0.4))
                .frame(width: 10, height: 10)
                .offset(x: 20, y: 4)

            // 눈
            cloudEyes
                .offset(y: -2)

            // 입
            cloudMouth
                .offset(y: 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                puffPhase = 1
            }
            startBlinkTimer()
        }
    }

    private var pupilOffset: CGPoint {
        CGPoint(x: lookOffset.x * 2.5, y: lookOffset.y * -1.5)
    }

    @ViewBuilder
    private var cloudEyes: some View {
        HStack(spacing: 16) {
            switch emotion {
            case .idle:
                cloudEye(size: 6)
                cloudEye(size: 6)
            case .happy:
                SmileEyeShape().stroke(lineWidth: 2).frame(width: 8, height: 5)
                    .foregroundColor(Color(hex: "5c6bc0"))
                SmileEyeShape().stroke(lineWidth: 2).frame(width: 8, height: 5)
                    .foregroundColor(Color(hex: "5c6bc0"))
            case .surprised:
                cloudEye(size: 9)
                cloudEye(size: 9)
            case .sleepy:
                Capsule().frame(width: 7, height: 2).foregroundColor(Color(hex: "5c6bc0"))
                Capsule().frame(width: 7, height: 2).foregroundColor(Color(hex: "5c6bc0"))
            }
        }
    }

    @ViewBuilder
    private func cloudEye(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .frame(width: size, height: isBlinking ? 1 : size)
                .foregroundColor(Color(hex: "5c6bc0"))
            if !isBlinking {
                Circle()
                    .frame(width: size * 0.4, height: size * 0.4)
                    .foregroundColor(Color(hex: "5c6bc0"))
                    .offset(x: pupilOffset.x * 0.4, y: pupilOffset.y * 0.3)
            }
        }
    }

    @ViewBuilder
    private var cloudMouth: some View {
        switch emotion {
        case .idle, .sleepy:
            Circle()
                .frame(width: 4, height: 4)
                .foregroundColor(Color(hex: "5c6bc0").opacity(0.4))
        case .happy:
            SmileEyeShape().stroke(lineWidth: 1.5).frame(width: 8, height: 4)
                .foregroundColor(Color(hex: "5c6bc0").opacity(0.5))
        case .surprised:
            Ellipse()
                .frame(width: 6, height: 8)
                .foregroundColor(Color(hex: "5c6bc0").opacity(0.4))
        }
    }

    private func startBlinkTimer() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 4...7), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) { isBlinking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) { isBlinking = false }
            }
        }
    }
}

// MARK: - Shapes

struct CloudBodyShape: Shape {
    var puff: CGFloat

    var animatableData: CGFloat {
        get { puff }
        set { puff = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let p = puff * 2

        // 하단 평평한 바닥
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.85))

        // 왼쪽 범프
        path.addCurve(
            to: CGPoint(x: w * 0.15, y: h * 0.4 - p),
            control1: CGPoint(x: -w * 0.05, y: h * 0.8),
            control2: CGPoint(x: -w * 0.02, y: h * 0.4)
        )

        // 왼쪽 상단 범프
        path.addCurve(
            to: CGPoint(x: w * 0.4, y: h * 0.1 - p),
            control1: CGPoint(x: w * 0.15, y: h * 0.1),
            control2: CGPoint(x: w * 0.25, y: -h * 0.05 - p)
        )

        // 중앙 상단 (가장 높은 범프)
        path.addCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.15 - p),
            control1: CGPoint(x: w * 0.5, y: -h * 0.1 - p),
            control2: CGPoint(x: w * 0.6, y: -h * 0.05 - p)
        )

        // 오른쪽 상단 범프
        path.addCurve(
            to: CGPoint(x: w * 0.9, y: h * 0.45 - p),
            control1: CGPoint(x: w * 0.82, y: h * 0.05),
            control2: CGPoint(x: w * 1.02, y: h * 0.35)
        )

        // 오른쪽 → 하단
        path.addCurve(
            to: CGPoint(x: w * 0.9, y: h * 0.85),
            control1: CGPoint(x: w * 1.05, y: h * 0.7),
            control2: CGPoint(x: w * 1.02, y: h * 0.85)
        )

        // 하단 직선
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.85))
        path.closeSubpath()

        return path
    }
}
