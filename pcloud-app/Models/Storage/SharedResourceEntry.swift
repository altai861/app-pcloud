import Foundation

struct SharedResourceEntry: Codable, Identifiable, Sendable {
    let resourceType: String
    let resourceId: Int64
    let name: String
    let path: String
    let ownerUserId: Int64
    let ownerUsername: String
    let createdByUserId: Int64?
    let createdByUsername: String
    let privilegeType: String
    let dateSharedUnixMs: Int64

    var id: String {
        "\(resourceType)-\(resourceId)"
    }

    var isFolder: Bool {
        resourceType == "folder"
    }
}

struct SharedListResponse: Codable, Sendable {
    let entries: [SharedResourceEntry]
}

struct SharePermission: Codable, Identifiable, Sendable {
    let userId: Int64
    let username: String
    let fullName: String
    let privilegeType: String
    let createdAtUnixMs: Int64

    var id: Int64 { userId }
}

struct SharePermissionsResponse: Codable, Sendable {
    let resourceType: String
    let resourceId: Int64
    let resourceName: String
    let entries: [SharePermission]
}

struct ShareableUser: Codable, Identifiable, Sendable {
    let userId: Int64
    let username: String
    let fullName: String

    var id: Int64 { userId }
}

struct ShareableUsersResponse: Codable, Sendable {
    let users: [ShareableUser]
}

struct ShareMutationResponse: Codable, Sendable {
    let message: String
}

extension SharedResourceEntry {
    func asStorageEntry() -> StorageEntry {
        StorageEntry(
            rawID: resourceId,
            name: name,
            path: path,
            entryType: resourceType,
            ownerUserId: ownerUserId,
            ownerUsername: ownerUsername,
            createdByUserId: createdByUserId,
            createdByUsername: createdByUsername,
            isStarred: false,
            sizeBytes: nil,
            modifiedAtUnixMs: nil
        )
    }
}
