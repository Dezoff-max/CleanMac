import Foundation

public enum LowDiskSpaceWarningPolicy {
    public static let thresholdFraction = 0.10
    public static let notificationCooldown: TimeInterval = 24 * 60 * 60

    public static func freeFraction(totalBytes: Int64, freeBytes: Int64) -> Double? {
        guard totalBytes > 0 else {
            return nil
        }

        return min(max(Double(freeBytes) / Double(totalBytes), 0), 1)
    }

    public static func isLowSpace(totalBytes: Int64, freeBytes: Int64) -> Bool {
        guard let fraction = freeFraction(totalBytes: totalBytes, freeBytes: freeBytes) else {
            return false
        }
        return fraction < thresholdFraction
    }

    public static func shouldNotify(
        totalBytes: Int64,
        freeBytes: Int64,
        lastNotificationDate: Date?,
        now: Date = Date()
    ) -> Bool {
        guard isLowSpace(totalBytes: totalBytes, freeBytes: freeBytes) else {
            return false
        }
        guard let lastNotificationDate else {
            return true
        }
        return now.timeIntervalSince(lastNotificationDate) >= notificationCooldown
    }
}
