import Foundation
import Combine

@MainActor
final class SharedViewModel: ObservableObject {
    @Published private(set) var entries: [SharedResourceEntry] = []
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

    func renameEntry(_ entry: SharedResourceEntry, newName: String, using sessionStore: SessionStore) async throws {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard newName != entry.name else { return }

        isMutating = true
        errorMessage = nil

        defer { isMutating = false }

        do {
            let api = try sessionStore.makeStorageAPI()
            _ = try await api.renameSharedEntry(
                path: entry.path,
                resourceId: entry.resourceId,
                isFolder: entry.isFolder,
                newName: newName
            )
            await refresh(using: sessionStore)
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

    func refresh(using sessionStore: SessionStore) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let api = try sessionStore.makeStorageAPI()
            let response = try await api.listShared()
            entries = response.entries
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
