import Foundation

struct LoginResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresAt: String
    let user: AuthUser
}
