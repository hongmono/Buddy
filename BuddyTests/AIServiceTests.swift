// BuddyTests/AIServiceTests.swift
import XCTest
@testable import Buddy

final class AIServiceTests: XCTestCase {
    func testBuildBubbleRequest() {
        let service = AIService(apiKey: "test-key")
        let request = service.buildBubbleRequest(context: "사용자가 Xcode를 열었음")

        XCTAssertEqual(request.url?.host, "api.anthropic.com")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-api-key"), "test-key")

        let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        XCTAssertEqual(body["max_tokens"] as? Int, 100)
        let messages = body["messages"] as! [[String: String]]
        XCTAssertTrue(messages.last?["content"]?.contains("Xcode") ?? false)
    }

    func testBuildChatRequest() {
        let service = AIService(apiKey: "test-key")
        let history = [
            ChatMessage(role: .user, content: "안녕"),
            ChatMessage(role: .assistant, content: "안녕! 반가워~"),
        ]
        let request = service.buildChatRequest(messages: history, newMessage: "뭐해?")

        let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        let messages = body["messages"] as! [[String: String]]
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(body["max_tokens"] as? Int, 500)
    }

    func testParseResponse() {
        let service = AIService(apiKey: "test-key")
        let json = """
        {
            "content": [{"type": "text", "text": "안녕하세요!"}],
            "stop_reason": "end_turn"
        }
        """.data(using: .utf8)!
        let text = service.parseResponseText(from: json)
        XCTAssertEqual(text, "안녕하세요!")
    }
}
