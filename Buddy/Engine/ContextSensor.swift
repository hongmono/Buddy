// Buddy/Engine/ContextSensor.swift
import AppKit
import CoreGraphics

class ContextSensor {
    var onContextEvent: ((String) -> Void)?

    private var workspaceObserver: NSObjectProtocol?
    private var idleTimer: Timer?
    private var randomBubbleTimer: Timer?
    private var lastBubbleTime = Date()
    private var lastActiveApp: String = ""

    func start() {
        observeAppSwitches()
        startIdleCheck()
        startRandomBubbleTimer()
        let hour = Calendar.current.component(.hour, from: Date())
        onContextEvent?(Self.timeOfDayContext(hour: hour))
    }

    func stop() {
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        idleTimer?.invalidate()
        randomBubbleTimer?.invalidate()
    }

    private func observeAppSwitches() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let name = app.localizedName else { return }
            guard let self = self, name != self.lastActiveApp else { return }
            self.lastActiveApp = name
            self.onContextEvent?("사용자가 \(name) 앱으로 전환했음")
        }
    }

    private func startIdleCheck() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            let idleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
            if idleTime > 30 * 60 {
                self?.onContextEvent?("사용자가 30분 이상 자리를 비웠음")
            }
        }
    }

    private func startRandomBubbleTimer() {
        scheduleNextRandom()
    }

    private func scheduleNextRandom() {
        let interval = TimeInterval.random(in: 5 * 60 ... 15 * 60)
        randomBubbleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.onContextEvent?("랜덤 혼잣말 시간")
            self?.scheduleNextRandom()
        }
    }

    // Testable static methods

    static func timeOfDayContext(hour: Int) -> String {
        switch hour {
        case 5..<9: return "아침 시간대 (\(hour)시)"
        case 9..<12: return "오전 시간대 (\(hour)시)"
        case 12..<14: return "점심 시간대 (\(hour)시)"
        case 14..<18: return "오후 시간대 (\(hour)시)"
        case 18..<22: return "저녁 시간대 (\(hour)시)"
        default: return "늦은 밤 시간대 (\(hour)시)"
        }
    }

    static func shouldTriggerRandom(lastBubbleTime: Date, minInterval: TimeInterval, maxInterval: TimeInterval) -> Bool {
        let elapsed = Date().timeIntervalSince(lastBubbleTime)
        guard elapsed >= minInterval else { return false }
        let probability = (elapsed - minInterval) / (maxInterval - minInterval)
        return Double.random(in: 0...1) < probability
    }
}
