import SwiftUI

struct SharedView: View {
    @ObservedObject var viewModel: SharedViewModel
    let onMenuTap: () -> Void
    let onOpenFolder: (SharedResourceEntry) -> Void

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @State private var showingProfileSheet = false
    @State private var searchText = ""

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                VStack(alignment: .leading, spacing: 14) {
                    searchBar(strings: strings)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12) {
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
                    Text(strings.shared)
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
        }
    }

    private func searchBar(strings: AppStrings) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppPalette.textSecondary)

            TextField(strings.sharedSearchPlaceholder, text: $searchText)
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
    }

    @ViewBuilder
    private func content(strings: AppStrings) -> some View {
        if viewModel.isLoading && viewModel.entries.isEmpty {
            ProgressView(strings.loadingShared)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .appCard()
        } else if let errorMessage = viewModel.errorMessage, viewModel.entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.sharedLoadErrorTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        } else if filteredEntries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(searchText.isEmpty ? strings.noSharedItemsTitle : strings.noMatchesTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(searchText.isEmpty ? strings.noSharedItemsSubtitle : strings.noMatchesSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        } else {
            ForEach(filteredEntries) { entry in
                sharedEntryRow(entry: entry, strings: strings)
            }
        }
    }

    private func sharedEntryRow(entry: SharedResourceEntry, strings: AppStrings) -> some View {
        HStack(spacing: 12) {
            Button {
                openEntry(entry)
            } label: {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(entry.isFolder ? AppPalette.softBlue : AppPalette.cardStrong)
                        .frame(width: 46, height: 46)
                        .overlay {
                            Image(systemName: entry.isFolder ? "folder.fill" : "doc.text.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(entry.isFolder ? AppPalette.softBlueDeep : AppPalette.textPrimary)
                        }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.name)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppPalette.textPrimary)
                            .lineLimit(1)

                        Text(entry.path)
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Text(strings.sharedByOwner(entry.ownerUsername))
                                .font(.caption2)
                                .foregroundStyle(AppPalette.textSecondary)

                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(AppPalette.textSecondary)

                            privilegeBadge(entry.privilegeType)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            SharedEntryActionsMenu(
                entry: entry,
                onOpen: { openEntry(entry) },
                onRename: { entry, newName in
                    try await viewModel.renameEntry(entry, newName: newName, using: sessionStore)
                }
            )
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

    private func privilegeBadge(_ privilege: String) -> some View {
        let isEditor = privilege.lowercased() == "editor" || privilege.lowercased() == "edit"
        return Text(isEditor ? settingsStore.strings.privilegeEditor : settingsStore.strings.privilegeViewer)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(isEditor ? AppPalette.softBlueDeep : AppPalette.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(isEditor ? AppPalette.softBlue : AppPalette.cardStrong)
            )
    }

    private var filteredEntries: [SharedResourceEntry] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return viewModel.entries
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return viewModel.entries.filter { entry in
            entry.name.lowercased().contains(query)
                || entry.ownerUsername.lowercased().contains(query)
                || entry.path.lowercased().contains(query)
        }
    }

    private func openEntry(_ entry: SharedResourceEntry) {
        if entry.isFolder {
            onOpenFolder(entry)
        }
    }
}

