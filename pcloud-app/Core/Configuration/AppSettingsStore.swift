import Foundation
import Combine

@MainActor
final class AppSettingsStore: ObservableObject {
    private enum Keys {
        static let apiBaseURLString = "api_base_url_string"
        static let themePreference = "theme_preference"
        static let appLanguage = "app_language"
    }

    @Published private(set) var apiBaseURLString: String
    @Published private(set) var themePreference: AppThemePreference
    @Published private(set) var appLanguage: AppLanguage

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let storedValue = userDefaults.string(forKey: Keys.apiBaseURLString)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let storedValue, Self.validatedURL(from: storedValue) != nil {
            apiBaseURLString = storedValue
        } else {
            apiBaseURLString = AppConfig.defaultAPIBaseURLString
        }

        themePreference = AppThemePreference(
            rawValue: userDefaults.string(forKey: Keys.themePreference) ?? ""
        ) ?? .light

        appLanguage = AppLanguage(
            rawValue: userDefaults.string(forKey: Keys.appLanguage) ?? ""
        ) ?? .english
    }

    var apiBaseURL: URL? {
        Self.validatedURL(from: apiBaseURLString)
    }

    var locale: Locale {
        Locale(identifier: appLanguage.localeIdentifier)
    }

    var strings: AppStrings {
        AppStrings(language: appLanguage)
    }

    func updateAPIBaseURL(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let validatedURL = Self.validatedURL(from: trimmed) else {
            throw AppSettingsError.invalidBaseURL
        }

        let normalized = validatedURL.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
        apiBaseURLString = normalized
        userDefaults.set(normalized, forKey: Keys.apiBaseURLString)
    }

    func updateThemePreference(_ preference: AppThemePreference) {
        themePreference = preference
        userDefaults.set(preference.rawValue, forKey: Keys.themePreference)
    }

    func updateAppLanguage(_ language: AppLanguage) {
        appLanguage = language
        userDefaults.set(language.rawValue, forKey: Keys.appLanguage)
    }

    static func validatedURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else {
            return nil
        }

        guard
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            url.host != nil
        else {
            return nil
        }

        return url
    }
}

enum AppSettingsError: LocalizedError {
    case invalidBaseURL

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Enter a full server URL such as http://127.0.0.1:8080 or http://192.168.1.5:8080."
        }
    }
}
