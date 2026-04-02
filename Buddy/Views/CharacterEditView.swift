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

                HStack {
                    Text("위치X")
                        .frame(width: 40, alignment: .leading)
                    Slider(value: $character.imageOffsetX, in: -1.0...1.0, step: 0.05)
                }

                HStack {
                    Text("위치Y")
                        .frame(width: 40, alignment: .leading)
                    Slider(value: $character.imageOffsetY, in: -1.0...1.0, step: 0.05)
                }
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
