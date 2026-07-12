import AppKit
import SwiftUI

@main
struct CleanMacApp: App {
    @NSApplicationDelegateAdaptor(CleanMacAppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    @AppStorage(CleanMacAppearance.storageKey) private var appearanceMode = CleanMacAppearance.defaultCode
    @AppStorage(CleanMacLanguage.storageKey) private var languageCode = CleanMacLanguage.defaultCode
    @AppStorage(CleanMacPreferenceKeys.onboardingCompleted) private var onboardingCompleted = false

    private var language: CleanMacLanguage {
        CleanMacLanguage(rawValue: languageCode) ?? .current
    }

    private var appearance: CleanMacAppearance {
        CleanMacAppearance.value(for: appearanceMode)
    }

    var body: some Scene {
        WindowGroup("CleanMac", id: "main") {
            Group {
                if onboardingCompleted {
                    MainWindowView()
                        .preferredColorScheme(appearance.colorScheme)
                } else {
                    OnboardingView {
                        onboardingCompleted = true
                    }
                    .preferredColorScheme(nil)
                }
            }
            .environment(\.locale, language.locale)
        }
        .defaultSize(width: 980, height: 720)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(L.t("about.menu")) {
                    openWindow(id: "about")
                }
            }
        }

        Window(L.t("about.windowTitle"), id: "about") {
            AboutView()
                .environment(\.locale, language.locale)
                .preferredColorScheme(appearance.colorScheme)
        }
        .defaultSize(width: 520, height: 440)
        .defaultPosition(.center)
        .windowResizability(.contentSize)

        MenuBarExtra("CleanMac", image: "MenuBarIcon") {
            StatusMenuView()
                .environment(\.locale, language.locale)
                .environment(\.colorScheme, appearance.colorScheme)
        }
        .menuBarExtraStyle(.window)
    }
}

final class CleanMacAppDelegate: NSObject, NSApplicationDelegate {
    private let autoScanScheduler = CleanMacAutoScanScheduler()
    private let lowDiskSpaceMonitor = CleanMacLowDiskSpaceMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        MainWindowController.prepareForInitialPresentation(isBackgroundLaunch: !NSApp.isActive)
        NSApp.setActivationPolicy(.regular)
        configureDockIcon()
        CleanMacNotificationService.configure()
        requestNotificationAuthorizationIfUseful()
        autoScanScheduler.start()
        lowDiskSpaceMonitor.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        MainWindowController.handleReopen()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MainWindowController.handleReopen()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        autoScanScheduler.stop()
        lowDiskSpaceMonitor.stop()
    }

    private func configureDockIcon() {
        guard let icon = NSImage(named: "BrandIcon") else { return }
        icon.isTemplate = false
        NSApp.applicationIconImage = icon
    }

    private func requestNotificationAuthorizationIfUseful() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: CleanMacPreferenceKeys.autoScanEnabled),
              CleanMacNotificationService.notificationsEnabled(defaults: defaults)
        else {
            return
        }

        Task {
            _ = await CleanMacNotificationService.requestAuthorizationIfNeeded(defaults: defaults)
        }
    }
}
