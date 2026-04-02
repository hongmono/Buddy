// Buddy/Models/BuddyCharacter.swift
import Foundation

/// PNG 이미지 표시 모양
enum ImageShape: String, Codable, CaseIterable, Equatable {
    case none       // 원본 그대로
    case circle     // 원형
    case rounded    // 둥근 네모
    case square     // 정사각형
    case star       // 별

    var displayName: String {
        switch self {
        case .none: return "원본"
        case .circle: return "원 ●"
        case .rounded: return "둥근네모 ▢"
        case .square: return "네모 ■"
        case .star: return "별 ★"
        }
    }
}

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
    var scale: Double  // 1.0 = 기본(60x70), 0.5~3.0 범위

    // 이미지 표시 설정 (appearance가 .image일 때만 유효)
    var imageShape: ImageShape
    var imageZoom: Double    // 1.0 = 원본, 2.0 = 2배 확대 (중앙 기준 크롭)
    var imageOffsetX: Double // 이미지 내 표시 위치 X (-1.0 ~ 1.0)
    var imageOffsetY: Double // 이미지 내 표시 위치 Y (-1.0 ~ 1.0)

    var bubbleEnabled: Bool  // 말풍선 표시 여부

    init(id: UUID = UUID(), name: String = "Buddy", appearance: CharacterAppearance = .ghost, personality: String = "다정하고 장난기 있고, 약간 나른한 유령", scale: Double = 1.0, imageShape: ImageShape = .none, imageZoom: Double = 1.0, imageOffsetX: Double = 0, imageOffsetY: Double = 0, bubbleEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.appearance = appearance
        self.personality = personality
        self.scale = scale
        self.imageShape = imageShape
        self.imageZoom = imageZoom
        self.imageOffsetX = imageOffsetX
        self.imageOffsetY = imageOffsetY
        self.bubbleEnabled = bubbleEnabled
    }

    /// 스케일 적용된 캐릭터 크기
    var characterSize: CGSize {
        CGSize(width: 60 * scale, height: 70 * scale)
    }
}
