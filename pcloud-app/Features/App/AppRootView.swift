import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    var body: some View {
        let strings = settingsStore.strings

        ZStack {
            AppBackground()

            Group {
                if sessionStore.isRestoringSession {
                    VStack(spacing: 14) {
                        ProgressView()
                            .tint(AppPalette.textPrimary)
                        Text(strings.restoringSession)
                            .font(.headline)
                            .foregroundStyle(AppPalette.textPrimary)
                    }
                    .appCard(padding: 28)
                    .padding(24)
                } else if sessionStore.isAuthenticated {
                    WorkspaceShellView()
                } else {
                    LoginView()
                }
            }
        }
        .task {
            await sessionStore.restoreSessionIfNeeded()
        }
    }
}
