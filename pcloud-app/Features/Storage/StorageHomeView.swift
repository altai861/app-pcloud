import SwiftUI

struct StorageHomeView: View {
    @ObservedObject var viewModel: StorageHomeViewModel
    let onMenuTap: () -> Void

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @State private var showingProfileSheet = false
    @State private var showingFolderInfoSheet = false
    @State private var selectedFileEntry: StorageEntry?
    @State private var searchText = ""
    @State private var layoutMode: StorageLayoutMode = .list
    @State private var sortMode: StorageSortMode = .modified
    @State private var sortDirection: StorageSortDirection = .descending

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                VStack(alignment: .leading, spacing: 14) {
                    stickyHeader

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            contentSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 148)
                    }
                    .refreshable {
                        await viewModel.refresh(using: sessionStore)
                    }
                }

                if let uploadProgress = viewModel.uploadProgress {
                    uploadProgressCard(uploadProgress)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 108)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: viewModel.uploadProgress)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onMenuTap) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(AppPalette.textPrimary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    toolbarTitle
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
            .sheet(isPresented: $showingFolderInfoSheet) {
                StorageFolderInfoSheet(
                    folderName: currentFolderName,
                    currentPath: viewModel.currentPath,
                    currentPrivilege: viewModel.response?.currentPrivilege ?? strings.owner,
                    parentPath: viewModel.parentPath,
                    currentFolderId: viewModel.response?.currentFolderId,
                    entriesCount: filteredEntries.count,
                    usedBytes: viewModel.response?.userStorageUsedBytes ?? 0
                )
            }
            .sheet(item: $selectedFileEntry) { entry in
                let entryPath = entry.path
                StorageFilePlaceholderSheet(
                    entry: entry,
                    onToggleStar: { starred in
                        let updatedEntry = try await viewModel.setEntryStarred(
                            path: entryPath,
                            entryType: "file",
                            starred: starred,
                            using: sessionStore
                        )
                        return updatedEntry.isStarred
                    }
                )
            }
        }
    }

    private var stickyHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            topSearchBar
            compactUtilityBar
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var topSearchBar: some View {
        let strings = settingsStore.strings

        return HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppPalette.textSecondary)

            TextField(strings.storageSearchPlaceholder, text: $searchText)
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

    private var compactUtilityBar: some View {
        let strings = settingsStore.strings

        return HStack(spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                if !viewModel.isAtRoot {
                    Button {
                        Task {
                            await viewModel.goToParent(using: sessionStore)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppPalette.textPrimary)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(AppPalette.cardStrong)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Image(systemName: viewModel.isAtRoot ? "internaldrive.fill" : "folder.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.softBlueDeep)

                Text(compactPathLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppPalette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppPalette.stroke, lineWidth: 1)
            )

            HStack(spacing: 8) {
                ViewThatFits(in: .horizontal) {
                    Text(viewModel.response?.currentPrivilege.capitalized ?? strings.owner)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppPalette.softBlue)
                        )

                    Image(systemName: "person.crop.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(AppPalette.softBlue)
                        )
                }

                Menu {
                    Picker(strings.sort, selection: $sortMode) {
                        ForEach(StorageSortMode.allCases, id: \.self) { mode in
                            Text(mode.title(strings: strings)).tag(mode)
                        }
                    }

                    Divider()

                    Picker(sortDirection.title(for: sortMode, strings: strings), selection: $sortDirection) {
                        ForEach(StorageSortDirection.allCases, id: \.self) { direction in
                            Text(direction.title(for: sortMode, strings: strings)).tag(direction)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .frame(width: 30, height: 30)
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

                Picker(strings.layout, selection: $layoutMode) {
                    ForEach(StorageLayoutMode.allCases, id: \.self) { mode in
                        Image(systemName: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 74)

                Button {
                    showingFolderInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .frame(width: 30, height: 30)
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
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var toolbarTitle: some View {
        HStack(spacing: 8) {
            Text(viewModel.isAtRoot ? settingsStore.strings.storage : currentFolderName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)

            if !viewModel.isAtRoot {
                Button {
                    Task {
                        try? await viewModel.setCurrentFolderStarred(
                            !viewModel.currentFolderIsStarred,
                            using: sessionStore
                        )
                    }
                } label: {
                    Image(systemName: viewModel.currentFolderIsStarred ? "star.fill" : "star")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(viewModel.currentFolderIsStarred ? .yellow : AppPalette.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 180)
    }

    @ViewBuilder
    private var contentSection: some View {
        let strings = settingsStore.strings

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
        } else if filteredEntries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(searchText.isEmpty ? strings.noEntriesTitle : strings.noMatchesTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(searchText.isEmpty ? strings.noEntriesSubtitle : strings.noMatchesSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        } else {
            if layoutMode == .list {
                VStack(spacing: 12) {
                    ForEach(filteredEntries) { entry in
                        StorageEntryRow(
                            entry: entry,
                            action: { openEntry(entry) },
                            onRenameEntry: renameEntryAction,
                            onMoveEntry: isOwner ? moveEntryAction : nil,
                            onMoveToTrash: isOwner ? moveEntryToTrashAction : nil,
                            allowsSharing: isOwner
                        )
                    }
                }
            } else {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(filteredEntries) { entry in
                        storageGridCard(entry)
                    }
                }
            }
        }
    }

    private var isOwner: Bool {
        (viewModel.response?.currentPrivilege ?? "owner").lowercased() == "owner"
    }

    private func storageGridCard(_ entry: StorageEntry) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                openEntry(entry)
            } label: {
                storageGridCardContent(entry)
            }
            .buttonStyle(.plain)

            StorageEntryActionsMenu(
                entry: entry,
                onRenameEntry: renameEntryAction,
                onMoveEntry: isOwner ? moveEntryAction : nil,
                onMoveToTrash: isOwner ? moveEntryToTrashAction : nil,
                allowsSharing: isOwner
            )
                .padding(.top, 12)
                .padding(.trailing, 12)
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

    private func storageGridCardContent(_ entry: StorageEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(entry.isFolder ? AppPalette.softBlue : AppPalette.cardStrong)
                .frame(height: 82)
                .overlay {
                    Image(systemName: entry.isFolder ? "folder.fill" : "doc.text.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(entry.isFolder ? AppPalette.softBlueDeep : AppPalette.textPrimary)
                }

            Text(entry.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .lineLimit(1)

            Text(entry.ownerUsername)
                .font(.caption)
                .foregroundStyle(AppPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .padding(.top, 30)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppPalette.stroke, lineWidth: 1)
        )
        .shadow(color: AppPalette.shadow, radius: 10, x: 0, y: 8)
    }

    private func uploadProgressCard(_ progress: StorageUploadProgress) -> some View {
        let strings = settingsStore.strings
        let isCompleted = progress.state == .completed

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isCompleted ? AppPalette.accent : AppPalette.softBlueDeep)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isCompleted ? strings.uploadsCompleteTitle : strings.uploadingItemsTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(
                        isCompleted
                            ? strings.uploadedItemsSummary(progress.totalCount)
                            : strings.uploadProgressSummary(
                                current: progress.currentItemNumber,
                                total: progress.totalCount
                            )
                    )
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)
                }

                Spacer()

                Text("\(Int(progress.displayProgress * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.textSecondary)
            }

            if let currentFileName = progress.currentFileName, !currentFileName.isEmpty, !isCompleted {
                Text(currentFileName)
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            ProgressView(value: progress.displayProgress)
                .tint(isCompleted ? AppPalette.accent : AppPalette.softBlueDeep)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: 320, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppPalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppPalette.stroke, lineWidth: 1)
        )
        .shadow(color: AppPalette.shadow.opacity(1.1), radius: 16, x: 0, y: 10)
    }

    private var filteredEntries: [StorageEntry] {
        let baseEntries = viewModel.entries.filter { entry in
            guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return true
            }

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return entry.name.lowercased().contains(query)
                || entry.path.lowercased().contains(query)
                || entry.ownerUsername.lowercased().contains(query)
        }

        return sortMode.sortedEntries(baseEntries, direction: sortDirection)
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var compactPathLabel: String {
        if viewModel.isAtRoot {
            return viewModel.currentPath
        }

        return currentFolderName
    }

    private var currentFolderName: String {
        if viewModel.isAtRoot {
            return settingsStore.strings.rootFolder
        }

        return URL(fileURLWithPath: viewModel.currentPath).lastPathComponent
    }

    private func openFolder(_ entry: StorageEntry) {
        Task {
            await viewModel.openFolder(entry, using: sessionStore)
        }
    }

    private func openEntry(_ entry: StorageEntry) {
        if entry.isFolder {
            openFolder(entry)
        } else {
            selectedFileEntry = entry
        }
    }
}

private struct StorageFolderInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let folderName: String
    let currentPath: String
    let currentPrivilege: String
    let parentPath: String?
    let currentFolderId: Int64?
    let entriesCount: Int
    let usedBytes: Int64

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(folderName)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppPalette.textPrimary)

                            Text(currentPath)
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)
                        }
                        .appCard(padding: 18)

                        VStack(spacing: 12) {
                            metadataRow(title: strings.name, value: folderName)
                            metadataRow(title: strings.pathLabel, value: currentPath)
                            metadataRow(title: strings.permission, value: currentPrivilege.capitalized)
                            metadataRow(title: strings.parentFolder, value: parentPath ?? strings.rootFolder)
                            metadataRow(
                                title: strings.folderId,
                                value: currentFolderId.map(String.init) ?? strings.rootFolder
                            )
                            metadataRow(title: strings.entries, value: "\(entriesCount)")
                            metadataRow(
                                title: strings.used,
                                value: ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .file)
                            )
                        }
                        .appCard(padding: 18)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(strings.folderInfo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func metadataRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.textSecondary)
                .frame(width: 108, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppPalette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
    }
}

private enum StorageLayoutMode: CaseIterable {
    case list
    case grid

    var systemImage: String {
        switch self {
        case .list: "list.bullet"
        case .grid: "square.grid.2x2"
        }
    }
}

private enum StorageSortMode: CaseIterable {
    case modified
    case name
    case type

    func title(strings: AppStrings) -> String {
        switch self {
        case .modified: strings.modifiedLong
        case .name: strings.name
        case .type: strings.type
        }
    }

    func shortTitle(strings: AppStrings) -> String {
        switch self {
        case .modified: strings.modifiedShort
        case .name: strings.name
        case .type: strings.type
        }
    }

    func sortedEntries(_ entries: [StorageEntry], direction: StorageSortDirection) -> [StorageEntry] {
        switch self {
        case .modified:
            return entries.sorted {
                let lhs = ($0.modifiedAtUnixMs ?? 0, $0.name.lowercased())
                let rhs = ($1.modifiedAtUnixMs ?? 0, $1.name.lowercased())
                return direction == .ascending ? lhs < rhs : lhs > rhs
            }
        case .name:
            return entries.sorted {
                let comparison = $0.name.localizedCaseInsensitiveCompare($1.name)
                return direction == .ascending ? comparison == .orderedAscending : comparison == .orderedDescending
            }
        case .type:
            return entries.sorted {
                if $0.isFolder != $1.isFolder {
                    return direction == .ascending ? $0.isFolder && !$1.isFolder : !$0.isFolder && $1.isFolder
                }

                let nameComparison = $0.name.localizedCaseInsensitiveCompare($1.name)
                if nameComparison != .orderedSame {
                    return nameComparison == .orderedAscending
                }

                if $0.entryType == $1.entryType {
                    return $0.rawID < $1.rawID
                }

                let typeComparison = $0.entryType.localizedCaseInsensitiveCompare($1.entryType)
                return typeComparison == .orderedAscending
            }
        }
    }
}

private enum StorageSortDirection: CaseIterable {
    case ascending
    case descending

    func title(for mode: StorageSortMode, strings: AppStrings) -> String {
        switch mode {
        case .modified:
            switch self {
            case .ascending:
                return strings.oldestFirst
            case .descending:
                return strings.newestFirst
            }
        case .name:
            switch self {
            case .ascending:
                return "\(strings.ascending) (A-Z)"
            case .descending:
                return "\(strings.descending) (Z-A)"
            }
        case .type:
            switch self {
            case .ascending:
                return strings.foldersFirst
            case .descending:
                return strings.filesFirst
            }
        }
    }
}
