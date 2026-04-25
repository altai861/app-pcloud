import SwiftUI

struct StorageShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: StorageEntry

    @State private var permissions: [SharePermission] = []
    @State private var isLoadingPermissions = true
    @State private var permissionsError: String?

    @State private var searchText = ""
    @State private var searchResults: [ShareableUser] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var hasSearched = false

    @State private var selectedUser: ShareableUser?
    @State private var selectedPrivilege: SharePrivilege = .viewer
    @State private var isGranting = false
    @State private var grantError: String?

    @State private var isMutating = false

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        currentPermissionsSection(strings: strings)
                        addUserSection(strings: strings)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(strings.shareTitle(entry.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            await loadPermissions()
        }
    }

    private func currentPermissionsSection(strings: AppStrings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings.shareCurrentPermissions)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)

            if isLoadingPermissions {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .appCard()
            } else if let error = permissionsError {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()
            } else if permissions.isEmpty {
                Text(strings.shareNoPermissions)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()
            } else {
                VStack(spacing: 10) {
                    ForEach(permissions) { permission in
                        permissionRow(permission, strings: strings)
                    }
                }
                .appCard(padding: 14)
            }
        }
    }

    private func permissionRow(_ permission: SharePermission, strings: AppStrings) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(AppPalette.softBlueDeep)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(permission.fullName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .lineLimit(1)

                Text("@\(permission.username)")
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)
            }

            Spacer()

            Menu {
                Button(strings.privilegeViewer) {
                    Task { await updatePermission(permission, privilege: .viewer) }
                }

                Button(strings.privilegeEditor) {
                    Task { await updatePermission(permission, privilege: .editor) }
                }

                Divider()

                Button(strings.shareRemoveAccess, role: .destructive) {
                    Task { await removePermission(permission) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(privilegeLabel(permission.privilegeType, strings: strings))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)

                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppPalette.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppPalette.softBlue)
                )
            }
            .buttonStyle(.plain)
            .disabled(isMutating)
        }
    }

    private func addUserSection(strings: AppStrings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings.shareAddPeople)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)

            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppPalette.textSecondary)

                    TextField(strings.shareSearchUsersPlaceholder, text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await searchUsers() }
                        }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppPalette.cardStrong)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppPalette.stroke, lineWidth: 1)
                )

                Button {
                    Task { await searchUsers() }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(isSearching ? AppPalette.textSecondary : AppPalette.softBlueDeep)
                }
                .buttonStyle(.plain)
                .disabled(isSearching || searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let error = searchError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            } else if hasSearched && searchResults.isEmpty {
                Text(strings.shareNoUsersFound)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else if !searchResults.isEmpty {
                VStack(spacing: 8) {
                    ForEach(searchResults) { user in
                        userSearchRow(user, strings: strings)
                    }
                }
                .appCard(padding: 12)
            }

            if let user = selectedUser {
                grantSection(user: user, strings: strings)
            }
        }
    }

    private func userSearchRow(_ user: ShareableUser, strings: AppStrings) -> some View {
        let isSelected = selectedUser?.userId == user.userId

        return Button {
            if isSelected {
                selectedUser = nil
            } else {
                selectedUser = user
                grantError = nil
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppPalette.softBlueDeep : AppPalette.textSecondary)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(user.fullName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .lineLimit(1)

                    Text("@\(user.username)")
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppPalette.softBlueDeep)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func grantSection(user: ShareableUser, strings: AppStrings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(strings.sharePrivilegeLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textSecondary)

                Spacer()

                Picker(strings.sharePrivilegeLabel, selection: $selectedPrivilege) {
                    Text(strings.privilegeViewer).tag(SharePrivilege.viewer)
                    Text(strings.privilegeEditor).tag(SharePrivilege.editor)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            if let error = grantError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await grantPermission(to: user) }
            } label: {
                HStack(spacing: 8) {
                    if isGranting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus")
                    }

                    Text(isGranting ? strings.shareSharing : strings.shareShare)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppPalette.accent)
                )
            }
            .buttonStyle(.plain)
            .disabled(isGranting || isMutating)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppPalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppPalette.stroke, lineWidth: 1)
        )
    }

    private func privilegeLabel(_ type: String, strings: AppStrings) -> String {
        let normalized = type.lowercased()
        if normalized == "editor" || normalized == "edit" {
            return strings.privilegeEditor
        }
        return strings.privilegeViewer
    }

    @MainActor
    private func loadPermissions() async {
        isLoadingPermissions = true
        permissionsError = nil

        do {
            let api = try sessionStore.makeStorageAPI()
            let response = try await api.listSharePermissions(
                entryType: entry.entryType,
                resourceId: entry.rawID
            )
            permissions = response.entries
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            permissionsError = apiError.localizedDescription
        } catch {
            permissionsError = error.localizedDescription
        }

        isLoadingPermissions = false
    }

    @MainActor
    private func searchUsers() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return
        }

        isSearching = true
        searchError = nil
        selectedUser = nil
        grantError = nil
        hasSearched = false

        do {
            let api = try sessionStore.makeStorageAPI()
            let response = try await api.searchShareableUsers(search: query)
            searchResults = response.users
            hasSearched = true
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            searchError = apiError.localizedDescription
        } catch {
            searchError = error.localizedDescription
        }

        isSearching = false
    }

    @MainActor
    private func grantPermission(to user: ShareableUser) async {
        isGranting = true
        grantError = nil

        do {
            let api = try sessionStore.makeStorageAPI()
            _ = try await api.upsertSharePermission(
                entryType: entry.entryType,
                resourceId: entry.rawID,
                targetUserId: user.userId,
                privilegeType: selectedPrivilege.rawValue
            )

            selectedUser = nil
            searchText = ""
            searchResults = []
            hasSearched = false
            await loadPermissions()
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            grantError = apiError.localizedDescription
        } catch {
            grantError = error.localizedDescription
        }

        isGranting = false
    }

    @MainActor
    private func updatePermission(_ permission: SharePermission, privilege: SharePrivilege) async {
        isMutating = true

        do {
            let api = try sessionStore.makeStorageAPI()
            _ = try await api.upsertSharePermission(
                entryType: entry.entryType,
                resourceId: entry.rawID,
                targetUserId: permission.userId,
                privilegeType: privilege.rawValue
            )

            await loadPermissions()
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            permissionsError = apiError.localizedDescription
        } catch {
            permissionsError = error.localizedDescription
        }

        isMutating = false
    }

    @MainActor
    private func removePermission(_ permission: SharePermission) async {
        isMutating = true

        do {
            let api = try sessionStore.makeStorageAPI()
            _ = try await api.removeSharePermission(
                entryType: entry.entryType,
                resourceId: entry.rawID,
                targetUserId: permission.userId
            )

            await loadPermissions()
        } catch let apiError as APIClientError {
            if apiError.isUnauthorized {
                sessionStore.clearSessionLocally()
            }

            permissionsError = apiError.localizedDescription
        } catch {
            permissionsError = error.localizedDescription
        }

        isMutating = false
    }
}

private enum SharePrivilege: String, CaseIterable {
    case viewer
    case editor
}
