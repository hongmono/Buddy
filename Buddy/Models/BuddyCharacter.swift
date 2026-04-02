// Buddy/Models/BuddyCharacter.swift
import Foundation

enum CharacterAppearance: Codable, Equatable {
    case ghost          // 기본 SwiftUI 유령
    case image(String)  // PNG 파일 경로 (App Support 내 상대경로)
}

struct BuddyCharacter: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var appearance: CharacterAppearance
    var personality: String  // AI system prompt에 쓸 성격 설명

    init(id: UUID = UUID(), name: String = "Buddy", appearance: CharacterAppearance = .ghost, personality: String = "다정하고 장난기 있고, 약간 나른한 유령") {
        self.id = id
        self.name = name
        self.appearance = appearance
        self.personality = personality
    }
}
