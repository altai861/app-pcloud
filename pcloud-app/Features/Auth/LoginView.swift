import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @StateObject private var viewModel = LoginViewModel()
    @State private var showingServerConnection = false
    @FocusState private var focusedField: LoginField?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            Spacer(minLength: 16)
                            serverCard
                            brandCard
                            signInCard
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }

                    HStack(spacing: 12) {
                        ThemePreferenceToggle()
                        LanguagePreferenceToggle()
                    }
                    .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .padding(.bottom, 28)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingServerConnection) {
                ServerConnectionSheet()
            }
        }
    }

    private var brandCard: some View {
        let strings = settingsStore.strings

        return VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.cardStrong)
                .frame(height: 58)
                .overlay {
                    Text(strings.appName)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppPalette.stroke, lineWidth: 1)
                )
        }
        .appCard(padding: 12)
    }

    private var serverCard: some View {
        let strings = settingsStore.strings

        return HStack(spacing: 10) {
            Image(systemName: connectionModeSystemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppPalette.textPrimary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppPalette.softBlue)
                )

            Text(connectionDisplayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .lineLimit(1)

            Spacer()

            Button {
                showingServerConnection = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(AppPalette.cardStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(AppPalette.stroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(strings.connectServerTitle)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppPalette.cardStrong.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppPalette.stroke, lineWidth: 1)
        )
    }

    private var signInCard: some View {
        let strings = settingsStore.strings

        return VStack(alignment: .leading, spacing: 18) {
            Text(strings.signInTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppPalette.textPrimary)

            fieldContainer(systemImage: "person", title: strings.username) {
                TextField(strings.usernamePlaceholder, text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }
            }

            fieldContainer(systemImage: "lock", title: strings.password) {
                SecureField(strings.passwordPlaceholder, text: $viewModel.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        focusedField = nil
                        submitLogin()
                    }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                focusedField = nil
                submitLogin()
            } label: {
                if viewModel.isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(strings.signInTitle)
                }
            }
            .buttonStyle(PrimaryCapsuleButtonStyle())
            .disabled(viewModel.isSubmitting)
        }
        .appCard(padding: 20)
    }

    private func fieldContainer<Content: View>(
        systemImage: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.textSecondary)

            content()
                .font(.body)
                .padding(.horizontal, 16)
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
    }

    private func submitLogin() {
        Task {
            let strings = settingsStore.strings
            await viewModel.login(
                using: sessionStore,
                usernameRequiredMessage: strings.usernameRequired,
                passwordRequiredMessage: strings.passwordRequired
            )
        }
    }

    private var connectionDisplayName: String {
        if let selectedServerName = settingsStore.selectedServerName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !selectedServerName.isEmpty
        {
            return selectedServerName
        }

        if let selectedDeviceID = settingsStore.selectedDeviceID?.trimmingCharacters(in: .whitespacesAndNewlines),
           !selectedDeviceID.isEmpty
        {
            return selectedDeviceID
        }

        return displayAddress(from: settingsStore.apiBaseURLString)
    }

    private var connectionModeSystemImage: String {
        switch settingsStore.serverConnectionMode {
        case .manual:
            return "link"
        case .lan:
            return "wifi"
        case .relay:
            return "point.3.connected.trianglepath.dotted"
        }
    }

    private func displayAddress(from rawValue: String) -> String {
        guard
            let url = AppSettingsStore.validatedURL(from: rawValue),
            let host = url.host()
        else {
            return rawValue
        }

        if let port = url.port {
            return "\(host):\(port)"
        }

        return host
    }
}

private enum LoginField {
    case username
    case password
}
