import SwiftUI

struct TrashView: View {
    @ObservedObject var viewModel: TrashViewModel
    let onMenuTap: () -> Void

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @State private var showingProfileSheet = false
    @State private var searchText = ""
    @State private var pendingPermanentDeleteEntry: StorageEntry?

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                VStack(alignment: .leading, spacing: 14) {
                    header(strings: strings)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            content(strings: strings)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 148)
                    }
                    .refreshable {
                        await viewModel.refresh(using: sessionStore)
                    }
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
                    Text(strings.trash)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    CurrentUserProfileButton {
                        showingProfileSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingProfileSheet) {
                ProfileSheetView()
            }
            .confirmationDialog(
                strings.deletePermanentlyConfirmTitle,
                isPresented: Binding(
                    get: { pendingPermanentDeleteEntry != nil },
                    set: { isPresented in
                        if !isPresented {
                            pendingPermanentDeleteEntry = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button(strings.cancel, role: .cancel) {
                    pendingPermanentDeleteEntry = nil
                }

                if let entry = pendingPermanentDeleteEntry {
                    Button(strings.deletePermanently, role: .destructive) {
                        permanentlyDelete(entry)
                    }
                }
            } message: {
                if let entry = pendingPermanentDeleteEntry {
                    Text(
                        strings.deletePermanentlyConfirmMessage(
                            entryName: entry.name,
                            isFolder: entry.isFolder
                        )
                    )
                }
            }
            .task {
                await viewModel.loadInitial(using: sessionStore)
            }
        }
    }

    private func header(strings: AppStrings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppPalette.textSecondary)

                TextField(strings.trashSearchPlaceholder, text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(AppPalette.cardStrong)
            )
            .overlay(
                Capsule()
                    .stroke(AppPalette.stroke, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(strings.trash)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(strings.trashSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.textSecondary)
            }
            .appCard(padding: 18)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private func content(strings: AppStrings) -> some View {
        if viewModel.isLoading && viewModel.entries.isEmpty {
            ProgressView(strings.loadingTrash)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .appCard()
        } else if let errorMessage = viewModel.errorMessage, viewModel.entries.isEmpty, !errorMessage.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.trashLoadErrorTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        } else {
            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(strings.trashLoadErrorTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard()
            }

            if filteredEntries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? strings.noTrashItemsTitle : strings.noMatchesTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? strings.noTrashItemsSubtitle : strings.noMatchesSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredEntries) { entry in
                        TrashEntryRow(
                            entry: entry,
                            isBusy: viewModel.isMutating,
                            onRestore: { restore(entry) },
                            onDelete: { pendingPermanentDeleteEntry = entry }
                        )
                    }
                }
            }
        }
    }

    private var filteredEntries: [StorageEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !query.isEmpty else {
            return viewModel.entries
        }

        return viewModel.entries.filter { entry in
            entry.name.lowercased().contains(query)
                || entry.path.lowercased().contains(query)
                || entry.ownerUsername.lowercased().contains(query)
        }
    }

    private func restore(_ entry: StorageEntry) {
        Task {
            try? await viewModel.restoreEntry(entry, using: sessionStore)
        }
    }

    private func permanentlyDelete(_ entry: StorageEntry) {
        pendingPermanentDeleteEntry = nil

        Task {
            try? await viewModel.permanentlyDeleteEntry(entry, using: sessionStore)
        }
    }
}

private struct TrashEntryRow: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: StorageEntry
    let isBusy: Bool
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(entry.isFolder ? AppPalette.softBlue : AppPalette.cardStrong)
                .frame(width: 46, height: 46)
                .overlay {
                    Image(systemName: entry.isFolder ? "folder.fill" : "doc.text.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(entry.isFolder ? AppPalette.softBlueDeep : AppPalette.textPrimary)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text(entry.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .lineLimit(1)

                    if entry.isStarred {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                Text(entry.path)
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 8) {
                    Text(deletedLabel)

                    if let sizeLabel {
                        Text("•")
                        Text(sizeLabel)
                    }
                }
                .font(.caption2)
                .foregroundStyle(AppPalette.textSecondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(action: onRestore) {
                    Text(settingsStore.strings.restore)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(AppPalette.softBlue)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isBusy)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(AppPalette.cardStrong)
                        )
                        .overlay(
                            Circle()
                                .stroke(AppPalette.stroke, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppPalette.cardStrong)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppPalette.stroke, lineWidth: 1)
        )
    }

    private var sizeLabel: String? {
        guard let sizeBytes = entry.sizeBytes else {
            return nil
        }

        return ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    private var deletedLabel: String {
        let strings = settingsStore.strings

        guard let modifiedAtUnixMs = entry.modifiedAtUnixMs else {
            return strings.deletedRecently
        }

        let date = Date(timeIntervalSince1970: TimeInterval(modifiedAtUnixMs) / 1000)
        return strings.deletedOn(date, locale: settingsStore.locale)
    }
}
