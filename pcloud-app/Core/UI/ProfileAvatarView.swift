import SwiftUI

struct ProfileAvatarView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    let userID: Int64?
    let fullName: String
    let username: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var imageURL: URL? {
        guard let userID else {
            return nil
        }

        return sessionStore.profileImageURL(for: userID)
    }

    private var placeholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [AppPalette.accent, AppPalette.softBlueDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
    }

    private var initials: String {
        let trimmedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmedFullName.isEmpty ? (username ?? "") : trimmedFullName
        let parts = source.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first)

        if !letters.isEmpty {
            return String(letters).uppercased()
        }

        return String(source.prefix(2)).uppercased()
    }
}

struct CurrentUserProfileButton: View {
    @EnvironmentObject private var sessionStore: SessionStore

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ProfileAvatarView(
                userID: sessionStore.currentUser?.id,
                fullName: sessionStore.currentUser?.fullName ?? "",
                username: sessionStore.currentUser?.username,
                size: 30
            )
            .overlay(
                Circle()
                    .stroke(AppPalette.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
