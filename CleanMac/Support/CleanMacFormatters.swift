import Foundation

enum CleanMacFormatters {
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
        return ByteCountFormatStyle(
            style: .file,
            allowedUnits: [.kb, .mb, .gb, .tb],
            spellsOutZero: false,
            includesActualByteCount: false,
            locale: CleanMacLanguage.current.locale
        ).format(value)
    }

    static func relativeDate(_ date: Date?) -> String {
        guard let date else {
            return L.t("date.unknown")
        }
        relativeFormatter.locale = CleanMacLanguage.current.locale
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    static func time(_ date: Date) -> String {
        timeFormatter.locale = CleanMacLanguage.current.locale
        return timeFormatter.string(from: date)
    }
}
