// Buddy/Services/AIService.swift
import Foundation

class AIService {
    private var process: Process?
    private var stdinPipe: Pipe?
    private var lineBuffer = ""
    private var isBusy = false

    private var responseCallback: ((String) -> Void)?

    private let systemPrompt = """
    너는 "Buddy"라는 이름의 귀여운 유령 캐릭터야. macOS 화면에 살고 있어.
    성격: 다정하고 장난기 있고, 약간 나른한 유령. 이모지를 가끔 쓰고, 반말로 짧게 말해.
    말풍선용 응답은 1-2문장으로 아주 짧게. 채팅은 자연스럽게 대화해.
    """

    private static var claudePath: String?

    // Claude CLI 바이너리 찾기
    static func findClaude(completion: @escaping (String?) -> Void) {
        if let cached = claudePath {
            completion(cached)
            return
        }
        ShellEnvironment.findBinary(
            name: "claude",
            fallbackPaths: [
                "\(FileManager.default.homeDirectoryForCurrentUser.path)/.local/bin/claude",
                "\(FileManager.default.homeDirectoryForCurrentUser.path)/.claude/local/bin/claude",
                "/usr/local/bin/claude",
                "/opt/homebrew/bin/claude"
            ]
        ) { path in
            claudePath = path
            completion(path)
        }
    }

    func start(completion: @escaping (Bool) -> Void) {
        Self.findClaude { [weak self] path in
            guard let self = self, let claudeBinary = path else {
                completion(false)
                return
            }
            self.launchProcess(binary: claudeBinary)
            completion(true)
        }
    }

    private func launchProcess(binary: String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binary)
        proc.arguments = [
            "-p",
            "--output-format", "stream-json",
            "--input-format", "stream-json",
            "--verbose",
            "--dangerously-skip-permissions"
        ]

        proc.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        proc.environment = ShellEnvironment.processEnvironment()

        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        proc.standardInput = stdin
        proc.standardOutput = stdout
        proc.standardError = stderr

        stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self?.processOutput(str)
            }
        }

        // stderr 무시 (에러 로그)
        stderr.fileHandleForReading.readabilityHandler = { _ in }

        do {
            try proc.run()
            self.process = proc
            self.stdinPipe = stdin
        } catch {
            print("Failed to launch claude: \(error)")
        }
    }

    private func processOutput(_ str: String) {
        lineBuffer += str
        while let newlineRange = lineBuffer.range(of: "\n") {
            let line = String(lineBuffer[lineBuffer.startIndex..<newlineRange.lowerBound])
            lineBuffer = String(lineBuffer[newlineRange.upperBound...])
            parseLine(line)
        }
    }

    private func parseLine(_ line: String) {
        guard !line.isEmpty,
              let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "assistant":
            // 텍스트 블록 추출
            if let message = json["message"] as? [String: Any],
               let content = message["content"] as? [[String: Any]] {
                for block in content {
                    if block["type"] as? String == "text",
                       let text = block["text"] as? String {
                        responseCallback?(text)
                    }
                }
            }

        case "result":
            isBusy = false

        default:
            break
        }
    }

    // 메시지 보내기
    func send(_ message: String) {
        guard let pipe = stdinPipe, !isBusy else { return }
        isBusy = true

        let payload: [String: Any] = [
            "type": "user",
            "message": [
                "role": "user",
                "content": message
            ]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let jsonStr = String(data: data, encoding: .utf8) else { return }

        let line = jsonStr + "\n"
        pipe.fileHandleForWriting.write(line.data(using: .utf8)!)
    }

    // 말풍선용 — 한마디 생성
    func generateBubble(context: String, completion: @escaping ((text: String, emotion: Emotion)?) -> Void) {
        let prompt = "\(systemPrompt)\n\n현재 상황: \(context). 이 상황에 맞는 짧은 한마디를 해줘. 감정도 하나 골라줘 (idle/happy/surprised/sleepy). 형식: {감정}|{대사}. 반드시 이 형식만 출력해."

        responseCallback = { response in
            let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = cleaned.split(separator: "|", maxSplits: 1)
            if parts.count == 2 {
                let emotion = Emotion(rawValue: String(parts[0])) ?? .idle
                completion((text: String(parts[1]), emotion: emotion))
            } else {
                completion((text: cleaned, emotion: .idle))
            }
        }
        send(prompt)
    }

    // 채팅용
    func chat(message: String, completion: @escaping (String?) -> Void) {
        responseCallback = { response in
            completion(response)
        }
        send(message)
    }

    func stop() {
        stdinPipe?.fileHandleForWriting.closeFile()
        process?.terminate()
        process = nil
        stdinPipe = nil
    }

    var isRunning: Bool {
        process?.isRunning ?? false
    }
}
