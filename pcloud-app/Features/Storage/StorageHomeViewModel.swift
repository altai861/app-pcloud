import Foundation
import Combine

struct StorageUploadItem {
    let data: Data
    let fileName: String
    let contentType: String?
}

struct StorageUploadProgress: Equatable {
    enum State: Equatable {
        case uploading
        case completed
    }

    let state: State
    let currentFileName: String?
    let completedCount: Int
    let totalCount: Int

    var currentItemNumber: Int {
        switch state {
        case .uploading:
            return min(completedCount + 1, totalCount)
        case .completed:
            return totalCount
        }
    }

    var displayProgress: Double {
        guard totalCount > 0 else {
            return 0
        }

        switch state {
        case .uploading:
            return min(0.94, (Double(completedCount) + 0.45) / Double(totalCount))
        case .completed:
            return 1
        }
    }
}

@MainActor
final class StorageHomeViewModel: ObservableObject {
    @Published private(set) var response: StorageListResponse?
    @Published private(set) var isLoading = false
    @Published private(set) var isMutating = false
    @Published private(set) var uploadProgress: StorageUploadProgress?
    @Published private(set) var currentFolderIsStarred = false
    @Published var errorMessage: String?

    private var hasLoadedInitialState = false
    private var uploadProgressDismissToken = UUID()
    private var starredStateByPath: [String: Bool] = ["/": false]

    var entries: [StorageEntry] {
        response?.entries ?? []
    }

    var currentPath: String {
        response?.currentPath ?? "/"
    }

    var parentPath: String? {
        response?.parentPath
    }

    var isAtRoot: Bool {
        currentPath == "/"
    }

    func loadInitial(using sessionStore: SessionStore) async {
        guard !hasLoadedInitialState else {
            return
        }

        hasLoadedInitialState = true
        await refresh(using: sessionStore)
    }

    func refresh(using sessionStore: SessionStore) async {
        await load(path: currentPath, using: sessionStore)
    }

    func openFolder(_ entry: StorageEntry, using sessionStore: SessionStore) async {
        guard entry.isFolder else {
            return
        }

        let isOwner = (response?.currentPrivilege ?? "owner").lowercased() == "owner"
        if isOwner {
            await load(path: entry.path, starredHint: entry.isStarred, using: sessionStore)
        } else {
            await loadByFolderID(entry.rawID, using: sessionStore)
        }
    }

    func openFolder(path: String, starredHint: Bool? = nil, using sessionStore: SessionStore) async {
        await load(path: path, starredHint: starredHint, using: sessionStore)
    }

    func openFolder(id folderID: Int64, using sessionStore: SessionStore) async {
        await loadByFolderID(folderID, using: sessionStore)
    }

    func goToParent(using sessionStore: SessionStore) async {
        guard !isAtRoot else {
            return
        }

        let isOwner = (response?.currentPrivilege ?? "owner").lowercased() == "owner"
        if !isOwner, let parentFolderID = response?.parentFolderId {
            await loadByFolderID(parentFolderID, using: sessionStore)
        } else {
            let targetPath = parentPath ?? "/"
            await load(path: targetPath, starredHint: starredStateByPath[targetPath], using: sessionStore)
        }
    }

    func setCurrentFolderStarred(_ starred: Bool, using sessionStore: SessionStore) async throws {
        guard currentPath != "/" else {
            return
        }

        do {
            let entry = try await setEntryStarred(
                path: currentPath,
                entryType: "folder",
                starred: starred,
                using: sessionStore
            )
            currentFolderIsStarred = entry.isStarred
            starredStateByPath[currentPath] = entry.isStarred
        } catch {
            throw error
        }
    }

    func syncEntryFromExternalUpdate(_ updatedEntry: StorageEntry) {
        applyUpdatedStarredEntry(updatedEntry)
    }

