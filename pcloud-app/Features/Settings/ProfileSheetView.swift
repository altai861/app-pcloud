import PhotosUI
import SwiftUI
import UIKit

struct ProfileSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var uploadErrorMessage: String?

    var body: some View {
        let strings = settingsStore.strings
        let currentUser = sessionStore.currentUser

        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        profileCard(user: currentUser, strings: strings)
                        QuickPreferencesCard()
                        actionsCard(strings: strings)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle(strings.profile)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.cancel) {
                        dismiss()
                    }
                    .foregroundStyle(AppPalette.textPrimary)
                }
            }
            .task(id: selectedPhotoItem) {
                await handlePhotoSelection()
            }
        }
    }

    private func profileCard(user: AuthUser?, strings: AppStrings) -> some View {
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        ProfileAvatarView(
                            userID: user?.id,
                            fullName: user?.fullName ?? strings.profile,
                            username: user?.username,
                            size: 64
                        )
                        .overlay(
                            Circle()
                                .stroke(AppPalette.stroke, lineWidth: 1)
                        )

                        Group {
                            if isUploadingPhoto {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(AppPalette.accent)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.75), lineWidth: 1)
                        )
                    }
                }
                .buttonStyle(.plain)
                .disabled(isUploadingPhoto)

                VStack(alignment: .leading, spacing: 4) {
                    Text(user?.fullName ?? strings.profile)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text("@\(user?.username ?? strings.guest.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.textSecondary)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                if let uploadErrorMessage {
                    Text(uploadErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .appCard(padding: 18)
    }

    private func actionsCard(strings: AppStrings) -> some View {
        VStack(spacing: 12) {
            Button {
                dismiss()
                Task {
                    await sessionStore.logout()
                }
            } label: {
                Label(strings.signOut, systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
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
            .buttonStyle(.plain)
        }
        .appCard(padding: 18)
    }

    private func handlePhotoSelection() async {
        guard let selectedPhotoItem else {
            return
        }

        uploadErrorMessage = nil
        isUploadingPhoto = true

        defer {
            isUploadingPhoto = false
            self.selectedPhotoItem = nil
        }

        do {
            guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                throw ProfilePhotoError.couldNotReadImage
            }

            let prepared = try ProfilePhotoPreparation.prepareUploadData(from: data)
            try await sessionStore.uploadProfileImage(
                imageData: prepared.data,
                fileName: prepared.fileName,
                contentType: prepared.contentType
            )
        } catch {
            uploadErrorMessage = error.localizedDescription
        }
    }
}

private enum ProfilePhotoError: LocalizedError {
    case couldNotReadImage
    case invalidImage
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .couldNotReadImage:
            return "Could not load the selected image."
        case .invalidImage:
            return "The selected photo could not be prepared for upload."
        case .imageTooLarge:
            return "Profile image limit exceeded. Maximum size is 30 MB."
        }
    }
}

private struct ProfilePhotoPreparation {
    let data: Data
    let fileName: String
    let contentType: String

    private static let maxUploadBytes = 30 * 1024 * 1024

    static func prepareUploadData(from originalData: Data) throws -> ProfilePhotoPreparation {
        guard let image = UIImage(data: originalData) else {
            throw ProfilePhotoError.invalidImage
        }

        for quality in [0.9, 0.75, 0.6, 0.45] {
            if let jpegData = image.jpegData(compressionQuality: quality), jpegData.count <= maxUploadBytes {
                return ProfilePhotoPreparation(
                    data: jpegData,
                    fileName: "profile.jpg",
                    contentType: "image/jpeg"
                )
            }
        }

        throw ProfilePhotoError.imageTooLarge
    }
}
