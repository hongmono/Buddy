// Buddy/Views/BlobView.swift
import SwiftUI

struct BlobView: View {
    let emotion: Emotion
    var lookOffset: CGPoint = .zero  // 눈동자가 바라보는 방향 (-1~1)

    @State private var wavePhase: CGFloat = 0
    @State private var isBlinking: Bool = false

    var body: some View {
        ZStack {
            // Ghost body
            GhostBodyShape(wavePhase: wavePhase)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "a8edea"), Color(hex: "7dd3cc")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 70)

            // Eyes
            eyesView
                .offset(y: -8)

            // Mouth
            mouthView
                .offset(y: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                wavePhase = 1
            }
            startBlinkTimer()
        }
    }

    // 눈동자 오프셋 (최대 3pt)
    private var pupilOffset: CGPoint {
        CGPoint(
            x: lookOffset.x * 3,
            y: lookOffset.y * -2  // macOS 좌표계 보정
        )
    }

    @ViewBuilder
    private var eyesView: some View {
        HStack(spacing: 16) {
            switch emotion {
            case .idle:
                // 나른한 눈 + 눈동자
                ZStack {
                    Capsule()
                        .frame(width: 12, height: isBlinking ? 1 : 5)
                        .foregroundColor(Color(hex: "1a1a2e"))
                    if !isBlinking {
                        Circle()
                            .frame(width: 3, height: 3)
                            .foregroundColor(Color(hex: "1a1a2e"))
                            .offset(x: pupilOffset.x, y: pupilOffset.y)
                    }
                }
                ZStack {
                    Capsule()
                        .frame(width: 12, height: isBlinking ? 1 : 5)
                        .foregroundColor(Color(hex: "1a1a2e"))
                    if !isBlinking {
                        Circle()
                            .frame(width: 3, height: 3)
                            .foregroundColor(Color(hex: "1a1a2e"))
                            .offset(x: pupilOffset.x, y: pupilOffset.y)
                    }
                }

            case .happy:
                SmileEyeShape().stroke(lineWidth: 2).frame(width: 10, height: 6)
                    .foregroundColor(Color(hex: "1a1a2e"))
                SmileEyeShape().stroke(lineWidth: 2).frame(width: 10, height: 6)
                    .foregroundColor(Color(hex: "1a1a2e"))

            case .surprised:
                // 동그란 눈 + 눈동자
                ZStack {
                    Circle()
                        .stroke(Color(hex: "1a1a2e"), lineWidth: 2)
                        .frame(width: isBlinking ? 10 : 12, height: isBlinking ? 2 : 12)
                    if !isBlinking {
                        Circle()
                            .frame(width: 4, height: 4)
                            .foregroundColor(Color(hex: "1a1a2e"))
                            .offset(x: pupilOffset.x, y: pupilOffset.y)
                    }
                }
                ZStack {
                    Circle()
                        .stroke(Color(hex: "1a1a2e"), lineWidth: 2)
                        .frame(width: isBlinking ? 10 : 12, height: isBlinking ? 2 : 12)
                    if !isBlinking {
                        Circle()
                            .frame(width: 4, height: 4)
                            .foregroundColor(Color(hex: "1a1a2e"))
                            .offset(x: pupilOffset.x, y: pupilOffset.y)
                    }
                }

            case .sleepy:
                Capsule().frame(width: 10, height: 2)
                    .foregroundColor(Color(hex: "1a1a2e"))
                Capsule().frame(width: 10, height: 2)
                    .foregroundColor(Color(hex: "1a1a2e"))
            }
        }
    }

    @ViewBuilder
    private var mouthView: some View {
        switch emotion {
        case .idle, .sleepy:
            Circle()
                .frame(width: 5, height: 5)
                .foregroundColor(Color(hex: "1a1a2e").opacity(0.5))
        case .happy:
            Capsule()
                .frame(width: 8, height: 4)
                .foregroundColor(Color(hex: "1a1a2e").opacity(0.6))
        case .surprised:
            Ellipse()
                .frame(width: 8, height: 10)
                .foregroundColor(Color(hex: "1a1a2e").opacity(0.6))
        }
    }

    private func startBlinkTimer() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...6), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                isBlinking = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isBlinking = false
                }
            }
        }
    }
}

// Ghost body shape - round top, wavy bottom
struct GhostBodyShape: Shape {
    var wavePhase: CGFloat

    var animatableData: CGFloat {
        get { wavePhase }
        set { wavePhase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let waveHeight: CGFloat = 6

        path.move(to: CGPoint(x: 0, y: h * 0.45))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.45),
            control1: CGPoint(x: 0, y: -h * 0.1),
            control2: CGPoint(x: w, y: -h * 0.1)
        )

        path.addLine(to: CGPoint(x: w, y: h - waveHeight))

        let waveOffset = wavePhase * 4
        let segments = 5
        let segmentWidth = w / CGFloat(segments)
        for i in (0..<segments).reversed() {
            let xStart = segmentWidth * CGFloat(i + 1)
            let xEnd = segmentWidth * CGFloat(i)
            let yTip = h - waveHeight + (i % 2 == 0 ? waveOffset : -waveOffset + waveHeight)
            path.addCurve(
                to: CGPoint(x: xEnd, y: h - waveHeight),
                control1: CGPoint(x: xStart - segmentWidth * 0.3, y: yTip),
                control2: CGPoint(x: xEnd + segmentWidth * 0.3, y: yTip)
            )
        }

        path.closeSubpath()
        return path
    }
}

struct BuddyContentView: View {
    let emotion: Emotion
    let bubbleText: String?
    var lookOffset: CGPoint = .zero
    var appearance: CharacterAppearance = .ghost
    var scale: Double = 1.0

    private var charWidth: CGFloat { 60 * CGFloat(scale) }
    private var charHeight: CGFloat { 70 * CGFloat(scale) }

    var body: some View {
        VStack(spacing: 4) {
            if let text = bubbleText {
                SpeechBubbleView(text: text, isVisible: true)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.3), value: bubbleText)
            }
            characterView
        }
        .frame(maxWidth: 300, maxHeight: max(200, charHeight + 130), alignment: .bottom)
    }

    @ViewBuilder
    private var characterView: some View {
        switch appearance {
        case .ghost:
            BlobView(emotion: emotion, lookOffset: lookOffset)
                .scaleEffect(CGFloat(scale))
                .frame(width: charWidth, height: charHeight)
        case .image(let filename):
            let url = CharacterStore.imagesDirectory.appendingPathComponent(filename)
            if let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: charWidth, height: charHeight)
            } else {
                BlobView(emotion: emotion, lookOffset: lookOffset)
                    .scaleEffect(CGFloat(scale))
                    .frame(width: charWidth, height: charHeight)
            }
        }
    }
}

// Smile eye shape for happy emotion
struct SmileEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: 0),
            control: CGPoint(x: rect.width / 2, y: rect.height)
        )
        return path
    }
}
