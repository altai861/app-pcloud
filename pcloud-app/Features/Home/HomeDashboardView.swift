import SwiftUI

struct HomeDashboardView: View {
    @Binding var selectedTab: WorkspaceTab
    @ObservedObject var storageViewModel: StorageHomeViewModel
    let onMenuTap: () -> Void

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @State private var showingProfileSheet = false

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        headerCard
                        recentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 34)
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
                    Text(strings.appName)
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
            .refreshable {
                await storageViewModel.refresh(using: sessionStore)
            }
        }
    }

    private var headerCard: some View {
        let strings = settingsStore.strings

        return VStack(alignment: .leading, spacing: 14) {
            Text(greetingTitle)
                .font(.title.weight(.heavy))
                .foregroundStyle(AppPalette.textPrimary)

            HStack(spacing: 10) {
                Label(sessionStore.currentUser?.username ?? strings.guest, systemImage: "person.fill")
                Label(hostDisplayName, systemImage: "network")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(AppPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 22)
    }

    private var quickActionsCard: some View {
        let strings = settingsStore.strings

        return VStack(alignment: .leading, spacing: 14) {
            Text(strings.quickAccess)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)

            HStack(spacing: 12) {
                quickActionButton(title: strings.storage, systemImage: "folder.fill", tab: .storage)
                quickActionButton(title: strings.starred, systemImage: "star.fill", tab: .starred)
                quickActionButton(title: strings.shared, systemImage: "person.2.fill", tab: .shared)
                quickActionButton(title: strings.trash, systemImage: "trash.fill", tab: .trash)
            }
        }
        .appCard(padding: 20)
    }

    private var recentSection: some View {
        let strings = settingsStore.strings

        return VStack(alignment: .leading, spacing: 12) {
            HStack {

                Spacer()

                Button(strings.seeAll) {
                    selectedTab = .storage
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
            }

            if storageViewModel.isLoading && storageViewModel.entries.isEmpty {
                ProgressView(strings.loadingWorkspace)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 28)
                    .appCard()
            } else if let errorMessage = storageViewModel.errorMessage, storageViewModel.entries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(strings.workspaceLoadErrorTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard()
            } else if storageViewModel.entries.isEmpty {
                Text(strings.emptyRoot)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(storageViewModel.entries.prefix(4))) { entry in
                        StorageEntryRow(entry: entry, style: .prominent)
                    }
                }
            }
        }
    }

    private func quickActionButton(title: String, systemImage: String, tab: WorkspaceTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(AppPalette.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppPalette.softBlue)
                    )

                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private var greetingTitle: String {
        settingsStore.strings.welcomeBack(name: sessionStore.currentUser?.fullName)
    }

    private var hostDisplayName: String {
        settingsStore.apiBaseURL?.host() ?? settingsStore.apiBaseURLString
    }
}
