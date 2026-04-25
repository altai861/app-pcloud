import Foundation

struct StorageMutationResponse: Decodable {
    let message: String
    let entry: StorageEntry
}

struct StorageTrashResponse: Decodable {
    let message: String
    let deletedPath: String
    let entryType: String
    let reclaimedBytes: Int64?
}

struct StorageRestoreResponse: Decodable {
    let message: String
    let restoredPath: String
    let entryType: String
}

struct StorageMoveResponse: Decodable {
    let message: String
    let movedCount: Int
    let destinationFolderId: Int64
    let destinationPath: String
}

struct CreateFolderRequest: Encodable {
    let parentPath: String?
    let parentFolderId: Int64?
    let name: String
}

struct SetStarredRequest: Encodable {
    let path: String
    let entryType: String
    let starred: Bool
}

struct MoveStorageRequest: Encodable {
    let destinationFolderId: Int64
    let items: [MoveStorageItemRequest]
}

struct MoveStorageItemRequest: Encodable {
    let entryType: String
    let resourceId: Int64
}

struct RenameStorageRequest: Encodable {
    let path: String
    let resourceId: Int64
    let newName: String
}

struct UpsertSharePermissionRequest: Encodable {
    let entryType: String
    let resourceId: Int64
    let targetUserId: Int64
    let privilegeType: String
}
