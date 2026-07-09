import CleanMacCore
import Foundation
import UserNotifications

enum CleanMacNotificationService {
    private static let center = UNUserNotificationCenter.current()

    static func configure() {
        center.delegate = CleanMacNotificationDelegate.shared
    }

    static func notificationsEnabled(defaults: UserDefaults = .standard) -> Bool {
        guard defaults.object(forKey: CleanMacPreferenceKeys.autoScanNotificationsEnabled) != nil else {
            return true
        }

        return defaults.bool(forKey: CleanMacPreferenceKeys.autoScanNotificationsEnabled)
    }

    static func requestAuthorizationIfNeeded(defaults: UserDefaults = .standard) async -> Bool {
        guard notificationsEnabled(defaults: defaults) else {
            return false
        }

        let settings = await notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            return await requestAuthorization()
        default:
            return false
        }
    }

    static func notifyScheduledScanCompleted(_ report: CleanupScanReport, defaults: UserDefaults = .standard) async {
        guard notificationsEnabled(defaults: defaults) else {
            return
        }

        let settings = await notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = L.t("notification.autoScan.title")
        content.body = L.f(
            "notification.autoScan.body",
            report.items.count,
            CleanMacFormatters.bytes(report.totalSizeBytes)
        )
        content.sound = .default

        let identifier = "CleanMac.autoScanCompleted.\(Int(report.scannedAt.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        await add(request)
    }

    private static func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    private static func add(_ request: UNNotificationRequest) async {
        await withCheckedContinuation { continuation in
            center.add(request) { _ in
                continuation.resume()
            }
        }
    }
}

private final class CleanMacNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = CleanMacNotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
