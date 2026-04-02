// Buddy/Views/CharacterEditView.swift
import SwiftUI
import UniformTypeIdentifiers

struct CharacterEditView: View {
    @State var character: BuddyCharacter
    let store: CharacterStore
    var onSave: (BuddyCharacter) -> Void
    var onDismiss: (() -> Void)?

    @State private var showingImagePicker = false

    var body: some View {
        VStack(spacing: 16) {
            Text("캐릭터 편집")
                .font(.headline)

            Form {
                TextField("이름", text: $character.name)
                TextField("성격", text: $character.personality)

                HStack {
                    Text("외형")
                    Spacer()
                    switch character.appearance {
                    case .ghost:
                        Text("기본 유령 👻")
                    case .image:
                        Text("커스텀 이미지")
                    }
                }

                HStack {
                    Button("기본 유령으로") {
                        character.appearance = .ghost
                    }
                    Button("PNG 이미지 선택...") {
                        showingImagePicker = true
                    }
                }
            }

            HStack {
                Button("취소") {
                    onDismiss?()
                }
                Spacer()
                Button("저장") {
                    store.update(character)
                    onSave(character)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 350, height: 280)
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
