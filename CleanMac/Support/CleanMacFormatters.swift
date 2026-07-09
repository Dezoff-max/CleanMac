import Foundation

enum CleanMacFormatters {
    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesActualByteCount = false
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static func bytes(_ value: Int64) -> String {
        guard value > 0 else {
            return L.t("size.zero")
        }
        return byteFormatter.string(fromByteCount: value)
    }

    static func relativeDate(_ date: Date?) -> String {
        guard let date else {
            return L.t("date.unknown")
        }
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}
