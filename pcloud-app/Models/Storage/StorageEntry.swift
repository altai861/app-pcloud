import Foundation

struct StorageEntry: Codable, Identifiable, Sendable {
    let rawID: Int64
    let name: String
    let path: String
    let entryType: String
    let ownerUserId: Int64
    let ownerUsername: String
    let createdByUserId: Int64?
    let createdByUsername: String
    let isStarred: Bool
    let sizeBytes: Int64?
    let modifiedAtUnixMs: Int64?

    enum CodingKeys: String, CodingKey {
        case rawID = "id"
        case name
        case path
        case entryType
        case ownerUserId
        case ownerUsername
        case createdByUserId
        case createdByUsername
        case isStarred
        case sizeBytes
        case modifiedAtUnixMs
    }

    var id: String {
        "\(entryType)-\(rawID)"
    }

    var isFolder: Bool {
        entryType == "folder"
    }
}
