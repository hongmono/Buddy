// Buddy/Engine/BuddyCommand.swift
import Foundation

/// 캐릭터에게 내리는 명령
enum BuddyCommand: String {
    // 단일 캐릭터 행동
    case comeHere           // 커서 위치로 이동
    case goAway             // 커서 반대 방향으로 이동
    case stop               // 제자리 고정
    case wander             // 자유 이동 재개
    case sleep              // 졸린 상태 + 멈춤
    case wakeUp             // 깨어남 + 이동 재개
    case dance              // 특수 애니메이션

    // 멀티 캐릭터
    case gather             // 모든 캐릭터 한 곳으로
    case scatter            // 모두 흩어짐
    case goToCharacter      // 특정 캐릭터에게 이동

    /// 명령에 대한 리액션
    var reaction: (text: String, emotion: Emotion) {
        switch self {
        case .comeHere: return ("가는 중~!", .happy)
        case .goAway: return ("에잇... 알았어", .idle)
        case .stop: return ("멈!", .idle)
        case .wander: return ("다시 돌아다닐게~", .happy)
        case .sleep: return ("zzZ...", .sleepy)
        case .wakeUp: return ("음냐... 일어났다!", .surprised)
        case .dance: return ("신난다~! 🎵", .happy)
        case .gather: return ("모여라~!", .happy)
        case .scatter: return ("흩어져~!", .surprised)
        case .goToCharacter: return ("가는 중!", .happy)
        }
    }

    /// 이 명령이 모든 캐릭터에 적용되는지
    var isGlobal: Bool {
        switch self {
        case .gather, .scatter: return true
        default: return false
        }
    }
}
