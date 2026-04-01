// Buddy/Views/SettingsView.swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("buddyName") private var buddyName: String = "Buddy"
    @AppStorage("bubbleFrequency") private var bubbleFrequency: Double = 10
    @AppStorage("wanderEnabled") private var wanderEnabled: Bool = true
    @State private var apiKey: String = ""
    @State private var launchAtLogin: Bool = false
    @State private var showSavedAlert: Bool = false

    var body: some View {
        Form {
            Section("캐릭터") {
                TextField("이름", text: $buddyName)
                Toggle("화면 이동", isOn: $wanderEnabled)
            }

            Section("AI") {
                SecureField("Claude API Key", text: $apiKey)
                Button("저장") {
                    KeychainHelper.save(key: "claude-api-key", value: apiKey)
                    showSavedAlert = true
                }
                .alert("API 키가 저장되었어요!", isPresented: $showSavedAlert) {
                    Button("OK") {}
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
        .frame(width: 350, height: 400)
        .onAppear {
            apiKey = KeychainHelper.load(key: "claude-api-key") ?? ""
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
