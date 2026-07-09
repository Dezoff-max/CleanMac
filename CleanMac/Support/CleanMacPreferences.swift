import CleanMacCore
import Foundation

enum CleanMacPreferenceKeys {
    static let selectedAreaIDs = "CleanMac.selectedAreaIDs"
    static let lastScanItemCount = "CleanMac.lastScanItemCount"
    static let lastScanBytes = "CleanMac.lastScanBytes"
    static let lastScanTimestamp = "CleanMac.lastScanTimestamp"
    static let lastScanSource = "CleanMac.lastScanSource"
    static let autoScanEnabled = "CleanMac.autoScanEnabled"
    static let autoScanFrequency = "CleanMac.autoScanFrequency"
    static let autoScanHour = "CleanMac.autoScanHour"
    static let autoScanMinute = "CleanMac.autoScanMinute"
    static let autoScanLastRunKey = "CleanMac.autoScanLastRunKey"
    static let scanInProgress = "CleanMac.scanInProgress"
}

enum CleanMacScanSource: String {
    case manual
    case scheduled
}

enum CleanMacAutoScanFrequency: String, CaseIterable, Identifiable {
    case daily
    case hourly
    case everyTwoHours

    static let defaultFrequency: CleanMacAutoScanFrequency = .daily

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            L.t("settings.autoScanFrequency.daily")
        case .hourly:
            L.t("settings.autoScanFrequency.hourly")
        case .everyTwoHours:
            L.t("settings.autoScanFrequency.everyTwoHours")
        }
    }

    var hourInterval: Int? {
        switch self {
        case .daily:
            nil
        case .hourly:
            1
        case .everyTwoHours:
            2
        }
    }
}

enum CleanMacScanPreferences {
    static var defaultSelectedAreaIDs: Set<String> {
        Set(CleanMacCatalog.cleanupAreas.filter(\.isDefaultSelected).map(\.id))
    }

    static var defaultSelectedAreaIDsRaw: String {
        encodeAreaIDs(defaultSelectedAreaIDs)
    }

    static func selectedAreaIDs(defaults: UserDefaults = .standard) -> Set<String> {
        let rawValue = defaults.string(forKey: CleanMacPreferenceKeys.selectedAreaIDs)
        guard let rawValue else {
            return defaultSelectedAreaIDs
        }
        guard !rawValue.isEmpty else {
            return []
        }

        let validIDs = Set(CleanMacCatalog.cleanupAreas.map(\.id))
        let decodedIDs = Set(rawValue.split(separator: ",").map(String.init))
            .intersection(validIDs)

        return decodedIDs.isEmpty ? defaultSelectedAreaIDs : decodedIDs
    }

    static func selectedCategories(defaults: UserDefaults = .standard) -> [CleanupCategory] {
        let selectedIDs = selectedAreaIDs(defaults: defaults)
        return CleanMacCatalog.cleanupAreas
            .filter { selectedIDs.contains($0.id) }
            .map(\.category)
    }

    static func storeSelectedAreaIDs(_ areaIDs: Set<String>, defaults: UserDefaults = .standard) {
        defaults.set(encodeAreaIDs(areaIDs), forKey: CleanMacPreferenceKeys.selectedAreaIDs)
    }

    static func storeLastScan(_ report: CleanupScanReport, source: CleanMacScanSource, defaults: UserDefaults = .standard) {
        defaults.set(report.items.count, forKey: CleanMacPreferenceKeys.lastScanItemCount)
        defaults.set(Double(report.totalSizeBytes), forKey: CleanMacPreferenceKeys.lastScanBytes)
        defaults.set(report.scannedAt.timeIntervalSince1970, forKey: CleanMacPreferenceKeys.lastScanTimestamp)
        defaults.set(source.rawValue, forKey: CleanMacPreferenceKeys.lastScanSource)
    }

    static func encodeAreaIDs(_ areaIDs: Set<String>) -> String {
        areaIDs.sorted().joined(separator: ",")
    }
}

enum CleanMacScanSchedule {
    static let defaultHour = 10
    static let defaultMinute = 0

    static func frequency(defaults: UserDefaults = .standard) -> CleanMacAutoScanFrequency {
        let rawValue = defaults.string(forKey: CleanMacPreferenceKeys.autoScanFrequency)
        return rawValue.flatMap(CleanMacAutoScanFrequency.init(rawValue:)) ?? CleanMacAutoScanFrequency.defaultFrequency
    }

    static func scheduledDate(on day: Date, defaults: UserDefaults = .standard, calendar: Calendar = .current) -> Date {
        let hour = defaults.object(forKey: CleanMacPreferenceKeys.autoScanHour) as? Int ?? defaultHour
        let minute = defaults.object(forKey: CleanMacPreferenceKeys.autoScanMinute) as? Int ?? defaultMinute
        return calendar.date(
            bySettingHour: min(max(hour, 0), 23),
            minute: min(max(minute, 0), 59),
            second: 0,
            of: day
        ) ?? day
    }

    static func dueRun(defaults: UserDefaults = .standard, now: Date = Date(), calendar: Calendar = .current) -> (date: Date, key: String)? {
        guard let date = dueRunDate(defaults: defaults, now: now, calendar: calendar) else {
            return nil
        }

        let key = runKey(for: date, calendar: calendar)
        guard defaults.string(forKey: CleanMacPreferenceKeys.autoScanLastRunKey) != key else {
            return nil
        }

        return (date, key)
    }

    static func nextRunDate(defaults: UserDefaults = .standard, now: Date = Date(), calendar: Calendar = .current) -> Date {
        if let dueRun = dueRun(defaults: defaults, now: now, calendar: calendar) {
            return dueRun.date
        }

        let frequency = frequency(defaults: defaults)
        let todayRun = scheduledDate(on: now, defaults: defaults, calendar: calendar)

        if frequency == .daily {
            if todayRun > now {
                return todayRun
            }

            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(24 * 60 * 60)
            return scheduledDate(on: tomorrow, defaults: defaults, calendar: calendar)
        }

        guard let hourInterval = frequency.hourInterval else {
            return todayRun
        }

        let dueDate = dueRunDate(defaults: defaults, now: now, calendar: calendar) ?? todayRun
        return calendar.date(byAdding: .hour, value: hourInterval, to: dueDate)
            ?? dueDate.addingTimeInterval(TimeInterval(hourInterval * 60 * 60))
    }

    static func runKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return String(
            format: "%04d-%02d-%02d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0,
            components.minute ?? 0
        )
    }

    private static func dueRunDate(defaults: UserDefaults, now: Date, calendar: Calendar) -> Date? {
        let frequency = frequency(defaults: defaults)
        let todayRun = scheduledDate(on: now, defaults: defaults, calendar: calendar)

        guard let hourInterval = frequency.hourInterval else {
            return now >= todayRun ? todayRun : nil
        }

        var anchor = todayRun
        if anchor > now {
            anchor = calendar.date(byAdding: .day, value: -1, to: anchor)
                ?? anchor.addingTimeInterval(-24 * 60 * 60)
        }

        let interval = TimeInterval(hourInterval * 60 * 60)
        let elapsed = max(0, now.timeIntervalSince(anchor))
        let completedIntervals = floor(elapsed / interval)
        return anchor.addingTimeInterval(completedIntervals * interval)
    }
}
