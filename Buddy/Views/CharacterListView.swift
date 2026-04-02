// Buddy/Views/CharacterListView.swift
import SwiftUI

struct CharacterListView: View {
    @ObservedObject var store: CharacterStore
    @State private var editingCharacterId: UUID?

    var onCharacterAdded: ((BuddyCharacter) -> Void)?
    var onCharacterRemoved: ((UUID) -> Void)?
    var onCharacterUpdated: ((BuddyCharacter) -> Void)?
    var onCharacterPreview: ((BuddyCharacter) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(store.characters) { character in
                VStack(spacing: 0) {
                    HStack {
                        characterIcon(character)
                        Text(character.name)
                        Spacer()
                        Button(editingCharacterId == character.id ? "닫기" : "편집") {
                            withAnimation {
                                if editingCharacterId == character.id {
                                    editingCharacterId = nil
                                } else {
                                    editingCharacterId = character.id
                                }
                            }
                        }
                        .buttonStyle(.borderless)
                        if store.characters.count > 1 {
                            Button(role: .destructive) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    store.remove(id: character.id)
                                }
                                onCharacterRemoved?(character.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.vertical, 2)

                    if editingCharacterId == character.id {
                        CharacterEditInlineView(
                            character: character,
                            store: store,
                            onSave: { updated in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    editingCharacterId = nil
                                }
                                onCharacterUpdated?(updated)
                            },
                            onPreview: { updated in
                                onCharacterPreview?(updated)
                            }
                        )
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            if store.characters.count < CharacterStore.maxCharacters {
                Button {
                    let new = BuddyCharacter(name: "New Buddy")
                    withAnimation(.easeInOut(duration: 0.25)) {
                        store.add(new)
                    }
                    onCharacterAdded?(new)
                } label: {
                    Label("캐릭터 추가", systemImage: "plus")
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func characterIcon(_ character: BuddyCharacter) -> some View {
        switch character.appearance {
        case .ghost:
            Text("👻").font(.caption)
        case .cat:
            Text("🐱").font(.caption)
        case .slime:
            Text("🟢").font(.caption)
        case .cloud:
            Text("☁️").font(.caption)
        case .image(let filename):
            let url = CharacterStore.imagesDirectory.appendingPathComponent(filename)
            if let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }
        }
    }
}
