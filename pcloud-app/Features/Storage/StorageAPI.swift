import Foundation

struct StorageAPI {
    let client: APIClient
    let accessToken: String

    func list(path: String = "/") async throws -> StorageListResponse {
        try await client.get(
            path: "/api/client/storage/list",
            bearerToken: accessToken,
            queryItems: [
                URLQueryItem(name: "path", value: path)
            ]
        )
    }

    func listByFolderID(_ folderID: Int64) async throws -> StorageListResponse {
        try await client.get(
            path: "/api/client/storage/list",
            bearerToken: accessToken,
            queryItems: [
                URLQueryItem(name: "folderId", value: String(folderID))
            ]
        )
    }

    func listStarred(search: String? = nil) async throws -> StorageListResponse {
        var queryItems: [URLQueryItem] = []

        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: search.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        return try await client.get(
            path: "/api/client/storage/starred/list",
            bearerToken: accessToken,
            queryItems: queryItems
        )
    }

    func listTrash(search: String? = nil) async throws -> StorageListResponse {
        var queryItems: [URLQueryItem] = []

        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: search.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        return try await client.get(
            path: "/api/client/storage/trash/list",
            bearerToken: accessToken,
            queryItems: queryItems
        )
    }

    func createFolder(
        name: String,
        parentPath: String?,
        parentFolderID: Int64?
    ) async throws -> StorageEntry {
        let response: StorageMutationResponse = try await client.post(
            path: "/api/client/storage/folders",
            bearerToken: accessToken,
            body: CreateFolderRequest(
                parentPath: parentPath,
                parentFolderId: parentFolderID,
                name: name
            )
        )

        return response.entry
    }

    func uploadFile(
        fileData: Data,
        fileName: String,
        contentType: String?,
        targetPath: String?,
        targetFolderID: Int64?
    ) async throws -> StorageEntry {
        var parts: [MultipartFormPart] = []

        if let targetPath, !targetPath.isEmpty {
            parts.append(.text(name: "path", value: targetPath))
        }

        if let targetFolderID {
            parts.append(.text(name: "folderId", value: String(targetFolderID)))
        }

        parts.append(
            .file(
                name: "file",
                filename: fileName,
                contentType: contentType,
                data: fileData
            )
        )

        let response: StorageMutationResponse = try await client.postMultipart(
            path: "/api/client/storage/files/upload",
            bearerToken: accessToken,
            parts: parts
        )

        return response.entry
    }

    func setStarred(
        path: String,
        entryType: String,
        starred: Bool
    ) async throws -> StorageEntry {
        let response: StorageMutationResponse = try await client.put(
            path: "/api/client/storage/starred",
            bearerToken: accessToken,
            body: SetStarredRequest(
                path: path,
                entryType: entryType,
                starred: starred
            )
        )

        return response.entry
    }

    func renameEntry(
        _ entry: StorageEntry,
        newName: String
    ) async throws -> StorageEntry {
        let response: StorageMutationResponse = try await client.put(
            path: entry.isFolder ? "/api/client/storage/folders" : "/api/client/storage/files",
            bearerToken: accessToken,
            body: RenameStorageRequest(
                path: entry.path,
                resourceId: entry.rawID,
                newName: newName
            )
        )

        return response.entry
    }

    func moveEntry(
        _ entry: StorageEntry,
        destinationFolderID: Int64
    ) async throws -> StorageMoveResponse {
        try await client.post(
            path: "/api/client/storage/move",
            bearerToken: accessToken,
            body: MoveStorageRequest(
                destinationFolderId: destinationFolderID,
                items: [
                    MoveStorageItemRequest(
                        entryType: entry.entryType,
                        resourceId: entry.rawID
                    )
                ]
            )
        )
    }

    func moveToTrash(entry: StorageEntry) async throws -> StorageTrashResponse {
        let idParamName = entry.isFolder ? "folderId" : "fileId"
        return try await client.delete(
            path: entry.isFolder ? "/api/client/storage/folders" : "/api/client/storage/files",
            bearerToken: accessToken,
            queryItems: [
                URLQueryItem(name: idParamName, value: String(entry.rawID))
            ]
        )
    }

    func permanentlyDeleteTrashedEntry(_ entry: StorageEntry) async throws -> StorageTrashResponse {
        try await client.delete(
            path: entry.isFolder ? "/api/client/storage/trash/folders" : "/api/client/storage/trash/files",
            bearerToken: accessToken,
            queryItems: [
                URLQueryItem(name: "path", value: entry.path)
            ]
        )
    }

    func restoreTrashedEntry(_ entry: StorageEntry) async throws -> StorageRestoreResponse {
        try await client.post(
            path: entry.isFolder ? "/api/client/storage/trash/folders/restore" : "/api/client/storage/trash/files/restore",
            bearerToken: accessToken,
            queryItems: [
                URLQueryItem(name: "path", value: entry.path)
            ]
        )
    }

