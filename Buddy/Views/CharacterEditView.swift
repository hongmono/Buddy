// Buddy/Views/CharacterEditView.swift
import SwiftUI
import UniformTypeIdentifiers

struct CharacterEditInlineView: View {
    @State var character: BuddyCharacter
    let store: CharacterStore
    var onSave: (BuddyCharacter) -> Void

    @State private var showingImagePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("이름")
                    .frame(width: 40, alignment: .leading)
                TextField("이름", text: $character.name)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("성격")
                    .frame(width: 40, alignment: .leading)
                TextField("성격", text: $character.personality)
                    .textFieldStyle(.roundedBorder)
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

/// 이미지 위치를 드래그로 조정하는 프리뷰
struct ImageCropPreview: View {
    @Binding var character: BuddyCharacter
    @State private var dragStartOffset: (x: Double, y: Double) = (0, 0)

    private let previewSize: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("위치 조정")
                    .font(.caption)
                Spacer()
                Button("초기화") {
                    character.imageOffsetX = 0
                    character.imageOffsetY = 0
                }
                .font(.caption2)
                .buttonStyle(.borderless)
            }

            // 프리뷰 + 드래그 영역
            ZStack {
                // 배경
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))

                // 이미지 프리뷰 (실제 결과와 동일하게 렌더링)
                if case .image(let filename) = character.appearance,
                   let nsImage = NSImage(contentsOf: CharacterStore.imagesDirectory.appendingPathComponent(filename)) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(CGFloat(character.imageZoom))
                        .offset(
                            x: CGFloat(character.imageOffsetX) * previewSize * 0.3,
                            y: CGFloat(character.imageOffsetY) * previewSize * 0.3
                        )
                        .frame(width: previewSize - 16, height: previewSize - 16)
                        .mask(previewClipShape.frame(width: previewSize - 16, height: previewSize - 16))
                }

                // "드래그" 힌트
                if character.imageOffsetX == 0 && character.imageOffsetY == 0 {
                    Text("드래그하여 위치 조정")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(width: previewSize, height: previewSize)
            .cornerRadius(8)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let sensitivity: CGFloat = 2.0 / previewSize
                        let newX = dragStartOffset.x + Double(value.translation.width * sensitivity)
                        let newY = dragStartOffset.y + Double(value.translation.height * sensitivity)
                        character.imageOffsetX = max(-1, min(1, newX))
                        character.imageOffsetY = max(-1, min(1, newY))
                    }
                    .onEnded { _ in
                        dragStartOffset = (character.imageOffsetX, character.imageOffsetY)
                    }
            )
            .onAppear {
                dragStartOffset = (character.imageOffsetX, character.imageOffsetY)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private var previewClipShape: some View {
        switch character.imageShape {
        case .none:
            Rectangle()
        case .circle:
            Circle()
        case .rounded:
            RoundedRectangle(cornerRadius: (previewSize - 16) * 0.2)
        case .square:
            Rectangle()
        case .star:
            StarShape(points: 5)
        }
    }
}
