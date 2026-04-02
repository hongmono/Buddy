// Buddy/Models/BuddyCharacter.swift
import Foundation

enum CharacterAppearance: Codable, Equatable {
    case ghost          // 유령
    case cat            // 고양이
    case slime          // 슬라임
    case cloud          // 구름
    case image(String)  // PNG 파일 경로 (App Support 내 상대경로)

    /// 빌트인 캐릭터 목록
    static let builtinCases: [CharacterAppearance] = [.ghost, .cat, .slime, .cloud]

    var displayName: String {
        switch self {
        case .ghost: return "유령 👻"
        case .cat: return "고양이 🐱"
        case .slime: return "슬라임 🟢"
        case .cloud: return "구름 ☁️"
        case .image: return "커스텀 이미지"
        }
    }
}

struct BuddyCharacter: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var appearance: CharacterAppearance
    var personality: String  // AI system prompt에 쓸 성격 설명
    var scale: Double  // 1.0 = 기본(60x70), 0.5~2.0 범위

    init(id: UUID = UUID(), name: String = "Buddy", appearance: CharacterAppearance = .ghost, personality: String = "다정하고 장난기 있고, 약간 나른한 유령", scale: Double = 1.0) {
        self.id = id
        self.name = name
        self.appearance = appearance
        self.personality = personality
        self.scale = scale
    }

    /// 스케일 적용된 캐릭터 크기
    var characterSize: CGSize {
        CGSize(width: 60 * scale, height: 70 * scale)
    }
}
