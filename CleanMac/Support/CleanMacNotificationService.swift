import CleanMacCore
import Foundation
import UserNotifications

enum CleanMacNotificationDeliveryResult {
    case sent
    case disabled
    case denied
    case failed
}

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

    static func notifyLowDiskSpaceIfNeeded(
        _ disk: StatusDiskSnapshot,
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) async {
        let lastTimestamp = defaults.double(forKey: CleanMacPreferenceKeys.lowDiskSpaceLastNotificationTimestamp)
        let lastNotificationDate = lastTimestamp > 0 ? Date(timeIntervalSince1970: lastTimestamp) : nil
        guard LowDiskSpaceWarningPolicy.shouldNotify(
            totalBytes: disk.totalBytes,
            freeBytes: disk.freeBytes,
            lastNotificationDate: lastNotificationDate,
            now: now
        ) else {
            return
        }

        let settings = await notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = L.t("notification.lowDisk.title")
        content.body = L.f(
            "notification.lowDisk.body",
            CleanMacFormatters.bytes(disk.freeBytes),
            Int(((disk.freeFraction ?? 0) * 100).rounded(.down))
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "CleanMac.lowDiskSpace",
            content: content,
            trigger: nil
        )
        if await add(request) {
            defaults.set(now.timeIntervalSince1970, forKey: CleanMacPreferenceKeys.lowDiskSpaceLastNotificationTimestamp)
        }
    }

    static func sendTestNotification(defaults: UserDefaults = .standard) async -> CleanMacNotificationDeliveryResult {
        guard notificationsEnabled(defaults: defaults) else {
            return .disabled
        }

        let settings = await notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            break
        case .notDetermined:
            guard await requestAuthorization() else {
                return .denied
            }
        default:
            return .denied
        }

        let content = UNMutableNotificationContent()
        content.title = L.t("notification.test.title")
        content.body = L.t("notification.test.body")
        content.sound = .default

        let identifier = "CleanMac.testNotification.\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        return await add(request) ? .sent : .failed
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

    @discardableResult
    private static func add(_ request: UNNotificationRequest) async -> Bool {
        await withCheckedContinuation { continuation in
            center.add(request) { error in
                continuation.resume(returning: error == nil)
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
