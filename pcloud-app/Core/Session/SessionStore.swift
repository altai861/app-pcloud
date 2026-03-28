import Foundation
import Combine

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var currentUser: AuthUser?
    @Published private(set) var accessToken: String?
    @Published private(set) var isRestoringSession = false
    @Published private(set) var profileImageRevision = UUID().uuidString

    private let settingsStore: AppSettingsStore
    private let tokenStore: KeychainAccessTokenStore
    private var hasAttemptedRestore = false

    init(
        settingsStore: AppSettingsStore,
        tokenStore: KeychainAccessTokenStore? = nil
    ) {
        self.settingsStore = settingsStore
        self.tokenStore = tokenStore ?? KeychainAccessTokenStore()
    }

    var isAuthenticated: Bool {
        accessToken != nil && currentUser != nil
    }

    func restoreSessionIfNeeded() async {
        guard !hasAttemptedRestore else {
            return
        }

        hasAttemptedRestore = true
        isRestoringSession = true
        defer { isRestoringSession = false }

        do {
            guard let savedToken = try tokenStore.readAccessToken(), !savedToken.isEmpty else {
                return
            }

            let meResponse = try await makeAuthAPI().fetchCurrentUser(accessToken: savedToken)
            applyAuthenticatedSession(accessToken: savedToken, user: meResponse.user)
        } catch {
            clearSessionState()
            try? tokenStore.deleteAccessToken()
        }
    }

    func login(username: String, password: String) async throws {
        let response = try await makeAuthAPI().login(username: username, password: password)
        try tokenStore.saveAccessToken(response.accessToken)
        applyAuthenticatedSession(accessToken: response.accessToken, user: response.user)
    }

    func logout() async {
        if let accessToken {
            do {
                _ = try await makeAuthAPI().logout(accessToken: accessToken)
            } catch {
                // Clear the local session even if the remote revoke fails.
            }
        }

        clearSessionState()
        try? tokenStore.deleteAccessToken()
    }

    func clearSessionLocally() {
        clearSessionState()
        try? tokenStore.deleteAccessToken()
    }

    func uploadProfileImage(
        imageData: Data,
        fileName: String,
        contentType: String
    ) async throws {
        guard let accessToken, !accessToken.isEmpty else {
            throw SessionStoreError.notAuthenticated
        }

        let response = try await makeAuthAPI().uploadProfileImage(
            accessToken: accessToken,
            imageData: imageData,
            fileName: fileName,
            contentType: contentType
        )

        currentUser = response.user
        profileImageRevision = UUID().uuidString
    }

    func profileImageURL(for userID: Int64) -> URL? {
        guard
            let baseURL = settingsStore.apiBaseURL,
            let accessToken,
            !accessToken.isEmpty
        else {
            return nil
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let basePath = components?.path == "/" ? "" : (components?.path ?? "")
        components?.path = basePath + "/api/client/users/profile-image"
        components?.queryItems = [
            URLQueryItem(name: "userId", value: String(userID)),
            URLQueryItem(name: "accessToken", value: accessToken),
            URLQueryItem(name: "rev", value: profileImageRevision)
        ]

        return components?.url
    }

    func makeStorageAPI() throws -> StorageAPI {
        guard let accessToken, !accessToken.isEmpty else {
            throw SessionStoreError.notAuthenticated
        }

        return StorageAPI(client: try makeClient(), accessToken: accessToken)
    }

    func makeAdminAPI() throws -> AdminAPI {
        guard let accessToken, !accessToken.isEmpty else {
            throw SessionStoreError.notAuthenticated
        }

        return AdminAPI(client: try makeClient(), accessToken: accessToken)
    }

    private func makeAuthAPI() throws -> AuthAPI {
        AuthAPI(client: try makeClient())
    }

    private func makeClient() throws -> APIClient {
        guard let baseURL = settingsStore.apiBaseURL else {
            throw SessionStoreError.invalidServerURL
        }

        return APIClient(baseURL: baseURL)
    }

    private func clearSessionState() {
        accessToken = nil
        currentUser = nil
        profileImageRevision = UUID().uuidString
    }

    private func applyAuthenticatedSession(accessToken: String, user: AuthUser) {
        self.accessToken = accessToken
        currentUser = user
        profileImageRevision = UUID().uuidString
    }
}

enum SessionStoreError: LocalizedError {
    case invalidServerURL
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            return "Set a valid API base URL before making requests."
        case .notAuthenticated:
            return "You need to sign in before loading storage."
        }
    }
}
