import SwiftUI

struct AdminUsersView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @ObservedObject var viewModel: AdminUsersViewModel
    let onMenuTap: () -> Void

    @State private var showingProfileSheet = false
    @State private var showingAddUserSheet = false
    @State private var selectedUser: AdminUser?

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        headerCard
                        addUserCard
                        contentSection
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
                    Text(strings.admin)
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
            .sheet(isPresented: $showingAddUserSheet) {
                AdminUserCreateSheet(viewModel: viewModel)
            }
            .sheet(item: $selectedUser) { user in
                AdminUserDetailSheet(
                    user: user,
                    viewModel: viewModel
                )
            }
            .task {
                await viewModel.load(using: sessionStore)
            }
            .refreshable {
                await viewModel.refresh(using: sessionStore)
            }
        }
    }

    private var headerCard: some View {
        let strings = settingsStore.strings

        return VStack(alignment: .leading, spacing: 14) {
            Text(strings.adminUsersTitle)
                .font(.title2.weight(.heavy))
                .foregroundStyle(AppPalette.textPrimary)

            HStack(spacing: 12) {
                statPill(title: strings.usersCount, value: "\(viewModel.users.count)")
                statPill(
                    title: strings.adminCount,
                    value: "\(viewModel.users.filter(\.isAdmin).count)"
                )
            }
        }
        .appCard(padding: 20)
    }

    private var addUserCard: some View {
        let strings = settingsStore.strings

        return Button {
            showingAddUserSheet = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.badge.plus")
                    .font(.headline)
                    .foregroundStyle(AppPalette.textPrimary)
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppPalette.softBlue)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.addUser)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .appCard(padding: 18)
    }

    @ViewBuilder
    private var contentSection: some View {
        let strings = settingsStore.strings

        if viewModel.isLoading && viewModel.users.isEmpty {
            ProgressView(strings.loadingUsers)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .appCard()
        } else if let errorMessage = viewModel.errorMessage, viewModel.users.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.adminLoadError)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        } else if viewModel.users.isEmpty {
            Text(strings.noUsersYet)
                .font(.subheadline)
                .foregroundStyle(AppPalette.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard()
        } else {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.users) { user in
                    AdminUserRow(user: user) {
                        selectedUser = user
                    }
                }
            }
        }
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppPalette.textSecondary)

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppPalette.cardStrong)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppPalette.stroke, lineWidth: 1)
        )
    }
}

