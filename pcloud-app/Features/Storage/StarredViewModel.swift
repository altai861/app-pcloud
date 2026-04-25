import Foundation
import Combine

@MainActor
final class StarredViewModel: ObservableObject {
    @Published private(set) var entries: [StorageEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isMutating = false
    @Published var errorMessage: String?

    private var hasLoadedInitialState = false

    func loadInitial(using sessionStore: SessionStore) async {
        guard !hasLoadedInitialState else {
            return
        }

        hasLoadedInitialState = true
        await refresh(using: sessionStore)
    }

    func refresh(using sessionStore: SessionStore) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            entries = try await sessionStore.makeStorageAPI().listStarred().entries
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func setEntryStarred(
        _ entry: StorageEntry,
        starred: Bool,
        using sessionStore: SessionStore
    ) async throws -> StorageEntry {
        isMutating = true
        errorMessage = nil

        defer { isMutating = false }

        do {
            let updatedEntry = try await sessionStore.makeStorageAPI().setStarred(
                path: entry.path,
                entryType: entry.entryType,
                starred: starred
            )
            applyUpdatedEntry(updatedEntry)
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

    func moveEntryToTrash(
        _ entry: StorageEntry,
        using sessionStore: SessionStore
    ) async throws {
        isMutating = true
        errorMessage = nil

        defer { isMutating = false }

        do {
            _ = try await sessionStore.makeStorageAPI().moveToTrash(entry: entry)
            entries.removeAll { $0.id == entry.id }
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
            _ = try await sessionStore.makeStorageAPI().renameEntry(entry, newName: newName)
            entries = try await sessionStore.makeStorageAPI().listStarred().entries
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
            _ = try await sessionStore.makeStorageAPI().moveEntry(
                entry,
                destinationFolderID: destinationFolderID
            )
            entries = try await sessionStore.makeStorageAPI().listStarred().entries
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

    private func applyUpdatedEntry(_ updatedEntry: StorageEntry) {
        if updatedEntry.isStarred {
            if let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) {
                entries[index] = updatedEntry
            } else {
                entries.insert(updatedEntry, at: 0)
            }
        } else {
            entries.removeAll { $0.id == updatedEntry.id }
        }
    }
}