    @discardableResult
    func setEntryStarred(
        path: String,
        entryType: String,
        starred: Bool,
        using sessionStore: SessionStore
    ) async throws -> StorageEntry {
        isMutating = true
        errorMessage = nil

        defer { isMutating = false }

        do {
            let api = try sessionStore.makeStorageAPI()
            let updatedEntry = try await api.setStarred(
                path: path,
                entryType: entryType,
                starred: starred
            )
            applyUpdatedStarredEntry(updatedEntry)
            return updatedEntry
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription
            throw apiError
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    private func loadByFolderID(_ folderID: Int64, using sessionStore: SessionStore) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            response = try await sessionStore.makeStorageAPI().listByFolderID(folderID)
            cacheStarredStates(from: response)
            currentFolderIsStarred = false
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func load(path: String, starredHint: Bool? = nil, using sessionStore: SessionStore) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            response = try await sessionStore.makeStorageAPI().list(path: path)
            cacheStarredStates(from: response)
            currentFolderIsStarred = path == "/" ? false : (starredHint ?? starredStateByPath[path] ?? false)
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createFolder(name: String, using sessionStore: SessionStore) async throws {
        isMutating = true
        errorMessage = nil

        defer { isMutating = false }

        do {
            let api = try sessionStore.makeStorageAPI()
            _ = try await api.createFolder(
                name: name,
                parentPath: normalizedTargetPath,
                parentFolderID: response?.currentFolderId
            )
            response = try await refreshCurrentFolder(using: api)
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription
            throw apiError
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func moveEntry(
        _ entry: StorageEntry,
        destinationFolderID: Int64,
        using sessionStore: SessionStore
    ) async throws {
        isMutating = true
        errorMessage = nil

        defer { isMutating = false }

        do {
            let api = try sessionStore.makeStorageAPI()
            _ = try await api.moveEntry(entry, destinationFolderID: destinationFolderID)
            response = try await refreshCurrentFolder(using: api)
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription
            throw apiError
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func renameEntry(
        _ entry: StorageEntry,
        newName: String,
        using sessionStore: SessionStore
    ) async throws {
        guard !newName.isEmpty else {
            return
        }

        guard newName != entry.name else {
            return
        }

        isMutating = true
        errorMessage = nil

        defer { isMutating = false }

        do {
            let api = try sessionStore.makeStorageAPI()
            _ = try await api.renameEntry(entry, newName: newName)
            response = try await refreshCurrentFolder(using: api)
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription
            throw apiError
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func moveEntryToTrash(
        _ entry: StorageEntry,
        using sessionStore: SessionStore
    ) async throws {
        isMutating = true
        errorMessage = nil

        defer { isMutating = false }

        do {
            let api = try sessionStore.makeStorageAPI()
            _ = try await api.moveToTrash(entry: entry)
            response = try await refreshCurrentFolder(using: api)
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription
            throw apiError
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func uploadFile(
        data: Data,
        fileName: String,
        contentType: String?,
        using sessionStore: SessionStore
    ) async throws {
        try await uploadFiles(
            [
                StorageUploadItem(
                    data: data,
                    fileName: fileName,
                    contentType: contentType
                )
            ],
            using: sessionStore
        )
    }

    func uploadFiles(
        _ files: [StorageUploadItem],
        using sessionStore: SessionStore
    ) async throws {
        guard !files.isEmpty else {
            return
        }

        isMutating = true
        errorMessage = nil

        defer { isMutating = false }

        let api = try sessionStore.makeStorageAPI()
        var uploadedAnyFile = false
        beginUploadProgress(totalCount: files.count, currentFileName: files.first?.fileName)

        do {
            for (index, file) in files.enumerated() {
                uploadProgress = StorageUploadProgress(
                    state: .uploading,
                    currentFileName: file.fileName,
                    completedCount: index,
                    totalCount: files.count
                )

                _ = try await api.uploadFile(
                    fileData: file.data,
                    fileName: file.fileName,
                    contentType: file.contentType,
                    targetPath: normalizedTargetPath,
                    targetFolderID: response?.currentFolderId
                )
                uploadedAnyFile = true
            }

            response = try await refreshCurrentFolder(using: api)
            showUploadCompletion(totalCount: files.count)
        } catch let apiError as APIClientError {
            clearUploadProgress()

            if uploadedAnyFile {
                response = try? await refreshCurrentFolder(using: api)
            }

            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription
            throw apiError
        } catch {
            clearUploadProgress()

            if uploadedAnyFile {
                response = try? await refreshCurrentFolder(using: api)
            }

            errorMessage = error.localizedDescription
            throw error
        }
    }

    private var normalizedTargetPath: String? {
        currentPath == "/" ? nil : currentPath
    }

    private func refreshCurrentFolder(using api: StorageAPI) async throws -> StorageListResponse {
        if let folderID = response?.currentFolderId {
            return try await api.listByFolderID(folderID)
        }
        return try await api.list(path: currentPath)
    }

    private func cacheStarredStates(from response: StorageListResponse?) {
        response?.entries.forEach { entry in
            starredStateByPath[entry.path] = entry.isStarred
        }
    }

    private func applyUpdatedStarredEntry(_ updatedEntry: StorageEntry) {
        starredStateByPath[updatedEntry.path] = updatedEntry.isStarred

        if response != nil {
            var entries = response?.entries ?? []
            if let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) {
                entries[index] = updatedEntry
                response = StorageListResponse(
                    currentPath: response?.currentPath ?? "/",
                    currentFolderId: response?.currentFolderId,
                    parentFolderId: response?.parentFolderId,
                    parentPath: response?.parentPath,
                    currentPrivilege: response?.currentPrivilege ?? "owner",
                    entries: entries,
                    nextCursor: response?.nextCursor,
                    hasMore: response?.hasMore ?? false,
                    totalStorageLimitBytes: response?.totalStorageLimitBytes,
                    totalStorageUsedBytes: response?.totalStorageUsedBytes ?? 0,
                    userStorageQuotaBytes: response?.userStorageQuotaBytes ?? 0,
                    userStorageUsedBytes: response?.userStorageUsedBytes ?? 0
                )
            }
        }

        if updatedEntry.entryType == "folder" && updatedEntry.path == currentPath {
            currentFolderIsStarred = updatedEntry.isStarred
        }
    }

    private func beginUploadProgress(totalCount: Int, currentFileName: String?) {
        uploadProgressDismissToken = UUID()
        uploadProgress = StorageUploadProgress(
            state: .uploading,
            currentFileName: currentFileName,
            completedCount: 0,
            totalCount: totalCount
        )
    }

    private func showUploadCompletion(totalCount: Int) {
        let token = UUID()
        uploadProgressDismissToken = token
        uploadProgress = StorageUploadProgress(
            state: .completed,
            currentFileName: nil,
            completedCount: totalCount,
            totalCount: totalCount
        )

        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            await MainActor.run {
                guard self.uploadProgressDismissToken == token else {
                    return
                }

                self.uploadProgress = nil
            }
        }
    }

    private func clearUploadProgress() {
        uploadProgressDismissToken = UUID()
        uploadProgress = nil
    }
}
