// Buddy/Views/SettingsView.swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var characterStore: CharacterStore
    @AppStorage("bubbleFrequency") private var bubbleFrequency: Double = 10
    @State private var launchAtLogin: Bool = false
    @State private var claudeFound: Bool = false

    var onCharacterAdded: ((BuddyCharacter) -> Void)?
    var onCharacterRemoved: ((UUID) -> Void)?
    var onCharacterUpdated: ((BuddyCharacter) -> Void)?
    var onSettingsOpen: (() -> Void)?
    var onSettingsClose: (() -> Void)?

    var body: some View {
        Form {
            Section("캐릭터") {
                CharacterListView(
                    store: characterStore,
                    onCharacterAdded: onCharacterAdded,
                    onCharacterRemoved: onCharacterRemoved,
                    onCharacterUpdated: onCharacterUpdated
                )
            }

            Section("AI") {
                HStack {
                    Text("Claude Code CLI")
                    Spacer()
                    if claudeFound {
                        Text("연결됨 ✓")
                            .foregroundColor(.green)
                    } else {
                        Text("미설치")
                            .foregroundColor(.secondary)
                    }
                }
                if !claudeFound {
                    Text("Claude Code CLI를 설치하면 AI 기능을 사용할 수 있어요.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("말풍선") {
                HStack {
                    Text("빈도")
                    Slider(value: $bubbleFrequency, in: 3...30, step: 1)
                    Text("\(Int(bubbleFrequency))분")
                        .frame(width: 40)
                }
            }

            Section("시스템") {
                Toggle("로그인 시 자동 시작", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 500)
        .onAppear {
            AIService.findClaude { path in
                claudeFound = path != nil
            }
            onSettingsOpen?()
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            onSettingsClose?()
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Launch at login error: \(error)")
        }
    }
}
