import Foundation
import SwiftUI

enum CleanMacLanguage: String, CaseIterable, Identifiable {
    static let storageKey = "CleanMac.languageCode"

    case ru
    case en

    var id: String { rawValue }

    static var defaultCode: String {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("ru") == true ? ru.rawValue : en.rawValue
    }

    static var current: CleanMacLanguage {
        let code = UserDefaults.standard.string(forKey: storageKey) ?? defaultCode
        return CleanMacLanguage(rawValue: code) ?? CleanMacLanguage(rawValue: defaultCode) ?? .en
    }

    var title: String {
        rawValue.uppercased()
    }

    var locale: Locale {
        switch self {
        case .ru: Locale(identifier: "ru_RU")
        case .en: Locale(identifier: "en_US")
        }
    }

    var bundle: Bundle {
        guard
            let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }
        return bundle
    }
}

enum CleanMacAppearance: String, CaseIterable, Identifiable {
    static let storageKey = "CleanMac.appearanceMode"
    static let defaultCode = CleanMacAppearance.light.rawValue

    case light
    case dark

    var id: String { rawValue }

    static func value(for code: String) -> CleanMacAppearance {
        CleanMacAppearance(rawValue: code) ?? .light
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: .light
        case .dark: .dark
        }
    }
}

enum L {
    static func t(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: CleanMacLanguage.current.bundle, value: key, comment: "")
    }

    static func f(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: t(key), locale: CleanMacLanguage.current.locale, arguments: arguments)
    }
}
