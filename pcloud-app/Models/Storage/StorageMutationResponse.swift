import Foundation

struct StorageMutationResponse: Decodable {
    let message: String
    let entry: StorageEntry
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
