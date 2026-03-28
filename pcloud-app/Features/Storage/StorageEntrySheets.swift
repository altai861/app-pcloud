import SwiftUI

struct StorageFilePlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: StorageEntry
    var onToggleStar: ((Bool) async throws -> StorageEntry)? = nil

    @State private var displayEntry: StorageEntry
    @State private var showingFileInfoSheet = false
    @State private var isUpdatingStar = false
    @State private var starErrorMessage: String?

    init(
        entry: StorageEntry,
        onToggleStar: ((Bool) async throws -> StorageEntry)? = nil
    ) {
        self.entry = entry
        self.onToggleStar = onToggleStar
        _displayEntry = State(initialValue: entry)
    }

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 20) {
                    fileHeader

                    Spacer(minLength: 0)

                    VStack(spacing: 18) {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(AppPalette.cardStrong)
                            .frame(height: 220)
                            .overlay {
                                VStack(spacing: 14) {
                                    Image(systemName: fileSystemImage)
                                        .font(.system(size: 48, weight: .semibold))
                                        .foregroundStyle(AppPalette.softBlueDeep)

                                    Text(strings.previewComingSoon)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(AppPalette.textPrimary)

                                    Text(strings.fileViewerTodo)
                                        .font(.subheadline)
                                        .foregroundStyle(AppPalette.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, 24)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(AppPalette.stroke, lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 10) {
                            storageMetadataLine(title: strings.pathLabel, value: displayEntry.path)

                            if let sizeBytes = displayEntry.sizeBytes {
                                storageMetadataLine(
                                    title: strings.used,
                                    value: ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
                                )
                            }

                            storageMetadataLine(title: strings.type, value: displayEntry.entryType.capitalized)
                        }
                        .appCard(padding: 18)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task(id: entry.id) {
                displayEntry = entry
            }
            .sheet(isPresented: $showingFileInfoSheet) {
                StorageFileInfoSheet(entry: displayEntry)
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
    }

    private var fileHeader: some View {
        HStack(spacing: 12) {
            Text(displayEntry.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            if onToggleStar != nil {
                headerActionButton(
                    systemImage: displayEntry.isStarred ? "star.fill" : "star",
                    foregroundColor: displayEntry.isStarred ? .yellow : AppPalette.textPrimary,
                    action: {
                        print("star button pressed")
                        toggleStar()
                    }
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

    private var fileSystemImage: String {
        let name = displayEntry.name.lowercased()

        if name.hasSuffix(".pdf") {
            return "doc.richtext.fill"
        }

        if ["png", "jpg", "jpeg", "gif", "webp", "heic"].contains(where: { name.hasSuffix($0) }) {
            return "photo.fill"
        }

        return "doc.text.fill"
    }

    private func toggleStar() {

        print("star tapped", displayEntry.path, displayEntry.isStarred)
        guard let onToggleStar else {
            return
        }

        let targetState = !displayEntry.isStarred
        print("target state:", targetState)

        Task {
            do {
                let updatedEntry = try await onToggleStar(targetState)
                print("server returned:", updatedEntry.isStarred)

                await MainActor.run {
                    displayEntry = updatedEntry
                    print("after assign:", displayEntry.isStarred)
                    isUpdatingStar = false
                }
            } catch {
                await MainActor.run {
                    print("toggle error:", error.localizedDescription)
                    starErrorMessage = error.localizedDescription
                    isUpdatingStar = false
                }
            }
        }
    }
}

private struct StorageFileInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: StorageEntry

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
                                value: entry.isStarred ? strings.starredStatus : strings.notStarred
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