private struct AdminUserRow: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let user: AdminUser
    let onOpenDetails: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ProfileAvatarView(
                userID: user.id,
                fullName: user.fullName,
                username: user.username,
                size: 48
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(user.fullName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .lineLimit(1)

                    statusBadge
                }

                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.textSecondary)
                    .lineLimit(1)

                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Menu {
                Button(settingsStore.strings.viewDetails, systemImage: "slider.horizontal.3") {
                    onOpenDetails()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(AppPalette.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppPalette.cardStrong)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
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

    private var statusBadge: some View {
        Text(user.role.capitalized)
            .font(.caption2.weight(.bold))
            .foregroundStyle(AppPalette.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(user.isAdmin ? AppPalette.accent.opacity(0.2) : AppPalette.softBlue)
            )
    }
}

private struct AdminUserCreateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @ObservedObject var viewModel: AdminUsersViewModel

    @State private var draft = AdminCreateUserDraft()
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            Form {
                Section(strings.adminUserInfoSection) {
                    TextField(strings.username, text: $draft.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField(strings.email, text: $draft.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    TextField(strings.fullName, text: $draft.fullName)

                    StorageQuotaInputSection(draft: $draft)
                }

                Section(strings.adminSecuritySection) {
                    SecureField(strings.password, text: $draft.password)
                    SecureField(strings.passwordConfirmation, text: $draft.passwordConfirmation)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(strings.addUser)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? strings.saving : strings.create) {
                        submit()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }

    private func submit() {
        errorMessage = nil
        isSubmitting = true

        Task {
            defer { isSubmitting = false }

            do {
                try await viewModel.createUser(
                    username: draft.username.trimmed,
                    email: draft.email.trimmed,
                    fullName: draft.fullName.trimmed,
                    password: draft.password,
                    passwordConfirmation: draft.passwordConfirmation,
                    storageQuotaBytes: draft.parsedQuota,
                    using: sessionStore
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct AdminUserDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let user: AdminUser
    @ObservedObject var viewModel: AdminUsersViewModel

    @State private var draft: AdminEditUserDraft
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var isDeleting = false

    init(user: AdminUser, viewModel: AdminUsersViewModel) {
        self.user = user
        self.viewModel = viewModel
        _draft = State(initialValue: AdminEditUserDraft(user: user))
    }

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            Form {
                Section(strings.userDetails) {
                    TextField(strings.username, text: $draft.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField(strings.email, text: $draft.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField(strings.fullName, text: $draft.fullName)

                    StorageQuotaInputSection(draft: $draft)
                }

                Section(strings.userMeta) {
                    infoRow(title: strings.role, value: user.role.capitalized)
                    infoRow(title: strings.status, value: user.status.capitalized)
                    infoRow(title: strings.used, value: ByteCountFormatter.string(fromByteCount: user.storageUsedBytes, countStyle: .file))
                    infoRow(title: strings.createdOn, value: user.createdAtDate.formatted(.dateTime.year().month().day()))
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                if !user.isAdmin {
                    Section {
                        Button(role: .destructive) {
                            deleteUser()
                        } label: {
                            if isDeleting {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Text(strings.deleteUser)
                            }
                        }
                        .disabled(isDeleting || isSaving)
                    }
                }
            }
            .navigationTitle(strings.userDetails)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? strings.saving : strings.saveChanges) {
                        saveUser()
                    }
                    .disabled(isSaving || isDeleting)
                }
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppPalette.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(AppPalette.textPrimary)
        }
    }

    private func saveUser() {
        errorMessage = nil
        isSaving = true

        Task {
            defer { isSaving = false }

            do {
                try await viewModel.updateUser(
                    userID: user.id,
                    username: draft.username.trimmed,
                    email: draft.email.trimmed,
                    fullName: draft.fullName.trimmed,
                    storageQuotaBytes: draft.parsedQuota,
                    using: sessionStore
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteUser() {
        errorMessage = nil
        isDeleting = true

        Task {
            defer { isDeleting = false }

            do {
                try await viewModel.deleteUser(userID: user.id, using: sessionStore)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct StorageQuotaInputSection<Draft: StorageQuotaDraftRepresentable>: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @Binding var draft: Draft

    var body: some View {
        let strings = settingsStore.strings

        VStack(alignment: .leading, spacing: 12) {
            Text(strings.storageQuotaLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)

            HStack(spacing: 12) {
                TextField("0", text: $draft.storageQuotaValue)
                    .keyboardType(.decimalPad)

                Picker(strings.storageQuotaUnit, selection: $draft.storageQuotaUnit) {
                    ForEach(StorageQuotaUnit.allCases) { unit in
                        Text(unit.label)
                            .tag(unit)
                    }
                }
                .pickerStyle(.menu)
            }

            Text("\(strings.exactBytes): \(draft.exactBytesDescription)")
                .font(.footnote)
                .foregroundStyle(AppPalette.textSecondary)
        }
    }
}

private protocol StorageQuotaDraftRepresentable {
    var storageQuotaValue: String { get set }
    var storageQuotaUnit: StorageQuotaUnit { get set }
    var exactBytesDescription: String { get }
}

private struct AdminCreateUserDraft: StorageQuotaDraftRepresentable {
    var username = ""
    var email = ""
    var fullName = ""
    var password = ""
    var passwordConfirmation = ""
    var storageQuotaValue = ""
    var storageQuotaUnit: StorageQuotaUnit = .gb

    var trimmedQuotaText: String {
        storageQuotaValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var parsedQuota: Int64 {
        storageQuotaUnit.bytes(for: trimmedQuotaText)
    }

    var exactBytesDescription: String {
        Self.formattedBytes(parsedQuota)
    }
}

private struct AdminEditUserDraft: StorageQuotaDraftRepresentable {
    var username: String
    var email: String
    var fullName: String
    var storageQuotaValue: String
    var storageQuotaUnit: StorageQuotaUnit

    init(user: AdminUser) {
        username = user.username
        email = user.email
        fullName = user.fullName
        let selection = StorageQuotaUnitSelection(bytes: user.storageQuotaBytes)
        storageQuotaValue = selection.valueText
        storageQuotaUnit = selection.unit
    }

    var trimmedQuotaText: String {
        storageQuotaValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var parsedQuota: Int64 {
        storageQuotaUnit.bytes(for: trimmedQuotaText)
    }

    var exactBytesDescription: String {
        Self.formattedBytes(parsedQuota)
    }
}

private enum StorageQuotaUnit: String, CaseIterable, Identifiable {
    case mb
    case gb
    case tb
    case pb

    var id: String { rawValue }

    var label: String {
        rawValue.uppercased()
    }

    var multiplier: Double {
        switch self {
        case .mb: 1_048_576
        case .gb: 1_073_741_824
        case .tb: 1_099_511_627_776
        case .pb: 1_125_899_906_842_624
        }
    }

    func bytes(for text: String) -> Int64 {
        guard let value = Double(text.replacingOccurrences(of: ",", with: ".")),
              value.isFinite,
              value >= 0 else {
            return 0
        }

        let result = value * multiplier
        if result >= Double(Int64.max) {
            return Int64.max
        }

        return Int64(result.rounded())
    }
}

private struct StorageQuotaUnitSelection {
    let valueText: String
    let unit: StorageQuotaUnit

    init(bytes: Int64) {
        if bytes <= 0 {
            valueText = ""
            unit = .gb
            return
        }

        let preferredUnit: StorageQuotaUnit
        if bytes >= Int64(StorageQuotaUnit.pb.multiplier) {
            preferredUnit = .pb
        } else if bytes >= Int64(StorageQuotaUnit.tb.multiplier) {
            preferredUnit = .tb
        } else if bytes >= Int64(StorageQuotaUnit.gb.multiplier) {
            preferredUnit = .gb
        } else {
            preferredUnit = .mb
        }

        unit = preferredUnit
        valueText = Self.formatValue(Double(bytes) / preferredUnit.multiplier)
    }

    private static func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = value.rounded() == value ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension StorageQuotaDraftRepresentable {
    static func formattedBytes(_ bytes: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(value: bytes)
        return formatter.string(from: number) ?? "\(bytes)"
    }
}

private extension AdminUser {
    var isAdmin: Bool {
        role.caseInsensitiveCompare("admin") == .orderedSame
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        if !letters.isEmpty {
            return String(letters)
        }

        return String(username.prefix(2)).uppercased()
    }

    var createdAtDate: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAtUnixMs) / 1000)
    }
}
