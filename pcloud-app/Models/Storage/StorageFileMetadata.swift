import Foundation

struct StorageFileMetadata: Codable, Identifiable {
    let id: Int64
    let folderId: Int64
    let folderPath: String
    let ownerUserId: Int64
    let ownerUsername: String
    let currentPrivilege: String
    let name: String
    let path: String
    let sizeBytes: Int64
    let mimeType: String?
    let extensionValue: String?
    let isStarred: Bool
    let createdAtUnixMs: Int64
    let modifiedAtUnixMs: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case folderId
        case folderPath
        case ownerUserId
        case ownerUsername
        case currentPrivilege
        case name
        case path
        case sizeBytes
        case mimeType
        case extensionValue = "extension"
        case isStarred
        case createdAtUnixMs
        case modifiedAtUnixMs
    }
}
