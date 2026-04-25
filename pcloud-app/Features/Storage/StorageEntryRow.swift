import SwiftUI

struct StorageEntryRow: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: StorageEntry
    var style: StorageEntryRowStyle = .standard
    var action: (() -> Void)? = nil
    var onRenameEntry: (@MainActor @Sendable (StorageEntry, String) async throws -> Void)? = nil
    var onMoveEntry: (@MainActor @Sendable (StorageEntry, Int64) async throws -> Void)? = nil
    var onMoveToTrash: (@MainActor @Sendable (StorageEntry) async throws -> Void)? = nil
    var onShareEntry: (@MainActor @Sendable (StorageEntry) -> Void)? = nil
    var allowsSharing: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            entryButton

            StorageEntryActionsMenu(
                entry: entry,
                onRenameEntry: onRenameEntry,
                onMoveEntry: onMoveEntry,
                onMoveToTrash: onMoveToTrash,
                onShareEntry: onShareEntry,
                allowsSharing: allowsSharing
            )
        }
        .padding(style.contentPadding)
        .background(
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .fill(style == .prominent ? AppPalette.card : AppPalette.cardStrong)
        )
        .overlay(
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .stroke(AppPalette.stroke, lineWidth: 1)
        )
        .shadow(color: style == .prominent ? AppPalette.shadow : .clear, radius: 12, x: 0, y: 8)
    }

    @ViewBuilder
    private var entryButton: some View {
        if let action {
            Button(action: action) {
                rowContent
            }
            .buttonStyle(.plain)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(entry.isFolder ? AppPalette.softBlue : AppPalette.cardStrong)
                .frame(width: style.iconBoxSize, height: style.iconBoxSize)
                .overlay {
                    Image(systemName: entry.isFolder ? "folder.fill" : "doc.text.fill")
                        .font(.system(size: style.iconSize, weight: .semibold))
                        .foregroundStyle(entry.isFolder ? AppPalette.softBlueDeep : AppPalette.textPrimary)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text(entry.name)
                        .font(style.titleFont)
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

                HStack(spacing: 8) {
                    Text(modifiedLabel)

                    if let sizeLabel {
                        Text("•")
                        Text(sizeLabel)
                    }
                }
                .font(.caption2)
                .foregroundStyle(AppPalette.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var sizeLabel: String? {
        guard let sizeBytes = entry.sizeBytes else {
            return nil
        }

        return ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    private var modifiedLabel: String {
        let strings = settingsStore.strings

        guard let modifiedAtUnixMs = entry.modifiedAtUnixMs else {
            return strings.updatedRecently
        }

        let date = Date(timeIntervalSince1970: TimeInterval(modifiedAtUnixMs) / 1000)
        return strings.modifiedOn(date, locale: settingsStore.locale)
    }
}

struct StorageEntryActionsMenu: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: StorageEntry
    var onRenameEntry: (@MainActor @Sendable (StorageEntry, String) async throws -> Void)? = nil
    var onMoveEntry: (@MainActor @Sendable (StorageEntry, Int64) async throws -> Void)? = nil
    var onMoveToTrash: (@MainActor @Sendable (StorageEntry) async throws -> Void)? = nil
    var onShareEntry: (@MainActor @Sendable (StorageEntry) -> Void)? = nil
    var allowsSharing: Bool = true

    @State private var showingRenameSheet = false
    @State private var isDownloadingFile = false
    @State private var isMovingToTrash = false
    @State private var downloadErrorMessage: String?
    @State private var moveToTrashErrorMessage: String?
    @State private var downloadedFile: DownloadedFileShareItem?
    @State private var showingMoveSheet = false
    @State private var showingShareSheet = false

    var body: some View {
        let strings = settingsStore.strings

        Menu {
            Button(strings.rename, systemImage: "pencil") {
                openRenameSheet()
            }

            if allowsSharing {
                Button(strings.shareAction, systemImage: "person.crop.circle.badge.plus") {
                    openShareSheet()
                }
            }

            if onMoveEntry != nil {
                Button(strings.move, systemImage: "folder") {
                    openMoveSheet()
                }
            }

            if !entry.isFolder {
                Button(strings.downloadFile, systemImage: "arrow.down.circle") {
                    downloadFile()
                }
                .disabled(isDownloadingFile)
            }

            if onMoveToTrash != nil {
                Divider()

                Button(strings.moveToTrash, systemImage: "trash", role: .destructive) {
                    moveToTrash()
                }
                .disabled(isMovingToTrash)
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
        .sheet(isPresented: $showingRenameSheet) {
            if let onRenameEntry {
                StorageRenameSheet(entry: entry, onRenameEntry: onRenameEntry)
            }
        }
        .sheet(isPresented: $showingMoveSheet) {
            if let onMoveEntry {
                StorageMoveSheet(entry: entry, onMove: onMoveEntry)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            StorageShareSheet(entry: entry)
        }
        .alert(
            strings.downloadFile,
            isPresented: Binding(
                get: { downloadErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        downloadErrorMessage = nil
                    }
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
        .alert(
            strings.moveToTrash,
            isPresented: Binding(
                get: { moveToTrashErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        moveToTrashErrorMessage = nil
                    }
                }
            ),
            actions: {
                Button(strings.cancel, role: .cancel) {
                    moveToTrashErrorMessage = nil
                }
            },
            message: {
                Text(moveToTrashErrorMessage ?? "")
            }
        )
    }

    private func placeholderAction() {}

    private func openShareSheet() {
        if let onShareEntry {
            onShareEntry(entry)
            return
        }

        showingShareSheet = true
    }

    private func openRenameSheet() {
        guard onRenameEntry != nil else {
            placeholderAction()
            return
        }

        showingRenameSheet = true
    }

    private func openMoveSheet() {
        guard onMoveEntry != nil else {
            placeholderAction()
            return
        }

        showingMoveSheet = true
    }

    @MainActor
    private func downloadFile() {
        guard !isDownloadingFile else {
            return
        }

        isDownloadingFile = true

        Task { @MainActor in
            do {
                let storageAPI = try sessionStore.makeStorageAPI()
                let file = try await storageAPI.downloadFile(entry: entry)
                clearDownloadedFile()
                downloadedFile = DownloadedFileShareItem(fileURL: file.fileURL)
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

    @MainActor
    private func moveToTrash() {
        guard !isMovingToTrash else {
            return
        }

        guard let onMoveToTrash else {
            placeholderAction()
            return
        }

        isMovingToTrash = true

        Task { @MainActor in
            do {
                try await onMoveToTrash(entry)
                isMovingToTrash = false
            } catch let apiError as APIClientError {
                if apiError.isUnauthorized {
                    sessionStore.clearSessionLocally()
                }

                moveToTrashErrorMessage = apiError.localizedDescription
                isMovingToTrash = false
            } catch {
                moveToTrashErrorMessage = error.localizedDescription
                isMovingToTrash = false
            }
        }
    }

    private func clearDownloadedFile() {
        guard let downloadedFile else {
            return
        }

        try? FileManager.default.removeItem(at: downloadedFile.fileURL)
        self.downloadedFile = nil
    }
}

private struct DownloadedFileShareItem: Identifiable {
    let id = UUID()
    let fileURL: URL
}

private struct StorageRenameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: StorageEntry
    let onRenameEntry: @MainActor @Sendable (StorageEntry, String) async throws -> Void

    @State private var draftName: String
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @FocusState private var isNameFieldFocused: Bool

    init(
        entry: StorageEntry,
        onRenameEntry: @escaping @MainActor @Sendable (StorageEntry, String) async throws -> Void
    ) {
        self.entry = entry
        self.onRenameEntry = onRenameEntry
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
        let copiedName = NSString(string: draftName) as String
        let trimmedName = copiedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let renameEntry = entry

        guard !isSubmitting else {
            return
        }

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
                try await onRenameEntry(renameEntry, trimmedName)
                isSubmitting = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

enum StorageEntryRowStyle {
    case standard
    case prominent

    var iconBoxSize: CGFloat {
        switch self {
        case .standard: 46
        case .prominent: 52
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .standard: 20
        case .prominent: 22
        }
    }

    var titleFont: Font {
        switch self {
        case .standard:
            .body.weight(.semibold)
        case .prominent:
            .headline.weight(.semibold)
        }
    }

    var contentPadding: CGFloat {
        switch self {
        case .standard: 14
        case .prominent: 16
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .standard: 20
        case .prominent: 22
        }
    }
}
