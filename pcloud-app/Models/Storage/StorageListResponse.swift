import Foundation

struct StorageListResponse: Decodable {
    let currentPath: String
    let currentFolderId: Int64?
    let parentFolderId: Int64?
    let parentPath: String?
    let currentPrivilege: String
    let entries: [StorageEntry]
    let nextCursor: String?
    let hasMore: Bool
    let totalStorageLimitBytes: Int64?
    let totalStorageUsedBytes: Int64
    let userStorageQuotaBytes: Int64
    let userStorageUsedBytes: Int64
}
