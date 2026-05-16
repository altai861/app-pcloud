@preconcurrency import Foundation
import Combine

struct DiscoveredPCloudServer: Identifiable, Equatable {
    let id: String
    let name: String
    let hostName: String
    let port: Int
    let apiBaseURLString: String
    let deviceID: String?
    let relayBaseURLString: String?
    let relayURLString: String?

    var displayHost: String {
        "\(hostName):\(port)"
    }

    var canUseRelay: Bool {
        relayURLString != nil
    }
}

@MainActor
final class LocalServerDiscovery: NSObject, ObservableObject {
    private static let serviceType = "_pcloud._tcp."
    private static let searchDomain = "local."

    @Published private(set) var servers: [DiscoveredPCloudServer] = []
    @Published private(set) var isSearching = false
    @Published private(set) var errorMessage: String?

    private let browser = NetServiceBrowser()
    private var services: [String: NetService] = [:]
    private var discoveredByID: [String: DiscoveredPCloudServer] = [:]

    override init() {
        super.init()
        browser.delegate = self
        browser.includesPeerToPeer = true
    }

    func start() {
        guard !isSearching else {
            return
        }

        errorMessage = nil
        isSearching = true
        browser.searchForServices(ofType: Self.serviceType, inDomain: Self.searchDomain)
    }

    func refresh() {
        stop()
        servers = []
        discoveredByID = [:]
        start()
    }

    func stop() {
        guard isSearching else {
            return
        }

        browser.stop()
        isSearching = false

        for service in services.values {
            service.stop()
            service.delegate = nil
        }
        services = [:]
    }

    private func addService(_ service: NetService) {
        let key = serviceKey(for: service)
        services[key] = service
        service.delegate = self
        service.includesPeerToPeer = true
        service.resolve(withTimeout: 6)
    }

    private func removeService(_ service: NetService) {
        let key = serviceKey(for: service)
        services[key]?.stop()
        services[key]?.delegate = nil
        services[key] = nil
        discoveredByID[key] = nil
        publishServers()
    }

    private func resolve(_ service: NetService) {
        guard service.port > 0 else {
            return
        }

        let properties = Self.txtProperties(from: service.txtRecordData())
        let scheme = Self.validScheme(from: properties["protocol"]) ?? "http"
        let hostName = Self.normalizedHostName(service.hostName)

        guard
            let hostName,
            let apiBaseURLString = Self.baseURLString(scheme: scheme, host: hostName, port: service.port)
        else {
            return
        }

        let deviceID = properties["device_id"]?.nonEmptyTrimmed
        let relayBaseURLString = AppConfig.defaultRelayBaseURLString.nonEmptyTrimmed
        let relayPath = properties["relay_path"]?.nonEmptyTrimmed
            ?? deviceID.map { "/d/\($0)" }
        let relayURLString = Self.relayURLString(base: relayBaseURLString, path: relayPath)
        let key = serviceKey(for: service)
        let server = DiscoveredPCloudServer(
            id: key,
            name: service.name,
            hostName: hostName,
            port: service.port,
            apiBaseURLString: apiBaseURLString,
            deviceID: deviceID,
            relayBaseURLString: relayBaseURLString,
            relayURLString: relayURLString
        )

        discoveredByID[key] = server
        publishServers()
    }

    private func publishServers() {
        servers = discoveredByID.values.sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    private func serviceKey(for service: NetService) -> String {
        "\(service.name)|\(service.type)|\(service.domain)"
    }

    private static func txtProperties(from data: Data?) -> [String: String] {
        guard let data else {
            return [:]
        }

        return NetService.dictionary(fromTXTRecord: data).reduce(into: [:]) { result, item in
            result[item.key] = String(data: item.value, encoding: .utf8)
        }
    }

    private static func normalizedHostName(_ hostName: String?) -> String? {
        hostName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingSuffix(".")
            .nonEmptyTrimmed
    }

    private static func validScheme(from rawValue: String?) -> String? {
        let scheme = rawValue?.nonEmptyTrimmed?.lowercased()
        return scheme == "http" || scheme == "https" ? scheme : nil
    }

    private static func baseURLString(scheme: String, host: String, port: Int) -> String? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        return components.url?.absoluteString.trimmingSuffix("/")
    }

    private static func relayURLString(base: String?, path: String?) -> String? {
        guard
            let base = base?.nonEmptyTrimmed?.trimmingSuffix("/"),
            let path = path?.nonEmptyTrimmed
        else {
            return nil
        }

        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        return AppSettingsStore.validatedURL(from: base + normalizedPath)?.absoluteString.trimmingSuffix("/")
    }
}

extension LocalServerDiscovery: NetServiceBrowserDelegate {
    nonisolated func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        MainActor.assumeIsolated {
            isSearching = true
            errorMessage = nil
        }
    }

    nonisolated func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        MainActor.assumeIsolated {
            isSearching = false
        }
    }

    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didNotSearch errorDict: [String: NSNumber]
    ) {
        MainActor.assumeIsolated {
            isSearching = false
            errorMessage = "Local discovery could not start. Check Local Network permission for PCloud."
        }
    }

    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind service: NetService,
        moreComing: Bool
    ) {
        MainActor.assumeIsolated {
            addService(service)
        }
    }

    nonisolated func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didRemove service: NetService,
        moreComing: Bool
    ) {
        MainActor.assumeIsolated {
            removeService(service)
        }
    }
}

extension LocalServerDiscovery: NetServiceDelegate {
    nonisolated func netServiceDidResolveAddress(_ sender: NetService) {
        MainActor.assumeIsolated {
            resolve(sender)
        }
    }

    nonisolated func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        MainActor.assumeIsolated {
            removeService(sender)
        }
    }
}

private extension String {
    var nonEmptyTrimmed: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func trimmingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else {
            return self
        }

        return String(dropLast(suffix.count))
    }
}
