import Foundation

struct AdminUser: Codable, Identifiable, Equatable {
    let id: Int64
    let username: String
    let email: String
    let fullName: String
    let role: String
    let status: String
    let storageQuotaBytes: Int64
    let storageUsedBytes: Int64
    let createdAtUnixMs: Int64
}

struct AdminUserListResponse: Decodable {
    let users: [AdminUser]
}

struct AdminCreateUserRequest: Encodable {
    let username: String
    let email: String
    let fullName: String
    let password: String
    let passwordConfirmation: String
    let storageQuotaBytes: Int64
}

struct AdminCreateUserResponse: Decodable {
    let message: String
    let user: AdminUser
}

struct AdminUpdateUserRequest: Encodable {
    let username: String
    let email: String
    let fullName: String
    let storageQuotaBytes: Int64
}

struct AdminUpdateUserResponse: Decodable {
    let message: String
    let user: AdminUser
}

struct AdminDeleteUserResponse: Decodable {
    let message: String
}
