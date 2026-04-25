import SwiftUI

struct StorageFilePlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: StorageEntry
    var onToggleStar: (@MainActor (Bool) async throws -> Bool)? = nil

    @State private var isStarred: Bool
    @State private var showingFileInfoSheet = false
    @State private var isUpdatingStar = false
    @State private var starErrorMessage: String?
    @State private var isLoadingPreview = true
    @State private var previewErrorMessage: String?
    @State private var previewMode: StorageFilePreviewMode = .none
    @State private var previewFileURL: URL?
    @State private var previewMetadata: StorageFileMetadata?

    init(
        entry: StorageEntry,
        onToggleStar: (@MainActor (Bool) async throws -> Bool)? = nil
    ) {
        self.entry = entry
        self.onToggleStar = onToggleStar
        _isStarred = State(initialValue: entry.isStarred)
    }

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 20) {
                    fileHeader

                    previewCard(strings: strings)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingFileInfoSheet) {
                StorageFileInfoSheet(entry: entry, isStarred: isStarred)
            }
            .alert(
                strings.starred,
                isPresented: Binding(
                    get: { starErrorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            starErrorMessage = nil
                        }
                    }
                ),
                actions: {
                    Button(strings.cancel, role: .cancel) {
                        starErrorMessage = nil
                    }
                },
                message: {
                    Text(starErrorMessage ?? "")
                }
            )
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task(id: entry.id) {
            await loadPreview()
        }
        .onChange(of: entry.isStarred) { _, newValue in
            isStarred = newValue
        }
        .onDisappear {
            clearPreviewFile()
        }
    }

    private var fileHeader: some View {
        HStack(spacing: 12) {
            Text(entry.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            if onToggleStar != nil {
                headerActionButton(
                    systemImage: isStarred ? "star.fill" : "star",
                    foregroundColor: isStarred ? .yellow : AppPalette.textPrimary,
                    action: toggleStar
                )
                .disabled(isUpdatingStar)
            }

            headerActionButton(
                systemImage: "info.circle",
                foregroundColor: AppPalette.textPrimary
            ) {
                showingFileInfoSheet = true
            }

            headerActionButton(
                systemImage: "xmark",
                foregroundColor: AppPalette.textPrimary
            ) {
                dismiss()
            }
        }
    }

    private func headerActionButton(
        systemImage: String,
        foregroundColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(foregroundColor)
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
        .buttonStyle(.plain)
    }

    private func previewCard(strings: AppStrings) -> some View {
        VStack(spacing: 14) {
            if isLoadingPreview {
                ProgressView(strings.loadingFilePreview)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let previewErrorMessage {
                previewMessage(
                    icon: "exclamationmark.triangle.fill",
                    title: previewErrorMessage,
                    color: .red
                )
            } else if previewMode == .unsupported {
                previewMessage(
                    icon: fileSystemImage,
                    title: previewStatusMessage(strings: strings),
                    color: AppPalette.softBlueDeep
                )
            } else if let previewFileURL {
                QuickLookPreview(fileURL: previewFileURL)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                previewMessage(
                    icon: fileSystemImage,
                    title: strings.previewUnsupported,
                    color: AppPalette.softBlueDeep
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppPalette.cardStrong)
        )
    }

    private func previewMessage(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(color)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    private var fileSystemImage: String {
        let name = entry.name.lowercased()

        if name.hasSuffix(".pdf") {
            return "doc.richtext.fill"
        }

        if ["png", "jpg", "jpeg", "gif", "webp", "heic"].contains(where: { name.hasSuffix($0) }) {
            return "photo.fill"
        }

        if ["mp3", "wav", "ogg", "flac", "m4a", "aac"].contains(where: { name.hasSuffix($0) }) {
            return "waveform"
        }

        if ["mp4", "webm", "mov", "m4v", "ogv"].contains(where: { name.hasSuffix($0) }) {
            return "film.fill"
        }

        return "doc.text.fill"
    }

    private func previewStatusMessage(strings: AppStrings) -> String {
        guard let metadata = previewMetadata else {
            return strings.previewUnsupported
        }

        let resolvedMode = StorageFilePreviewMode.resolve(for: metadata)
        if resolvedMode == .text && metadata.sizeBytes > StorageFilePreviewMode.maximumTextPreviewBytes {
            return strings.previewTextTooLarge
        }

        return strings.previewUnsupported
    }

    @MainActor
    private func toggleStar() {
        guard !isUpdatingStar else {
            return
        }

        guard let onToggleStar else {
            return
        }

        let targetState = !isStarred
        isUpdatingStar = true

        Task { @MainActor in
            do {
                let updatedIsStarred = try await onToggleStar(targetState)
                isStarred = updatedIsStarred
                isUpdatingStar = false
            } catch {
                starErrorMessage = error.localizedDescription
                isUpdatingStar = false
            }
        }
    }

    @MainActor
    private func loadPreview() async {
        isLoadingPreview = true
        previewErrorMessage = nil
        previewMetadata = nil
        previewMode = .none
        clearPreviewFile()

        do {
            let storageAPI = try sessionStore.makeStorageAPI()
            let metadata = try await storageAPI.fileMetadata(fileID: entry.rawID)
            previewMetadata = metadata

            let resolvedMode = StorageFilePreviewMode.resolve(for: metadata)

            if resolvedMode == .text && metadata.sizeBytes > StorageFilePreviewMode.maximumTextPreviewBytes {
                previewMode = .unsupported
                isLoadingPreview = false
                return
            }

            guard resolvedMode != .unsupported else {
                previewMode = .unsupported
                isLoadingPreview = false
                return
            }

            previewMode = resolvedMode

            let downloadedFile = try await storageAPI.downloadFile(entry: entry)
            previewFileURL = downloadedFile.fileURL
            isLoadingPreview = false
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            previewErrorMessage = apiError.localizedDescription
            isLoadingPreview = false
        } catch {
            previewErrorMessage = error.localizedDescription
            isLoadingPreview = false
        }
    }

    private func clearPreviewFile() {
        guard let previewFileURL else {
            return
        }

        try? FileManager.default.removeItem(at: previewFileURL)
        self.previewFileURL = nil
    }
}

private struct StorageFileInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: StorageEntry
    let isStarred: Bool

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppPalette.textPrimary)

                            Text(entry.path)
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)
                        }
                        .appCard(padding: 18)

                        VStack(spacing: 12) {
                            storageMetadataLine(title: strings.name, value: entry.name)
                            storageMetadataLine(title: strings.pathLabel, value: entry.path)
                            storageMetadataLine(title: strings.type, value: entry.entryType.capitalized)
                            storageMetadataLine(title: strings.owner, value: entry.ownerUsername)
                            storageMetadataLine(title: strings.createdBy, value: entry.createdByUsername)
                            storageMetadataLine(
                                title: strings.starredStatus,
                                value: isStarred ? strings.starredStatus : strings.notStarred
                            )

                            if let sizeBytes = entry.sizeBytes {
                                storageMetadataLine(
                                    title: strings.used,
                                    value: ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
                                )
                            }

                            if let modifiedAtUnixMs = entry.modifiedAtUnixMs {
                                let modifiedDate = Date(timeIntervalSince1970: TimeInterval(modifiedAtUnixMs) / 1000)
                                storageMetadataLine(
                                    title: strings.modifiedLong,
                                    value: strings.modifiedOn(modifiedDate, locale: settingsStore.locale)
                                )
                            }

                            storageMetadataLine(title: strings.fileId, value: String(entry.rawID))
                        }
                        .appCard(padding: 18)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(strings.fileInfo)
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
}

