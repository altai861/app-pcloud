import SwiftUI

struct StarredView: View {
    @ObservedObject var viewModel: StarredViewModel
    let onMenuTap: () -> Void
    let onOpenFolder: (StorageEntry) -> Void
    let onEntryUpdated: (StorageEntry) -> Void

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @State private var showingProfileSheet = false
    @State private var selectedFileEntry: StorageEntry?

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        content(strings: strings)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 140)
                }
                .refreshable {
                    await viewModel.refresh(using: sessionStore)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onMenuTap) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(AppPalette.textPrimary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(strings.starred)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    CurrentUserProfileButton {
                        showingProfileSheet = true
                    }
                }
            }
            .task {
                await viewModel.loadInitial(using: sessionStore)
            }
            .sheet(isPresented: $showingProfileSheet) {
                ProfileSheetView()
            }
            .sheet(item: $selectedFileEntry) { entry in
                let selectedEntry = entry
                StorageFilePlaceholderSheet(
                    entry: entry,
                    onToggleStar: { starred in
                        let updatedEntry = try await viewModel.setEntryStarred(
                            selectedEntry,
                            starred: starred,
                            using: sessionStore
                        )
                        onEntryUpdated(updatedEntry)
                        selectedFileEntry = updatedEntry.isStarred ? updatedEntry : nil
                        return updatedEntry.isStarred
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func content(strings: AppStrings) -> some View {
        if viewModel.isLoading && viewModel.entries.isEmpty {
            ProgressView(strings.loadingStorage)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .appCard()
        } else if let errorMessage = viewModel.errorMessage, viewModel.entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.storageLoadErrorTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        } else if viewModel.entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.noStarredItemsTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(strings.noStarredItemsSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        } else {
            VStack(spacing: 12) {
                ForEach(viewModel.entries) { entry in
                    StorageEntryRow(
                        entry: entry,
                        action: { openEntry(entry) },
                        onRenameEntry: renameEntryAction,
                        onMoveEntry: moveEntryAction,
                        onMoveToTrash: moveEntryToTrashAction
                    )
                }
            }
        }
    }

    @MainActor
    private func renameEntryAction(_ selectedEntry: StorageEntry, _ newName: String) async throws {
        try await viewModel.renameEntry(
            selectedEntry,
            newName: newName,
            using: sessionStore
        )
    }

    @MainActor
    private func moveEntryAction(_ selectedEntry: StorageEntry, _ destinationFolderID: Int64) async throws {
        try await viewModel.moveEntry(
            selectedEntry,
            destinationFolderID: destinationFolderID,
            using: sessionStore
        )
    }

    @MainActor
    private func moveEntryToTrashAction(_ selectedEntry: StorageEntry) async throws {
        try await viewModel.moveEntryToTrash(
            selectedEntry,
            using: sessionStore
        )
    }

    private func openEntry(_ entry: StorageEntry) {
        if entry.isFolder {
            onOpenFolder(entry)
        } else {
            selectedFileEntry = entry
        }
    }
}
