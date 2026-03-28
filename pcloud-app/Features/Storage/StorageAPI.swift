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
}