@ViewBuilder
private func storageMetadataLine(title: String, value: String) -> some View {
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

private enum StorageFilePreviewMode: Equatable {
    case none
    case image
    case pdf
    case text
    case audio
    case video
    case unsupported

    static let maximumTextPreviewBytes: Int64 = 5 * 1024 * 1024

    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "webp", "bmp", "svg", "heic", "heif", "tif", "tiff", "ico", "avif"
    ]
    private static let textExtensions: Set<String> = [
        "txt", "md", "markdown", "json", "xml", "yaml", "yml", "toml", "csv", "tsv", "log", "ini", "conf",
        "rs", "ts", "tsx", "js", "jsx", "mjs", "cjs", "html", "css", "scss", "less", "go", "java", "py",
        "c", "cpp", "h", "hpp", "php", "sh", "sql"
    ]
    private static let audioExtensions: Set<String> = [
        "mp3", "wav", "ogg", "flac", "m4a", "aac"
    ]
    private static let videoExtensions: Set<String> = [
        "mp4", "webm", "mov", "m4v", "ogv"
    ]
    private static let textMimeTypes: Set<String> = [
        "application/json",
        "application/xml",
        "application/x-yaml",
        "application/yaml",
        "application/toml",
        "application/javascript",
        "application/x-javascript",
        "application/typescript",
        "application/sql",
        "image/svg+xml"
    ]

    static func resolve(for metadata: StorageFileMetadata?) -> StorageFilePreviewMode {
        guard let metadata else {
            return .unsupported
        }

        let mimeType = (metadata.mimeType ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let fileExtension = (metadata.extensionValue ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
            .lowercased()

        if mimeType == "application/pdf" || fileExtension == "pdf" {
            return .pdf
        }

        if mimeType.hasPrefix("image/") || imageExtensions.contains(fileExtension) {
            return .image
        }

        if mimeType.hasPrefix("text/")
            || textMimeTypes.contains(mimeType)
            || textExtensions.contains(fileExtension) {
            return .text
        }

        if mimeType.hasPrefix("audio/") || audioExtensions.contains(fileExtension) {
            return .audio
        }

        if mimeType.hasPrefix("video/") || videoExtensions.contains(fileExtension) {
            return .video
        }

        return .unsupported
    }
}
