// Buddy/Views/CharacterListView.swift
import SwiftUI

struct CharacterListView: View {
    @ObservedObject var store: CharacterStore
    @State private var selectedCharacter: BuddyCharacter?
    @State private var showingEdit = false

    var onCharacterAdded: ((BuddyCharacter) -> Void)?
    var onCharacterRemoved: ((UUID) -> Void)?
    var onCharacterUpdated: ((BuddyCharacter) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(store.characters) { character in
                HStack {
                    characterIcon(character)
                    Text(character.name)
                    Spacer()
                    Button("편집") {
                        selectedCharacter = character
                        showingEdit = true
                    }
                    .buttonStyle(.borderless)
                    if store.characters.count > 1 {
                        Button(role: .destructive) {
                            store.remove(id: character.id)
                            onCharacterRemoved?(character.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 2)
            }

            if store.characters.count < CharacterStore.maxCharacters {
                Button {
                    let new = BuddyCharacter(name: "New Buddy")
                    store.add(new)
                    onCharacterAdded?(new)
                } label: {
                    Label("캐릭터 추가", systemImage: "plus")
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let char = selectedCharacter {
                CharacterEditView(character: char, store: store, onSave: { updated in
                    onCharacterUpdated?(updated)
                    showingEdit = false
                }, onDismiss: {
                    showingEdit = false
                })
            }
        }
    }

    @ViewBuilder
    private func characterIcon(_ character: BuddyCharacter) -> some View {
        switch character.appearance {
        case .ghost:
            Image(systemName: "ghost.fill")
                .foregroundColor(.cyan)
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
