import SwiftUI

@main
struct BuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Buddy", systemImage: "ghost.fill") {
            Button("Settings...") {
                // Settings will be implemented in Task 10
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
