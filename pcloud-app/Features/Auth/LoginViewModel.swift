import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    func login(
        using sessionStore: SessionStore,
        usernameRequiredMessage: String,
        passwordRequiredMessage: String
    ) async {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty else {
            errorMessage = usernameRequiredMessage
            return
        }

        guard !password.isEmpty else {
            errorMessage = passwordRequiredMessage
            return
        }

        isSubmitting = true
        errorMessage = nil

        defer { isSubmitting = false }

        do {
            try await sessionStore.login(username: trimmedUsername, password: password)
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
