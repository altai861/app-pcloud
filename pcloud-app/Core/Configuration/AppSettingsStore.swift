import Foundation
import Combine

enum ServerConnectionMode: String, CaseIterable, Identifiable {
    case manual
    case lan
    case relay

    var id: String { rawValue }
}

struct SavedPCloudServer: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let deviceID: String
    let lanBaseURLString: String?
    let relayBaseURLString: String
    let relayURLString: String
}

@MainActor
final class AppSettingsStore: ObservableObject {
    private enum Keys {
        static let apiBaseURLString = "api_base_url_string"
        static let serverConnectionMode = "server_connection_mode"
        static let selectedServerName = "selected_server_name"
        static let selectedDeviceID = "selected_device_id"
        static let selectedRelayBaseURLString = "selected_relay_base_url_string"
        static let selectedRelayURLString = "selected_relay_url_string"
        static let savedServers = "saved_pcloud_servers"
        static let themePreference = "theme_preference"
        static let appLanguage = "app_language"
    }

    @Published private(set) var apiBaseURLString: String
    @Published private(set) var serverConnectionMode: ServerConnectionMode
    @Published private(set) var selectedServerName: String?
    @Published private(set) var selectedDeviceID: String?
    @Published private(set) var selectedRelayBaseURLString: String?
    @Published private(set) var selectedRelayURLString: String?
    @Published private(set) var savedServers: [SavedPCloudServer]
    @Published private(set) var themePreference: AppThemePreference
    @Published private(set) var appLanguage: AppLanguage

    private let userDefaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let storedValue = userDefaults.string(forKey: Keys.apiBaseURLString)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let storedValue, Self.validatedURL(from: storedValue) != nil {
            apiBaseURLString = storedValue
        } else {
            apiBaseURLString = AppConfig.defaultAPIBaseURLString
        }

        serverConnectionMode = ServerConnectionMode(
            rawValue: userDefaults.string(forKey: Keys.serverConnectionMode) ?? ""
        ) ?? .manual

