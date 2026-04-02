// Buddy/Services/OnDeviceAIService.swift
import Foundation
import FoundationModels

/// Apple Intelligence를 사용한 온디바이스 AI 서비스
@available(macOS 26.0, *)
class OnDeviceAIService {

    // MARK: - Generable Types

    @Generable
    struct IntentAnalysis {
        @Guide(description: "사용자 입력이 캐릭터에 대한 명령인지 판별. 명령이면 true")
        var isCommand: Bool

        @Guide(description: "명령 타입. comeHere/goAway/stop/wander/sleep/wakeUp/dance/gather/scatter/goToCharacter 중 하나. 명령이 아니면 nil")
        var commandType: String?

        @Guide(description: "goToCharacter일 때 대상 캐릭터 이름")
        var targetCharacterName: String?

        @Guide(description: "Claude 같은 고급 AI가 필요한 복잡한 대화인지. 간단한 인사나 질문은 false, 깊은 대화나 설명이 필요하면 true")
        var needsComplexAI: Bool

        @Guide(description: "명령이거나 간단한 대화일 때 캐릭터의 짧은 반응 (1-2문장, 반말, 귀여운 말투). 복잡한 대화면 nil")
        var simpleResponse: String?
    }

    private var session: LanguageModelSession?

    func createSession(characterName: String, personality: String) {
        session = LanguageModelSession {
            """
            너는 "\(characterName)"라는 귀여운 캐릭터야. 성격: \(personality).
            사용자가 말하면 그게 명령인지 대화인지 판별해.

            명령 종류:
            - comeHere: "이리 와", "이쪽으로", "와봐" 등
            - goAway: "저리 가", "가버려", "꺼져" 등
            - stop: "멈춰", "그만", "스톱" 등
            - wander: "돌아다녀", "자유롭게", "움직여" 등
            - sleep: "자", "잠자", "꿈나라" 등
            - wakeUp: "일어나", "깨어나", "기상" 등
            - dance: "춤춰", "댄스", "흔들어" 등
            - gather: "모여", "집합", "다 모여" 등
            - scatter: "흩어져", "해산", "각자" 등
            - goToCharacter: "[이름]한테 가", "[이름]에게 가" 등

            간단한 인사, 기분 물어보기, 짧은 대화는 직접 응답해 (needsComplexAI=false).
            복잡한 질문, 설명 요청, 긴 대화가 필요하면 needsComplexAI=true.
            """
        }
    }

    /// 사용자 입력 의도 분석
    func analyzeIntent(_ text: String) async -> IntentResult {
        guard let session = session else {
            return .chat(needsComplexAI: true, simpleResponse: nil)
        }

        do {
            let response = try await session.respond(
                to: "사용자 입력: \"\(text)\"",
                generating: IntentAnalysis.self
            )
            let analysis = response.content

            if analysis.isCommand, let typeStr = analysis.commandType,
               let command = BuddyCommand(rawValue: typeStr) {
                return .command(
                    command: command,
                    targetName: analysis.targetCharacterName,
                    reaction: analysis.simpleResponse
                )
            } else {
                return .chat(
                    needsComplexAI: analysis.needsComplexAI,
                    simpleResponse: analysis.simpleResponse
                )
            }
        } catch {
            print("OnDeviceAI error: \(error)")
            return .chat(needsComplexAI: true, simpleResponse: nil)
        }
    }

    /// 간단한 대화 응답 생성
    func generateSimpleResponse(_ text: String) async -> String? {
        guard let session = session else { return nil }
        do {
            let response = try await session.respond(to: text)
            return response.content
        } catch {
            return nil
        }
    }

    static var isAvailable: Bool {
        true // macOS 26+ 에서 이 코드가 실행됨
    }
}

/// 의도 분석 결과
enum IntentResult {
    case command(command: BuddyCommand, targetName: String?, reaction: String?)
    case chat(needsComplexAI: Bool, simpleResponse: String?)
}
