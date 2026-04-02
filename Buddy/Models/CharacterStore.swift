// Buddy/Models/CharacterStore.swift
import Foundation

class CharacterStore: ObservableObject {
    @Published var characters: [BuddyCharacter] = []

    private static var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Buddy", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("characters.json")
    }

    /// App Support/Buddy/Images/ 디렉토리 (PNG 저장용)
    static var imagesDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Buddy/Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        load()
        if characters.isEmpty {
            characters = [BuddyCharacter()]
            save()
        }
    }

    static let maxCharacters = 5

    func add(_ character: BuddyCharacter) {
        guard characters.count < Self.maxCharacters else { return }
        characters.append(character)
        save()
    }

    func update(_ character: BuddyCharacter) {
        guard let idx = characters.firstIndex(where: { $0.id == character.id }) else { return }
        characters[idx] = character
        save()
    }

    func remove(id: UUID) {
        guard characters.count > 1 else { return }
        if let char = characters.first(where: { $0.id == id }),
           case .image(let path) = char.appearance {
            let fileURL = Self.imagesDirectory.appendingPathComponent(path)
            try? FileManager.default.removeItem(at: fileURL)
        }
        characters.removeAll { $0.id == id }
        save()
    }

    func importImage(from sourceURL: URL) -> String? {
        let filename = "\(UUID().uuidString).png"
        let dest = Self.imagesDirectory.appendingPathComponent(filename)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: dest)
            return filename
        } catch {
            print("Image import failed: \(error)")
            return nil
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(characters) else { return }
        try? data.write(to: Self.fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let decoded = try? JSONDecoder().decode([BuddyCharacter].self, from: data) else { return }
        characters = decoded
    }
}
