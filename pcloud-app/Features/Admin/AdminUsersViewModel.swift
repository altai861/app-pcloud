import Foundation
import Combine

@MainActor
final class AdminUsersViewModel: ObservableObject {
    @Published private(set) var users: [AdminUser] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    func load(using sessionStore: SessionStore) async {
        if !users.isEmpty {
            return
        }

        await refresh(using: sessionStore)
    }

    func refresh(using sessionStore: SessionStore) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let api = try sessionStore.makeAdminAPI()
            users = try await api.listUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createUser(
        username: String,
        email: String,
        fullName: String,
        password: String,
        passwordConfirmation: String,
        storageQuotaBytes: Int64,
        using sessionStore: SessionStore
    ) async throws {
        let api = try sessionStore.makeAdminAPI()
        let created = try await api.createUser(
            username: username,
            email: email,
            fullName: fullName,
            password: password,
            passwordConfirmation: passwordConfirmation,
            storageQuotaBytes: storageQuotaBytes
        )

        users.append(created)
        users.sort { $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending }
    }

    func updateUser(
        userID: Int64,
        username: String,
        email: String,
        fullName: String,
        storageQuotaBytes: Int64,
        using sessionStore: SessionStore
    ) async throws {
        let api = try sessionStore.makeAdminAPI()
        let updated = try await api.updateUser(
            userID: userID,
            username: username,
            email: email,
            fullName: fullName,
            storageQuotaBytes: storageQuotaBytes
        )

        replaceUser(updated)
    }

    func deleteUser(userID: Int64, using sessionStore: SessionStore) async throws {
        let api = try sessionStore.makeAdminAPI()
        try await api.deleteUser(userID: userID)
        users.removeAll { $0.id == userID }
    }

    private func replaceUser(_ user: AdminUser) {
        guard let index = users.firstIndex(where: { $0.id == user.id }) else {
            users.append(user)
            return
        }

        users[index] = user
    }
}
