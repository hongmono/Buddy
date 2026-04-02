// Buddy/Views/CharacterEditView.swift
import SwiftUI
import UniformTypeIdentifiers

struct CharacterEditInlineView: View {
    @State var character: BuddyCharacter
    let store: CharacterStore
    var onSave: (BuddyCharacter) -> Void
    var onPreview: ((BuddyCharacter) -> Void)?

    @State private var showingImagePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("이름")
                    .frame(width: 40, alignment: .leading)
                TextField("", text: $character.name, prompt: Text("이름"))
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("성격")
                    .frame(width: 40, alignment: .leading)
                TextField("", text: $character.personality, prompt: Text("성격"))
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("말풍선")
                    .frame(width: 40, alignment: .leading)
                Toggle("", isOn: $character.bubbleEnabled)
                    .labelsHidden()
                Text(character.bubbleEnabled ? "켜짐" : "꺼짐")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            HStack {
                Text("크기")
                    .frame(width: 40, alignment: .leading)
                Slider(value: $character.scale, in: 0.5...3.0, step: 0.1)
                Text("\(String(format: "%.1f", character.scale))x")
                    .frame(width: 35)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("외형")
                HStack(spacing: 6) {
                    ForEach(CharacterAppearance.builtinCases, id: \.displayName) { appearance in
                        Button {
                            character.appearance = appearance
                        } label: {
                            Text(appearance.displayName)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(character.appearance == appearance ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.15))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.borderless)
                    }
                    Button("PNG...") {
                        showingImagePicker = true
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
            }

            // PNG 이미지 옵션 (이미지일 때만 표시)
            if case .image = character.appearance {
                VStack(alignment: .leading, spacing: 4) {
                    Text("이미지 모양")
                    HStack(spacing: 4) {
                        ForEach(ImageShape.allCases, id: \.rawValue) { shape in
                            Button {
                                character.imageShape = shape
                            } label: {
                                Text(shape.displayName)
                                    .font(.caption2)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(character.imageShape == shape ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.15))
                                    .cornerRadius(3)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                HStack {
                    Text("줌")
                        .frame(width: 40, alignment: .leading)
                    Slider(value: $character.imageZoom, in: 1.0...3.0, step: 0.1)
                    Text("\(String(format: "%.1f", character.imageZoom))x")
                        .frame(width: 35)
                        .foregroundColor(.secondary)
                }

                // 드래그 프리뷰
                ImageCropPreview(character: $character)
            }

            HStack {
                Spacer()
                Button("저장") {
                    store.update(character)
                    onSave(character)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
        .onChange(of: character) { _, newValue in
            onPreview?(newValue)
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.png],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let filename = store.importImage(from: url) {
                        character.appearance = .image(filename)
                    }
                }
            }
        }
    }
}

/// 이미지 위에 마스크 영역을 드래그/리사이즈하는 크롭 프리뷰
struct ImageCropPreview: View {
    @Binding var character: BuddyCharacter

    private let previewSize: CGFloat = 180

    // 마스크 위치/크기를 픽셀 단위로 관리
    @State private var maskCenter: CGPoint = .zero
    @State private var maskSize: CGFloat = 80
    @State private var dragStart: CGPoint = .zero
    @State private var resizeStart: CGFloat = 0
    @State private var initialized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("영역 선택")
                    .font(.caption)
                Spacer()
                Button("초기화") {
                    maskCenter = CGPoint(x: previewSize / 2, y: previewSize / 2)
                    maskSize = previewSize * 0.6
                    syncToModel()
                }
                .font(.caption2)
                .buttonStyle(.borderless)
            }

            ZStack {
                // 1) 원본 이미지 (고정, 약간 어둡게)
                imageView
                    .frame(width: previewSize, height: previewSize)
                    .clipped()
                    .overlay(Color.black.opacity(0.5))

                // 2) 마스크 영역 안의 이미지 (밝게)
                imageView
                    .frame(width: previewSize, height: previewSize)
                    .clipped()
                    .mask(
                        maskShapeView
                            .frame(width: maskSize, height: maskSize)
                            .position(maskCenter)
                    )

                // 3) 마스크 테두리
                maskBorderView
                    .frame(width: maskSize, height: maskSize)
                    .position(maskCenter)

                // 4) 리사이즈 핸들 (우하단)
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .shadow(radius: 2)
                    .position(
                        x: maskCenter.x + maskSize / 2 - 2,
                        y: maskCenter.y + maskSize / 2 - 2
                    )
                    .gesture(resizeGesture)
            }
            .frame(width: previewSize, height: previewSize)
            .cornerRadius(8)
            .contentShape(Rectangle())
            .gesture(moveGesture)
            .frame(maxWidth: .infinity, alignment: .center)
            .onAppear { initFromModel() }
        }
    }

    // MARK: - Image

    @ViewBuilder
    private var imageView: some View {
        if case .image(let filename) = character.appearance,
           let nsImage = NSImage(contentsOf: CharacterStore.imagesDirectory.appendingPathComponent(filename)) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
        } else {
            Color.gray
        }
    }

    // MARK: - Mask Shape

    @ViewBuilder
    private var maskShapeView: some View {
        switch character.imageShape {
        case .none, .square:
            Rectangle()
        case .circle:
            Circle()
        case .rounded:
            RoundedRectangle(cornerRadius: maskSize * 0.2)
        case .star:
            StarShape(points: 5)
        }
    }

    @ViewBuilder
    private var maskBorderView: some View {
        switch character.imageShape {
        case .none, .square:
            Rectangle().stroke(Color.white.opacity(0.8), lineWidth: 1.5)
        case .circle:
            Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5)
        case .rounded:
            RoundedRectangle(cornerRadius: maskSize * 0.2).stroke(Color.white.opacity(0.8), lineWidth: 1.5)
        case .star:
            StarShape(points: 5).stroke(Color.white.opacity(0.8), lineWidth: 1.5)
        }
    }

    // MARK: - Gestures

    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if dragStart == .zero { dragStart = maskCenter }
                let newX = dragStart.x + value.translation.width
                let newY = dragStart.y + value.translation.height
                let half = maskSize / 2
                maskCenter.x = max(half, min(previewSize - half, newX))
                maskCenter.y = max(half, min(previewSize - half, newY))
                syncToModel()
            }
            .onEnded { _ in dragStart = .zero }
    }

    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if resizeStart == 0 { resizeStart = maskSize }
                // 대각선 드래그 → 크기 변경
                let delta = (value.translation.width + value.translation.height) / 2
                let newSize = max(30, min(previewSize, resizeStart + delta))
                maskSize = newSize
                // 마스크가 프리뷰 밖으로 나가지 않게 보정
                let half = maskSize / 2
                maskCenter.x = max(half, min(previewSize - half, maskCenter.x))
                maskCenter.y = max(half, min(previewSize - half, maskCenter.y))
                syncToModel()
            }
            .onEnded { _ in resizeStart = 0 }
    }

    // MARK: - Model Sync

    /// 마스크 → 모델 값 변환
    private func syncToModel() {
        // zoom = 프리뷰 전체 / 마스크 크기
        character.imageZoom = Double(previewSize / maskSize)
        // offset = 마스크 중심이 프리뷰 중심에서 얼마나 벗어났는지 (-1~1)
        let centerX = previewSize / 2
        let centerY = previewSize / 2
        character.imageOffsetX = Double((maskCenter.x - centerX) / (previewSize / 2)) * -1
        character.imageOffsetY = Double((maskCenter.y - centerY) / (previewSize / 2)) * -1
    }

    /// 모델 → 마스크 초기값
    private func initFromModel() {
        guard !initialized else { return }
        initialized = true
        let zoom = CGFloat(max(1, character.imageZoom))
        maskSize = previewSize / zoom
        let centerX = previewSize / 2
        let centerY = previewSize / 2
        maskCenter = CGPoint(
            x: centerX - CGFloat(character.imageOffsetX) * (previewSize / 2),
            y: centerY - CGFloat(character.imageOffsetY) * (previewSize / 2)
        )
    }
}
