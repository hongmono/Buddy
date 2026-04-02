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
                Text("외형")
                    .frame(width: 40, alignment: .leading)
                switch character.appearance {
                case .ghost:
                    Text("기본 유령 👻")
                        .foregroundColor(.secondary)
                case .image:
                    Text("커스텀 이미지")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("유령") {
                    character.appearance = .ghost
                }
                .buttonStyle(.borderless)
                Button("PNG 선택...") {
                    showingImagePicker = true
                }
                .buttonStyle(.borderless)
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
