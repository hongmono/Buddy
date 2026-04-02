// Buddy/BuddyApp.swift
import SwiftUI

@main
struct BuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Buddy", systemImage: "face.dashed") {
            SettingsLink {
                Text("Settings...")
            }
            .keyboardShortcut(",")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView(
                characterStore: appDelegate.characterStore,
                onCharacterAdded: { character in
                    appDelegate.spawnCharacter(character)
                },
                onCharacterRemoved: { id in
                    appDelegate.despawnCharacter(id: id)
                },
                onCharacterUpdated: { character in
                    appDelegate.despawnCharacter(id: character.id)
                    appDelegate.spawnCharacter(character)
                },
                onSettingsOpen: {
                    appDelegate.setCharacterWindowsFloating(false)
                },
                onSettingsClose: {
                    appDelegate.setCharacterWindowsFloating(true)
                }
            )
        }
    }
}
