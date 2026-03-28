import Foundation

struct UpdateProfileImageResponse: Decodable {
    let message: String
    let user: AuthUser
}
