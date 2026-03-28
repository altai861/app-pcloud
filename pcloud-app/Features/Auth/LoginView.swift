import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @StateObject private var viewModel = LoginViewModel()
    @State private var showingSettings = false
    @FocusState private var focusedField: LoginField?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 22) {
                            Spacer(minLength: 24)
                            brandCard
                            serverCard
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var brandCard: some View {
        let strings = settingsStore.strings

        return VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.cardStrong)
                .frame(height: 88)
                .overlay {
                    Text(strings.appName)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppPalette.stroke, lineWidth: 1)
                )
        }
        .appCard(padding: 18)
    }

    private var serverCard: some View {
        let strings = settingsStore.strings

        return Button {
            showingSettings = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "network")
                    .font(.headline)
                    .foregroundStyle(AppPalette.textPrimary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.cloudServer)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.textSecondary)

                    Text(settingsStore.apiBaseURLString)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppPalette.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundStyle(AppPalette.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .appCard(padding: 18)
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
}

private enum LoginField {
    case username
    case password
}
