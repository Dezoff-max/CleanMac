import AppKit
import SwiftUI

@main
struct CleanMacApp: App {
    @NSApplicationDelegateAdaptor(CleanMacAppDelegate.self) private var appDelegate
    @AppStorage(CleanMacAppearance.storageKey) private var appearanceMode = CleanMacAppearance.defaultCode
    @AppStorage(CleanMacLanguage.storageKey) private var languageCode = CleanMacLanguage.defaultCode

    private var language: CleanMacLanguage {
        CleanMacLanguage(rawValue: languageCode) ?? .current
    }

    private var appearance: CleanMacAppearance {
        CleanMacAppearance.value(for: appearanceMode)
    }

    var body: some Scene {
        WindowGroup("CleanMac", id: "main") {
            MainWindowView()
                .environment(\.locale, language.locale)
                .preferredColorScheme(appearance.colorScheme)
        }
        .defaultSize(width: 980, height: 720)
        .windowResizability(.contentMinSize)

        MenuBarExtra("CleanMac", image: "MenuBarIcon") {
            StatusMenuView()
                .environment(\.locale, language.locale)
                .preferredColorScheme(appearance.colorScheme)
        }
        .menuBarExtraStyle(.window)
    }
}

final class CleanMacAppDelegate: NSObject, NSApplicationDelegate {
    private let autoScanScheduler = CleanMacAutoScanScheduler()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        autoScanScheduler.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        autoScanScheduler.stop()
    }
}
