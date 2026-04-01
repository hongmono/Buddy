// Buddy/Services/AIService.swift
import Foundation

class AIService {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-haiku-4-5-20251001"

    private let systemPrompt = """
    너는 "Buddy"라는 이름의 귀여운 유령 캐릭터야. macOS 화면에 살고 있어.
    성격: 다정하고 장난기 있고, 약간 나른한 유령. 이모지를 가끔 쓰고, 반말로 짧게 말해.
    말풍선용 응답은 1-2문장으로 아주 짧게. 채팅은 자연스럽게 대화해.
    """

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func buildBubbleRequest(context: String) -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 100,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "현재 상황: \(context). 이 상황에 맞는 짧은 한마디를 해줘. 감정도 하나 골라줘 (idle/happy/surprised/sleepy). 형식: {감정}|{대사}"]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    func buildChatRequest(messages: [ChatMessage], newMessage: String) -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        var apiMessages: [[String: String]] = messages.map { msg in
            ["role": msg.role == .user ? "user" : "assistant", "content": msg.content]
        }
        apiMessages.append(["role": "user", "content": newMessage])

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 500,
            "system": systemPrompt,
            "messages": apiMessages
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    func parseResponseText(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            return nil
        }
        return text
    }

    func generateBubble(context: String) async -> (text: String, emotion: Emotion)? {
        let request = buildBubbleRequest(context: context)
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let response = parseResponseText(from: data) else {
            return nil
        }
        let parts = response.split(separator: "|", maxSplits: 1)
        if parts.count == 2 {
            let emotion = Emotion(rawValue: String(parts[0])) ?? .idle
            return (text: String(parts[1]), emotion: emotion)
        }
        return (text: response, emotion: .idle)
    }

    func chat(messages: [ChatMessage], newMessage: String) async -> String? {
        let request = buildChatRequest(messages: messages, newMessage: newMessage)
        guard let (data, _) = try? await URLSession.shared.data(for: request) else {
            return nil
        }
        return parseResponseText(from: data)
    }
}
