// Buddy/Views/CatView.swift
import SwiftUI

struct CatView: View {
    let emotion: Emotion
    var lookOffset: CGPoint = .zero

    @State private var tailPhase: CGFloat = 0
    @State private var isBlinking: Bool = false

    var body: some View {
        ZStack {
            // 꼬리
            CatTailShape(phase: tailPhase)
                .stroke(Color(hex: "f5a623"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 60, height: 70)
                .offset(x: 22, y: 10)

            // 몸체
            CatBodyShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "f5a623"), Color(hex: "e8912d")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)

            // 귀
            CatEarShape()
                .fill(Color(hex: "f5a623"))
                .frame(width: 56, height: 20)
                .offset(y: -30)

            // 귀 안쪽
            CatEarInnerShape()
                .fill(Color(hex: "ffcdd2"))
                .frame(width: 40, height: 12)
                .offset(y: -28)

            // 눈
            catEyes
                .offset(y: -6)

            // 코
            Ellipse()
                .frame(width: 5, height: 4)
                .foregroundColor(Color(hex: "d4845a"))
                .offset(y: 4)

            // 입
            catMouth
                .offset(y: 8)

            // 수염
            whiskers
                .offset(y: 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                tailPhase = 1
            }
            startBlinkTimer()
        }
    }

    private var pupilOffset: CGPoint {
        CGPoint(x: lookOffset.x * 2.5, y: lookOffset.y * -2)
    }

    @ViewBuilder
    private var catEyes: some View {
        HStack(spacing: 14) {
            switch emotion {
            case .idle:
                catEye(size: 8)
                catEye(size: 8)
            case .happy:
                SmileEyeShape().stroke(lineWidth: 2).frame(width: 8, height: 5)
                    .foregroundColor(Color(hex: "1a1a2e"))
                SmileEyeShape().stroke(lineWidth: 2).frame(width: 8, height: 5)
                    .foregroundColor(Color(hex: "1a1a2e"))
            case .surprised:
                catEye(size: 11)
                catEye(size: 11)
            case .sleepy:
                Capsule().frame(width: 8, height: 2).foregroundColor(Color(hex: "1a1a2e"))
                Capsule().frame(width: 8, height: 2).foregroundColor(Color(hex: "1a1a2e"))
            }
        }
    }

    @ViewBuilder
    private func catEye(size: CGFloat) -> some View {
        ZStack {
            // 눈 전체 (세로로 긴 타원)
            Ellipse()
                .frame(width: size * 0.9, height: isBlinking ? 1 : size)
                .foregroundColor(Color(hex: "4a6741"))
            if !isBlinking {
                // 세로 동공
                Capsule()
                    .frame(width: 2, height: size * 0.6)
                    .foregroundColor(Color(hex: "1a1a2e"))
                    .offset(x: pupilOffset.x * 0.5, y: pupilOffset.y * 0.3)
            }
        }
    }

    @ViewBuilder
    private var catMouth: some View {
        switch emotion {
        case .idle, .sleepy:
            // W 모양 입
            CatMouthShape()
                .stroke(Color(hex: "1a1a2e").opacity(0.5), lineWidth: 1.5)
                .frame(width: 10, height: 4)
        case .happy:
            CatMouthShape()
                .stroke(Color(hex: "1a1a2e").opacity(0.6), lineWidth: 1.5)
                .frame(width: 12, height: 5)
        case .surprised:
            Ellipse()
                .frame(width: 6, height: 8)
                .foregroundColor(Color(hex: "1a1a2e").opacity(0.5))
        }
    }

    private var whiskers: some View {
        ZStack {
            // 왼쪽 수염
            WhiskerShape(side: .left)
                .stroke(Color(hex: "1a1a2e").opacity(0.3), lineWidth: 1)
                .frame(width: 60, height: 16)
            // 오른쪽 수염
            WhiskerShape(side: .right)
                .stroke(Color(hex: "1a1a2e").opacity(0.3), lineWidth: 1)
                .frame(width: 60, height: 16)
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

struct CatBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: rect.width * 0.4, height: rect.height * 0.4))
        return path
    }
}

struct CatEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // 왼쪽 귀
        path.move(to: CGPoint(x: rect.width * 0.1, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * 0.2, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.4, y: rect.height))
        // 오른쪽 귀
        path.move(to: CGPoint(x: rect.width * 0.6, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * 0.8, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.9, y: rect.height))
        return path
    }
}

struct CatEarInnerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.08, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * 0.2, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.height))
        path.move(to: CGPoint(x: rect.width * 0.65, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * 0.8, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.92, y: rect.height))
        return path
    }
}

struct CatTailShape: Shape {
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sway = phase * 8
        path.move(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.7))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.8 + sway, y: rect.height * 0.1),
            control1: CGPoint(x: rect.width * 0.6, y: rect.height * 0.9),
            control2: CGPoint(x: rect.width * 0.9 + sway, y: rect.height * 0.4)
        )
        return path
    }
}

struct CatMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // W 모양
        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.height), control: CGPoint(x: rect.width * 0.25, y: rect.height * 0.8))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: 0), control: CGPoint(x: rect.width * 0.75, y: rect.height * 0.8))
        return path
    }
}

enum WhiskerSide { case left, right }

struct WhiskerShape: Shape {
    let side: WhiskerSide

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let isLeft = side == .left
        let startX = isLeft ? rect.midX - 2 : rect.midX + 2
        let endX = isLeft ? 0 : rect.width

        // 위 수염
        path.move(to: CGPoint(x: startX, y: rect.height * 0.3))
        path.addLine(to: CGPoint(x: endX, y: rect.height * 0.1))
        // 아래 수염
        path.move(to: CGPoint(x: startX, y: rect.height * 0.6))
        path.addLine(to: CGPoint(x: endX, y: rect.height * 0.7))

        return path
    }
}
