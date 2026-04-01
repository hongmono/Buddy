// Buddy/Buddy/AppDelegate.swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: FloatingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        windowController = FloatingWindowController()
        let placeholder = Circle()
            .fill(LinearGradient(
                colors: [Color(hex: "a8edea"), Color(hex: "7dd3cc")],
                startPoint: .top,
                endPoint: .bottom
            ))
            .frame(width: 60, height: 60)
        windowController?.setContent(placeholder)
        windowController?.show()
    }
}

// Color hex extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
