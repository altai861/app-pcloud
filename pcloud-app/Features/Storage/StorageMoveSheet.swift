import SwiftUI

struct StorageMoveSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: StorageEntry
    let onMove: @MainActor @Sendable (StorageEntry, Int64) async throws -> Void

    @State private var browserResponse: StorageListResponse?
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        titleCard(strings: strings)
                        locationCard(strings: strings)
                        browserList(strings: strings)

                        if let warning = destinationWarning {
                            Text(warning)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .appCard()
                        } else if let errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .appCard()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footer(strings: strings)
            }
            .task {
                await loadBrowser(path: "/")
            }
        }
    }

    private func titleCard(strings: AppStrings) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(strings.moveTitle): \(entry.name)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .lineLimit(2)

            Text(entry.path)
                .font(.caption)
                .foregroundStyle(AppPalette.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .appCard(padding: 18)
    }

    private func locationCard(strings: AppStrings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings.moveCurrentLocation)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(locationSegments) { segment in
                        Button {
                            Task {
                                await loadBrowser(path: segment.path)
                            }
                        } label: {
                            Text(segment.label)
                                .font(.subheadline.weight(segment.isCurrent ? .semibold : .regular))
                                .foregroundStyle(segment.isCurrent ? AppPalette.textPrimary : AppPalette.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(segment.isCurrent ? AppPalette.cardStrong : AppPalette.card)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(AppPalette.stroke, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading || segment.isCurrent)
                    }
                }
            }
        }
        .appCard(padding: 18)
    }

    @ViewBuilder
    private func browserList(strings: AppStrings) -> some View {
        if isLoading && browserResponse == nil {
            ProgressView(strings.moveLoadingFolders)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .appCard()
        } else {
            let folders = browserFolders

            VStack(alignment: .leading, spacing: 10) {
                if isLoading {
                    ProgressView(strings.moveLoadingFolders)
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                }

                if folders.isEmpty {
                    Text(strings.moveNoFolders)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.textSecondary)
                } else {
                    ForEach(folders) { folder in
                        Button {
                            Task {
                                await loadBrowser(path: folder.path)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(AppPalette.softBlueDeep)

                                Text(folder.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppPalette.textPrimary)
                                    .lineLimit(1)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppPalette.textSecondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AppPalette.cardStrong)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppPalette.stroke, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                    }
                }
            }
            .appCard(padding: 18)
        }
    }

    private func footer(strings: AppStrings) -> some View {
        HStack(spacing: 12) {
            Button(strings.cancel) {
                dismiss()
            }
            .buttonStyle(.bordered)
            .tint(AppPalette.textSecondary)
            .disabled(isSubmitting)

            Button(isSubmitting ? strings.moving : strings.move) {
                submitMove()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppPalette.accentDeep)
            .disabled(!canSubmit)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(.ultraThinMaterial)
    }

    private var browserFolders: [StorageEntry] {
        let folders = browserResponse?.entries.filter(\.isFolder) ?? []

        return folders.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var currentFolderID: Int64? {
        browserResponse?.currentFolderId
    }

    private var currentPath: String {
        browserResponse?.currentPath ?? "/"
    }

    private var destinationWarning: String? {
        guard let currentFolderID else {
            return nil
        }

        if entry.isFolder {
            if currentFolderID == entry.rawID {
                return settingsStore.strings.moveWarnSelf
            }

            if currentPath == entry.path || currentPath.hasPrefix(entry.path + "/") {
                return settingsStore.strings.moveWarnChild
            }
        }

        return nil
    }

    private var canSubmit: Bool {
        !isSubmitting
            && !isLoading
            && currentFolderID != nil
            && destinationWarning == nil
    }

    private var locationSegments: [MoveLocationSegment] {
        let strings = settingsStore.strings
        let path = currentPath

        if path == "/" {
            return [
                MoveLocationSegment(
                    id: "/",
                    label: strings.moveRoot,
                    path: "/",
                    isCurrent: true
                )
            ]
        }

        let components = path.split(separator: "/").map(String.init)
        var segments: [MoveLocationSegment] = [
            MoveLocationSegment(
                id: "/",
                label: strings.moveRoot,
                path: "/",
                isCurrent: false
            )
        ]

        var traversedPath = ""
        for (index, component) in components.enumerated() {
            traversedPath += "/\(component)"
            segments.append(
                MoveLocationSegment(
                    id: traversedPath,
                    label: component,
                    path: traversedPath,
                    isCurrent: index == components.count - 1
                )
            )
        }

        return segments
    }

    @MainActor
    private func loadBrowser(path: String) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            browserResponse = try await sessionStore.makeStorageAPI().list(path: path)
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            errorMessage = apiError.localizedDescription.isEmpty
                ? settingsStore.strings.moveErrorLoadFolders
                : apiError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func submitMove() {
        guard let currentFolderID else {
            errorMessage = settingsStore.strings.moveErrorSelectDestination
            return
        }

        if let warning = destinationWarning {
            errorMessage = warning
            return
        }

        isSubmitting = true
        errorMessage = nil

        Task { @MainActor in
            do {
                try await onMove(entry, currentFolderID)
                isSubmitting = false
                dismiss()
            } catch let apiError as APIClientError {
                if apiError.isUnauthorized {
                    sessionStore.clearSessionLocally()
                }

                errorMessage = apiError.localizedDescription.isEmpty
                    ? settingsStore.strings.moveErrorSubmit
                    : apiError.localizedDescription
                isSubmitting = false
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

private struct MoveLocationSegment: Identifiable {
    let id: String
    let label: String
    let path: String
    let isCurrent: Bool
}
