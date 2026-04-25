import Foundation
import Combine

@MainActor
final class TrashViewModel: ObservableObject {
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
            entries = try await sessionStore.makeStorageAPI().listTrash().entries
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restoreEntry(
        _ entry: StorageEntry,
        using sessionStore: SessionStore
    ) async throws {
        isMutating = true
        errorMessage = nil

        defer { isMutating = false }

        do {
            _ = try await sessionStore.makeStorageAPI().restoreTrashedEntry(entry)
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

    func permanentlyDeleteEntry(
        _ entry: StorageEntry,
        using sessionStore: SessionStore
    ) async throws {
        isMutating = true
        errorMessage = nil

        defer { isMutating = false }

        do {
            _ = try await sessionStore.makeStorageAPI().permanentlyDeleteTrashedEntry(entry)
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
}