        selectedServerName = userDefaults.string(forKey: Keys.selectedServerName)
        selectedDeviceID = userDefaults.string(forKey: Keys.selectedDeviceID)
        selectedRelayBaseURLString = userDefaults.string(forKey: Keys.selectedRelayBaseURLString)
        selectedRelayURLString = userDefaults.string(forKey: Keys.selectedRelayURLString)
        savedServers = Self.loadSavedServers(from: userDefaults, decoder: decoder)

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
        applyServerSelection(
            baseURLString: normalized,
            mode: .manual,
            serverName: nil,
            deviceID: nil,
            relayBaseURLString: nil,
            relayURLString: nil
        )
    }

    func updateDiscoveredServer(_ server: DiscoveredPCloudServer, mode: ServerConnectionMode) throws {
        let selectedBaseURLString: String

        switch mode {
        case .manual:
            selectedBaseURLString = server.apiBaseURLString
        case .lan:
            selectedBaseURLString = server.apiBaseURLString
        case .relay:
            guard let relayURLString = server.relayURLString else {
                throw AppSettingsError.relayUnavailable
            }
            selectedBaseURLString = relayURLString
        }

        guard let validatedURL = Self.validatedURL(from: selectedBaseURLString) else {
            throw AppSettingsError.invalidBaseURL
        }

        applyServerSelection(
            baseURLString: validatedURL.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines),
            mode: mode,
            serverName: server.name,
            deviceID: server.deviceID,
            relayBaseURLString: server.relayBaseURLString,
            relayURLString: server.relayURLString
        )

        if
            let deviceID = server.deviceID,
            let relayBaseURLString = server.relayBaseURLString,
            let relayURLString = server.relayURLString
        {
            rememberServer(
                SavedPCloudServer(
                    id: deviceID,
                    name: server.name,
                    deviceID: deviceID,
                    lanBaseURLString: server.apiBaseURLString,
                    relayBaseURLString: relayBaseURLString,
                    relayURLString: relayURLString
                )
            )
        }
    }

    func updateRelayDeviceID(_ rawDeviceID: String) throws {
        let deviceID = rawDeviceID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !deviceID.isEmpty else {
            throw AppSettingsError.invalidDeviceID
        }

        let relayTarget = try Self.relayTarget(for: deviceID)

        applyServerSelection(
            baseURLString: relayTarget.relayURLString,
            mode: .relay,
            serverName: "Device \(deviceID)",
            deviceID: deviceID,
            relayBaseURLString: relayTarget.relayBaseURLString,
            relayURLString: relayTarget.relayURLString
        )

        rememberServer(
            SavedPCloudServer(
                id: deviceID,
                name: "Device \(deviceID)",
                deviceID: deviceID,
                lanBaseURLString: nil,
                relayBaseURLString: relayTarget.relayBaseURLString,
                relayURLString: relayTarget.relayURLString
            )
        )
    }

    func updateSavedServer(_ server: SavedPCloudServer, mode: ServerConnectionMode) throws {
        let selectedBaseURLString: String

        switch mode {
        case .manual:
            selectedBaseURLString = server.relayURLString
        case .lan:
            guard let lanBaseURLString = server.lanBaseURLString else {
                throw AppSettingsError.invalidBaseURL
            }
            selectedBaseURLString = lanBaseURLString
        case .relay:
            selectedBaseURLString = server.relayURLString
        }

        guard let validatedURL = Self.validatedURL(from: selectedBaseURLString) else {
            throw AppSettingsError.invalidBaseURL
        }

        applyServerSelection(
            baseURLString: validatedURL.absoluteString.trimmingSuffix("/"),
            mode: mode == .lan ? .lan : .relay,
            serverName: server.name,
            deviceID: server.deviceID,
            relayBaseURLString: server.relayBaseURLString,
            relayURLString: server.relayURLString
        )

        rememberServer(server)
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

    private static func relayTarget(for deviceID: String) throws -> (
        relayBaseURLString: String,
        relayURLString: String
    ) {
        guard let relayBaseURL = Self.validatedURL(from: AppConfig.defaultRelayBaseURLString) else {
            throw AppSettingsError.invalidBaseURL
        }

        let relayBaseURLString = relayBaseURL.absoluteString.trimmingSuffix("/")
        let encodedDeviceID = deviceID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? deviceID
        let relayURLString = "\(relayBaseURLString)/d/\(encodedDeviceID)"

        guard let validatedURL = Self.validatedURL(from: relayURLString) else {
            throw AppSettingsError.invalidBaseURL
        }

        return (
            relayBaseURLString,
            validatedURL.absoluteString.trimmingSuffix("/")
        )
    }

    private static func loadSavedServers(
        from userDefaults: UserDefaults,
        decoder: JSONDecoder
    ) -> [SavedPCloudServer] {
        guard
            let data = userDefaults.data(forKey: Keys.savedServers),
            let decoded = try? decoder.decode([SavedPCloudServer].self, from: data)
        else {
            return []
        }

        return decoded
    }

    private func applyServerSelection(
        baseURLString: String,
        mode: ServerConnectionMode,
        serverName: String?,
        deviceID: String?,
        relayBaseURLString: String?,
        relayURLString: String?
    ) {
        apiBaseURLString = baseURLString
        serverConnectionMode = mode
        selectedServerName = serverName
        selectedDeviceID = deviceID
        selectedRelayBaseURLString = relayBaseURLString
        selectedRelayURLString = relayURLString

        userDefaults.set(baseURLString, forKey: Keys.apiBaseURLString)
        userDefaults.set(mode.rawValue, forKey: Keys.serverConnectionMode)
        setOptional(serverName, forKey: Keys.selectedServerName)
        setOptional(deviceID, forKey: Keys.selectedDeviceID)
        setOptional(relayBaseURLString, forKey: Keys.selectedRelayBaseURLString)
        setOptional(relayURLString, forKey: Keys.selectedRelayURLString)
    }

    private func setOptional(_ value: String?, forKey key: String) {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }

    private func rememberServer(_ server: SavedPCloudServer) {
        var updatedServers = savedServers.filter { $0.id != server.id }
        updatedServers.insert(server, at: 0)
        savedServers = Array(updatedServers.prefix(8))

        if let data = try? encoder.encode(savedServers) {
            userDefaults.set(data, forKey: Keys.savedServers)
        }
    }
}

enum AppSettingsError: LocalizedError {
    case invalidBaseURL
    case invalidDeviceID
    case relayUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Enter a valid server URL."
        case .invalidDeviceID:
            return "Enter a device ID."
        case .relayUnavailable:
            return "Device ID unavailable."
        }
    }
}

private extension String {
    func trimmingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else {
            return self
        }

        return String(dropLast(suffix.count))
    }
}
