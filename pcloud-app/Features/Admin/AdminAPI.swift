import Foundation

struct AdminAPI {
    let client: APIClient
    let accessToken: String

    func listUsers() async throws -> [AdminUser] {
        let response: AdminUserListResponse = try await client.get(
            path: "/api/client/admin/users",
            bearerToken: accessToken
        )
        return response.users
    }

    func createUser(
        username: String,
        email: String,
        fullName: String,
        password: String,
        passwordConfirmation: String,
        storageQuotaBytes: Int64
    ) async throws -> AdminUser {
        let response: AdminCreateUserResponse = try await client.post(
            path: "/api/client/admin/users",
            bearerToken: accessToken,
            body: AdminCreateUserRequest(
                username: username,
                email: email,
                fullName: fullName,
                password: password,
                passwordConfirmation: passwordConfirmation,
                storageQuotaBytes: storageQuotaBytes
            )
        )

        return response.user
    }

    func updateUser(
        userID: Int64,
        username: String,
        email: String,
        fullName: String,
        storageQuotaBytes: Int64
    ) async throws -> AdminUser {
        let response: AdminUpdateUserResponse = try await client.put(
            path: "/api/client/admin/users/\(userID)",
            bearerToken: accessToken,
            body: AdminUpdateUserRequest(
                username: username,
                email: email,
                fullName: fullName,
                storageQuotaBytes: storageQuotaBytes
            )
        )

        return response.user
    }

    func deleteUser(userID: Int64) async throws {
        let _: AdminDeleteUserResponse = try await client.delete(
            path: "/api/client/admin/users/\(userID)",
            bearerToken: accessToken
        )
    }
}
