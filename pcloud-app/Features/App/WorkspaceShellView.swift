import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceShellView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @StateObject private var storageViewModel = StorageHomeViewModel()
    @StateObject private var starredViewModel = StarredViewModel()
    @StateObject private var adminUsersViewModel = AdminUsersViewModel()
    @State private var selectedTab: WorkspaceTab = .home
    @State private var isSidebarPresented = false
    @State private var showingFileImporter = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var storageActionErrorMessage: String?

    var body: some View {
        ZStack(alignment: .leading) {
            currentContentView
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 12) {
                        if selectedTab == .storage {
                            HStack {
                                Spacer()
                                storageQuickActionButton
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 64)
                            .padding(.top, 6)
                        }

                        bottomBar
                    }
                }
            .task {
                await storageViewModel.loadInitial(using: sessionStore)
            }

            if isSidebarPresented {
                Color.black.opacity(0.22)
                    .ignoresSafeArea()
                    .onTapGesture {
                        hideSidebar()
                    }
                    .transition(.opacity)

                sidebarView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isSidebarPresented)
        .onChange(of: selectedTab) { _, newTab in
            guard newTab == .starred else {
                return
            }

            Task {
                await starredViewModel.refresh(using: sessionStore)
            }
        }
        .onChange(of: selectedPhotoItems) { _, items in
            guard !items.isEmpty else {
                return
            }

            Task {
                await handlePhotoSelection(items)
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: nil,
            matching: .images,
            preferredItemEncoding: .automatic
        )
        .alert(settingsStore.strings.createFolder, isPresented: $showingCreateFolderAlert) {
            TextField(settingsStore.strings.folderNamePlaceholder, text: $newFolderName)
            Button(settingsStore.strings.cancel, role: .cancel) {
                newFolderName = ""
            }
            Button(settingsStore.strings.createFolder) {
                submitCreateFolder()
            }
        } message: {
            Text(settingsStore.strings.folderName)
        }
        .alert(
            settingsStore.strings.storageLoadErrorTitle,
            isPresented: Binding(
                get: { storageActionErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        storageActionErrorMessage = nil
                    }
                }
            ),
            actions: {
                Button(settingsStore.strings.cancel, role: .cancel) {
                    storageActionErrorMessage = nil
                }
            },
            message: {
                Text(storageActionErrorMessage ?? "")
            }
        )
    }

    @ViewBuilder
    private var currentContentView: some View {
        let strings = settingsStore.strings

        switch selectedTab {
        case .home:
            HomeDashboardView(
                selectedTab: $selectedTab,
                storageViewModel: storageViewModel,
                onMenuTap: toggleSidebar
            )
        case .starred:
            StarredView(
                viewModel: starredViewModel,
                onMenuTap: toggleSidebar,
                onOpenFolder: openStarredFolder
            )
        case .storage:
            StorageHomeView(
                viewModel: storageViewModel,
                onMenuTap: toggleSidebar
            )
        case .shared:
            WorkspacePlaceholderView(
                title: strings.shared,
                subtitle: "",
                systemImage: "person.2.fill",
                onMenuTap: toggleSidebar
            )
        case .trash:
            WorkspacePlaceholderView(
                title: strings.trash,
                subtitle: "",
                systemImage: "trash.fill",
                onMenuTap: toggleSidebar
            )
        case .admin:
            AdminUsersView(
                viewModel: adminUsersViewModel,
                onMenuTap: toggleSidebar
            )
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            ForEach(WorkspaceTab.primaryTabs, id: \.self) { tab in
                bottomBarItem(for: tab)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 0)
        .background(
            Color.clear
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Divider()
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var storageQuickActionButton: some View {
        let strings = settingsStore.strings

        return Menu {
            Button(strings.uploadFile, systemImage: "arrow.up.doc") {
                showingFileImporter = true
            }

            Button(strings.uploadPhoto, systemImage: "photo.on.rectangle") {
                showingPhotoPicker = true
            }

            Button(strings.newFolder, systemImage: "folder.badge.plus") {
                newFolderName = ""
                showingCreateFolderAlert = true
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(AppPalette.accent)
                )
                .overlay(
                    Circle()
                        .stroke(AppPalette.stroke.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: AppPalette.shadow.opacity(0.75), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var sidebarView: some View {
        let strings = settingsStore.strings

        return VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(strings.appName)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)

                    if let user = sessionStore.currentUser {
                        Text(user.fullName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.textPrimary)
                        Text("@\(user.username)")
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }

                Spacer()

                Button {
                    hideSidebar()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(AppPalette.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(AppPalette.cardStrong)
                        )
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(primarySidebarTabs, id: \.self) { tab in
                    sidebarItem(for: tab)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                sidebarItem(for: .trash)
                storageUsagePanel
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .frame(width: 304)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppPalette.cardStrong)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(AppPalette.stroke, lineWidth: 1)
        )
        .shadow(color: AppPalette.shadow.opacity(1.2), radius: 26, x: 14, y: 0)
        .padding(.leading, 12)
        .padding(.vertical, 12)
    }

    private var storageUsagePanel: some View {
        let strings = settingsStore.strings
        let quota = storageViewModel.response?.userStorageQuotaBytes ?? sessionStore.currentUser?.storageQuotaBytes ?? 0
        let used = storageViewModel.response?.userStorageUsedBytes ?? sessionStore.currentUser?.storageUsedBytes ?? 0
        let progress = quota > 0 ? min(max(Double(used) / Double(quota), 0), 1) : 0

        return VStack(alignment: .leading, spacing: 14) {
            Text(strings.storageUsage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)

            Gauge(value: progress) {
                EmptyView()
            } currentValueLabel: {
                Text("\(Int(progress * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppPalette.textSecondary)
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(Gradient(colors: [AppPalette.accent, AppPalette.softBlueDeep]))

            HStack(spacing: 12) {
                usagePill(
                    title: strings.used,
                    value: ByteCountFormatter.string(fromByteCount: used, countStyle: .file)
                )
                usagePill(
                    title: strings.limit,
                    value: quota > 0
                        ? ByteCountFormatter.string(fromByteCount: quota, countStyle: .file)
                        : strings.unlimited
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.card)
        )
    }

    private func usagePill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppPalette.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sidebarItem(for tab: WorkspaceTab) -> some View {
        let strings = settingsStore.strings

        return Button {
            selectedTab = tab
            hideSidebar()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: tab.systemImage)
                    .font(.headline)
                    .frame(width: 22)

                Text(tab.title(strings: strings))
                    .font(.headline.weight(selectedTab == tab ? .bold : .semibold))

                Spacer()
            }
            .foregroundStyle(selectedTab == tab ? AppPalette.textPrimary : AppPalette.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selectedTab == tab ? AppPalette.softBlue : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func bottomBarItem(for tab: WorkspaceTab) -> some View {
        let strings = settingsStore.strings
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 17, weight: .semibold))

                Text(tab.title(strings: strings))
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? AppPalette.textPrimary : AppPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? AppPalette.softBlue : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggleSidebar() {
        withAnimation {
            isSidebarPresented.toggle()
        }
    }

    private var sidebarTabs: [WorkspaceTab] {
        if sessionStore.currentUser?.isAdmin == true {
            return WorkspaceTab.allCases
        }

        return WorkspaceTab.allCases.filter { $0 != .admin }
    }

    private var primarySidebarTabs: [WorkspaceTab] {
        sidebarTabs.filter { $0 != .trash }
    }

    private func hideSidebar() {
        withAnimation {
            isSidebarPresented = false
        }
    }

    private func openStarredFolder(_ entry: StorageEntry) {
        selectedTab = .storage

        Task {
            await storageViewModel.openFolder(
                path: entry.path,
                starredHint: entry.isStarred,
                using: sessionStore
            )
        }
    }

    private func submitCreateFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            storageActionErrorMessage = settingsStore.strings.folderNamePlaceholder
            return
        }

        newFolderName = ""

        Task {
            do {
                try await storageViewModel.createFolder(name: name, using: sessionStore)
            } catch {
                storageActionErrorMessage = error.localizedDescription
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard !urls.isEmpty else {
                return
            }

            Task {
                do {
                    let selectedFiles = try urls.map(loadSelectedFile)
                    try await storageViewModel.uploadFiles(selectedFiles, using: sessionStore)
                } catch {
                    storageActionErrorMessage = error.localizedDescription
                }
            }
        case let .failure(error):
            storageActionErrorMessage = error.localizedDescription
        }
    }

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else {
            return
        }

        defer {
            self.selectedPhotoItems = []
        }

        do {
            var selectedFiles: [StorageUploadItem] = []
            selectedFiles.reserveCapacity(items.count)

            for item in items {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw StoragePhotoImportError.couldNotReadImage
                }

                let contentType = item.supportedContentTypes.first(where: { $0.conforms(to: .image) }) ?? .jpeg
                let fileExtension = contentType.preferredFilenameExtension ?? "jpg"
                let fileName = "photo-\(UUID().uuidString.lowercased()).\(fileExtension)"

                selectedFiles.append(
                    StorageUploadItem(
                        data: data,
                        fileName: fileName,
                        contentType: contentType.preferredMIMEType ?? "image/jpeg"
                    )
                )
            }

            try await storageViewModel.uploadFiles(selectedFiles, using: sessionStore)
        } catch {
            storageActionErrorMessage = error.localizedDescription
        }
    }

    private func loadSelectedFile(from url: URL) throws -> StorageUploadItem {
        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey, .nameKey])
        let fileName = resourceValues.name ?? url.lastPathComponent
        let data = try Data(contentsOf: url)
        let contentType = resourceValues.contentType?.preferredMIMEType
            ?? UTType(filenameExtension: url.pathExtension)?.preferredMIMEType

        return StorageUploadItem(
            data: data,
            fileName: fileName,
            contentType: contentType
        )
    }
}

private enum StoragePhotoImportError: LocalizedError {
    case couldNotReadImage

    var errorDescription: String? {
        switch self {
        case .couldNotReadImage:
            return "Could not load the selected photo."
        }
    }
}

enum WorkspaceTab: Hashable {
    case home
    case starred
    case storage
    case shared
    case trash
    case admin
}

extension WorkspaceTab: CaseIterable {
    static var allCases: [WorkspaceTab] {
        [.home, .starred, .storage, .shared, .trash, .admin]
    }

    static var primaryTabs: [WorkspaceTab] {
        [.home, .starred, .storage, .shared]
    }
}

extension WorkspaceTab {
    func title(strings: AppStrings) -> String {
        switch self {
        case .home: strings.home
        case .starred: strings.starred
        case .storage: strings.storage
        case .shared: strings.shared
        case .trash: strings.trash
        case .admin: strings.admin
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .starred: "star.fill"
        case .storage: "externaldrive.fill"
        case .shared: "person.2.fill"
        case .trash: "trash.fill"
        case .admin: "person.3.fill"
        }
    }
}

private struct WorkspacePlaceholderView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let onMenuTap: () -> Void

    @State private var showingProfileSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 20) {
                    Image(systemName: systemImage)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .padding(24)
                        .background(
                            Circle()
                                .fill(AppPalette.cardStrong)
                        )

                    VStack(spacing: 10) {
                        Text(title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppPalette.textPrimary)

                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.body)
                                .foregroundStyle(AppPalette.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(28)
                .appCard(padding: 28)
                .padding(24)
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
                    Text(title)
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
        }
    }
}