    func listShared(search: String? = nil) async throws -> SharedListResponse {
        var queryItems: [URLQueryItem] = []

        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: search.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        return try await client.get(
            path: "/api/client/storage/shared/list",
            bearerToken: accessToken,
            queryItems: queryItems
        )
    }

    func listSharePermissions(entryType: String, resourceId: Int64) async throws -> SharePermissionsResponse {
        try await client.get(
            path: "/api/client/storage/shares",
            bearerToken: accessToken,
            queryItems: [
                URLQueryItem(name: "entryType", value: entryType),
                URLQueryItem(name: "resourceId", value: String(resourceId))
            ]
        )
    }

    func upsertSharePermission(
        entryType: String,
        resourceId: Int64,
        targetUserId: Int64,
        privilegeType: String
    ) async throws -> ShareMutationResponse {
        try await client.put(
            path: "/api/client/storage/shares",
            bearerToken: accessToken,
            body: UpsertSharePermissionRequest(
                entryType: entryType,
                resourceId: resourceId,
                targetUserId: targetUserId,
                privilegeType: privilegeType
            )
        )
    }

    func removeSharePermission(
        entryType: String,
        resourceId: Int64,
        targetUserId: Int64
    ) async throws -> ShareMutationResponse {
        try await client.delete(
            path: "/api/client/storage/shares",
            bearerToken: accessToken,
            queryItems: [
                URLQueryItem(name: "entryType", value: entryType),
                URLQueryItem(name: "resourceId", value: String(resourceId)),
                URLQueryItem(name: "targetUserId", value: String(targetUserId))
            ]
        )
    }

    func searchShareableUsers(search: String? = nil) async throws -> ShareableUsersResponse {
        var queryItems: [URLQueryItem] = []

        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: search.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        return try await client.get(
            path: "/api/client/storage/shares/users",
            bearerToken: accessToken,
            queryItems: queryItems
        )
    }

    func fileMetadata(fileID: Int64) async throws -> StorageFileMetadata {
        try await client.get(
            path: "/api/client/storage/files/metadata",
            bearerToken: accessToken,
            queryItems: [
                URLQueryItem(name: "fileId", value: String(fileID))
            ]
        )
    }

    func downloadFile(entry: StorageEntry) async throws -> StorageDownloadedFile {
        try await downloadFile(fileID: entry.rawID, fileName: entry.name)
    }

    func downloadFile(fileID: Int64, fileName: String) async throws -> StorageDownloadedFile {
        let response = try await client.download(
            path: "/api/client/storage/files/download",
            bearerToken: accessToken,
            queryItems: [
                URLQueryItem(name: "fileId", value: String(fileID))
            ]
        )

        let resolvedFileName = self.fileName(
            from: response.response.value(forHTTPHeaderField: "Content-Disposition"),
            fallback: fileName
        )

        let downloadsDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("storage-downloads", isDirectory: true)

        try FileManager.default.createDirectory(
            at: downloadsDirectory,
            withIntermediateDirectories: true
        )

        let destinationURL = downloadsDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathExtension("download")
            .deletingPathExtension()
            .appendingPathComponent(resolvedFileName)

        try FileManager.default.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.moveItem(
            at: response.temporaryFileURL,
            to: destinationURL
        )

        return StorageDownloadedFile(
            fileURL: destinationURL,
            fileName: resolvedFileName,
            mimeType: response.response.mimeType
        )
    }

    func renameSharedEntry(
        path: String,
        resourceId: Int64,
        isFolder: Bool,
        newName: String
    ) async throws -> StorageMutationResponse {
        try await client.put(
            path: isFolder ? "/api/client/storage/folders" : "/api/client/storage/files",
            bearerToken: accessToken,
            body: RenameStorageRequest(
                path: path,
                resourceId: resourceId,
                newName: newName
            )
        )
    }

    private func fileName(from contentDisposition: String?, fallback: String) -> String {
        guard let contentDisposition else {
            return fallback
        }

        let components = contentDisposition
            .split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if let encodedValue = components.first(where: { $0.lowercased().hasPrefix("filename*=") }) {
            let rawValue = String(encodedValue.dropFirst("filename*=".count))
            let cleanedValue = rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let segments = cleanedValue.split(separator: "'", maxSplits: 2, omittingEmptySubsequences: false)

            if let encodedName = segments.last {
                let decodedName = encodedName.replacingOccurrences(of: "+", with: "%20")
                if let parsedName = decodedName.removingPercentEncoding, !parsedName.isEmpty {
                    return parsedName
                }
            }
        }

        if let plainValue = components.first(where: { $0.lowercased().hasPrefix("filename=") }) {
            let rawValue = String(plainValue.dropFirst("filename=".count))
            let cleanedValue = rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

            if !cleanedValue.isEmpty {
                return cleanedValue
            }
        }

        return fallback
    }
}

struct StorageDownloadedFile {
    let fileURL: URL
    let fileName: String
    let mimeType: String?
}
