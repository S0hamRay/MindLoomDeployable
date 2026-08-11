import ApplicationServices
import AppKit
import Foundation

enum AccessibilityPermission {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Path macOS TCC is evaluating — useful when multiple agent builds are listed.
    static var currentExecutablePath: String {
        Bundle.main.executablePath
            ?? CommandLine.arguments.first
            ?? "(unknown)"
    }

    static var isRunningFromAppBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
            || Bundle.main.bundlePath.hasSuffix(".app")
    }

    @discardableResult
    static func promptIfNeeded() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        ]
        for raw in urls {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
