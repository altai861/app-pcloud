import Foundation

struct AuthUser: Codable, Identifiable {
    let id: Int64
    let username: String
    let fullName: String
    let role: String
    let storageQuotaBytes: Int64
    let storageUsedBytes: Int64
    let profileImageUrl: String?
}

extension AuthUser {
    var isAdmin: Bool {
        role.caseInsensitiveCompare("admin") == .orderedSame
    }
}
