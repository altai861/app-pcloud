import Foundation

struct AuthAPI {
    let client: APIClient

    func login(username: String, password: String) async throws -> LoginResponse {
        try await client.post(
            path: "/api/client/auth/login",
            body: LoginRequest(
                username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        )
    }

    func fetchCurrentUser(accessToken: String) async throws -> MeResponse {
        try await client.get(
            path: "/api/client/me",
            bearerToken: accessToken
        )
    }

    func logout(accessToken: String) async throws -> LogoutResponse {
        try await client.post(
            path: "/api/client/auth/logout",
            bearerToken: accessToken
        )
    }

    func uploadProfileImage(
        accessToken: String,
        imageData: Data,
        fileName: String,
        contentType: String
    ) async throws -> UpdateProfileImageResponse {
        try await client.postMultipart(
            path: "/api/client/me/profile-image",
            bearerToken: accessToken,
            parts: [
                .file(
                    name: "image",
                    filename: fileName,
                    contentType: contentType,
                    data: imageData
                )
            ]
        )
    }
}
