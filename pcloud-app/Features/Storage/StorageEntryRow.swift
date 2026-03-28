import SwiftUI

struct StorageEntryRow: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let entry: StorageEntry
    var style: StorageEntryRowStyle = .standard
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(entry.isFolder ? AppPalette.softBlue : AppPalette.cardStrong)
                .frame(width: style.iconBoxSize, height: style.iconBoxSize)
                .overlay {
                    Image(systemName: entry.isFolder ? "folder.fill" : "doc.text.fill")
                        .font(.system(size: style.iconSize, weight: .semibold))
                        .foregroundStyle(entry.isFolder ? AppPalette.softBlueDeep : AppPalette.textPrimary)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text(entry.name)
                        .font(style.titleFont)
                        .foregroundStyle(AppPalette.textPrimary)
                        .lineLimit(1)

                    if entry.isStarred {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                Text(entry.path)
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(modifiedLabel)

                    if let sizeLabel {
                        Text("•")
                        Text(sizeLabel)
                    }
                }
                .font(.caption2)
                .foregroundStyle(AppPalette.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: action != nil ? "chevron.right" : "ellipsis")
                .font(.headline)
                .foregroundStyle(AppPalette.textSecondary)
        }
        .padding(style.contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .fill(style == .prominent ? AppPalette.card : AppPalette.cardStrong)
        )
        .overlay(
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .stroke(AppPalette.stroke, lineWidth: 1)
        )
        .shadow(color: style == .prominent ? AppPalette.shadow : .clear, radius: 12, x: 0, y: 8)
    }

    private var sizeLabel: String? {
        guard let sizeBytes = entry.sizeBytes else {
            return nil
        }

        return ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    private var modifiedLabel: String {
        let strings = settingsStore.strings

        guard let modifiedAtUnixMs = entry.modifiedAtUnixMs else {
            return strings.updatedRecently
        }

        let date = Date(timeIntervalSince1970: TimeInterval(modifiedAtUnixMs) / 1000)
        return strings.modifiedOn(date, locale: settingsStore.locale)
    }
}

enum StorageEntryRowStyle {
    case standard
    case prominent

    var iconBoxSize: CGFloat {
        switch self {
        case .standard: 46
        case .prominent: 52
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .standard: 20
        case .prominent: 22
        }
    }

    var titleFont: Font {
        switch self {
        case .standard:
            .body.weight(.semibold)
        case .prominent:
            .headline.weight(.semibold)
        }
    }

    var contentPadding: CGFloat {
        switch self {
        case .standard: 14
        case .prominent: 16
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .standard: 20
        case .prominent: 22
        }
    }
}