private struct SharedEntryActionsMenu: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: SharedResourceEntry
    var onOpen: (() -> Void)? = nil
    var onRename: (@MainActor @Sendable (SharedResourceEntry, String) async throws -> Void)? = nil

    @State private var showingRenameSheet = false
    @State private var showingPreviewSheet = false
    @State private var isDownloadingFile = false
    @State private var downloadErrorMessage: String?
    @State private var downloadedFile: SharedDownloadItem?

    private var isEditor: Bool {
        let p = entry.privilegeType.lowercased()
        return p == "editor" || p == "edit"
    }

    var body: some View {
        let strings = settingsStore.strings

        Menu {
            if entry.isFolder {
                Button(strings.openFolder, systemImage: "folder") {
                    onOpen?()
                }
            } else {
                Button(strings.previewFile, systemImage: "eye") {
                    showingPreviewSheet = true
                }

                Button(strings.downloadFile, systemImage: "arrow.down.circle") {
                    downloadFile()
                }
                .disabled(isDownloadingFile)

                if isEditor {
                    Divider()

                    Button(strings.rename, systemImage: "pencil") {
                        showingRenameSheet = true
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppPalette.textSecondary)
                .rotationEffect(.degrees(90))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(AppPalette.cardStrong)
                )
                .overlay(
                    Circle()
                        .stroke(AppPalette.stroke, lineWidth: 1)
                )
        }
        .accessibilityLabel(strings.entryActions)
        .buttonStyle(.plain)
        .sheet(item: $downloadedFile, onDismiss: clearDownloadedFile) { item in
            ActivityShareSheet(activityItems: [item.fileURL])
        }
        .sheet(isPresented: $showingPreviewSheet) {
            StorageFilePlaceholderSheet(entry: entry.asStorageEntry())
        }
        .sheet(isPresented: $showingRenameSheet) {
            if let onRename {
                SharedRenameSheet(entry: entry) { newName in
                    try await onRename(entry, newName)
                }
            }
        }
        .alert(
            strings.downloadFile,
            isPresented: Binding(
                get: { downloadErrorMessage != nil },
                set: { isPresented in
                    if !isPresented { downloadErrorMessage = nil }
                }
            ),
            actions: {
                Button(strings.cancel, role: .cancel) {
                    downloadErrorMessage = nil
                }
            },
            message: {
                Text(downloadErrorMessage ?? "")
            }
        )
    }

    @MainActor
    private func downloadFile() {
        guard !isDownloadingFile else { return }

        isDownloadingFile = true

        Task { @MainActor in
            do {
                let api = try sessionStore.makeStorageAPI()
                let file = try await api.downloadFile(fileID: entry.resourceId, fileName: entry.name)
                clearDownloadedFile()
                downloadedFile = SharedDownloadItem(fileURL: file.fileURL)
                isDownloadingFile = false
            } catch let apiError as APIClientError {
                if apiError.isUnauthorized {
                    sessionStore.clearSessionLocally()
                }

                downloadErrorMessage = apiError.localizedDescription
                isDownloadingFile = false
            } catch {
                downloadErrorMessage = error.localizedDescription
                isDownloadingFile = false
            }
        }
    }

    private func clearDownloadedFile() {
        guard let downloadedFile else { return }
        try? FileManager.default.removeItem(at: downloadedFile.fileURL)
        self.downloadedFile = nil
    }
}

private struct SharedDownloadItem: Identifiable {
    let id = UUID()
    let fileURL: URL
}

private struct SharedRenameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: SharedResourceEntry
    let onRename: @MainActor @Sendable (String) async throws -> Void

    @State private var draftName: String
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @FocusState private var isNameFieldFocused: Bool

    init(
        entry: SharedResourceEntry,
        onRename: @escaping @MainActor @Sendable (String) async throws -> Void
    ) {
        self.entry = entry
        self.onRename = onRename
        _draftName = State(initialValue: entry.name)
    }

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .lineLimit(1)

                    Text(strings.newName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.textSecondary)
                }

                TextField(strings.newNamePlaceholder, text: $draftName)
                    .focused($isNameFieldFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppPalette.cardStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppPalette.stroke, lineWidth: 1)
                    )
                    .submitLabel(.done)
                    .onSubmit {
                        submitRename()
                    }

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(AppBackground())
            .navigationTitle(strings.rename)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(strings.cancel) {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSubmitting ? strings.renaming : strings.rename) {
                        submitRename()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.async {
                isNameFieldFocused = true
            }
        }
    }

    @MainActor
    private func submitRename() {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !isSubmitting else { return }

        guard !trimmedName.isEmpty else {
            errorMessage = settingsStore.strings.renameNameEmpty
            return
        }

        guard trimmedName != entry.name else {
            dismiss()
            return
        }

        errorMessage = nil
        isSubmitting = true

        Task { @MainActor in
            do {
                try await onRename(trimmedName)
                isSubmitting = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
