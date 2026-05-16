import SwiftUI

struct StorageResourceIcon: View {
    let name: String
    let isFolder: Bool
    var width: CGFloat?
    var height: CGFloat
    var iconSize: CGFloat
    var cornerRadius: CGFloat

    init(
        name: String,
        isFolder: Bool,
        width: CGFloat? = nil,
        height: CGFloat,
        iconSize: CGFloat,
        cornerRadius: CGFloat
    ) {
        self.name = name
        self.isFolder = isFolder
        self.width = width
        self.height = height
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        let icon = StorageResourceIconDescriptor(name: name, isFolder: isFolder)

        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(icon.background)
            .frame(width: width, height: height)
            .overlay {
                Image(systemName: icon.systemImage)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(icon.foreground)
            }
    }
}

struct StorageResourceIconDescriptor {
    let systemImage: String
    let foreground: Color
    let background: Color

    init(name: String, isFolder: Bool) {
        if isFolder {
            systemImage = "folder.fill"
            foreground = AppPalette.softBlueDeep
            background = AppPalette.softBlue
            return
        }

        let fileExtension = Self.fileExtension(from: name)

        switch fileExtension {
        case "jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "tiff", "tif", "bmp", "svg", "raw":
            systemImage = "photo.fill"
            foreground = Color(red: 0.11, green: 0.58, blue: 0.36)
            background = Color(red: 0.84, green: 0.96, blue: 0.88)
        case "mp4", "mov", "m4v", "avi", "mkv", "webm", "wmv", "flv", "ogv":
            systemImage = "film.fill"
            foreground = Color(red: 0.49, green: 0.29, blue: 0.86)
            background = Color(red: 0.91, green: 0.86, blue: 1.0)
        case "mp3", "wav", "m4a", "aac", "flac", "ogg", "opus", "aiff", "wma":
            systemImage = "waveform"
            foreground = Color(red: 0.83, green: 0.38, blue: 0.08)
            background = Color(red: 1.0, green: 0.91, blue: 0.78)
        case "zip", "rar", "7z", "tar", "gz", "tgz", "bz2", "xz", "iso", "dmg":
            systemImage = "archivebox.fill"
            foreground = Color(red: 0.62, green: 0.42, blue: 0.14)
            background = Color(red: 0.94, green: 0.88, blue: 0.74)
        case "pdf":
            systemImage = "doc.richtext.fill"
            foreground = Color(red: 0.83, green: 0.16, blue: 0.16)
            background = Color(red: 1.0, green: 0.86, blue: 0.84)
        case "doc", "docx", "rtf", "odt", "pages":
            systemImage = "doc.text.fill"
            foreground = Color(red: 0.12, green: 0.39, blue: 0.82)
            background = Color(red: 0.84, green: 0.91, blue: 1.0)
        case "xls", "xlsx", "csv", "tsv", "ods", "numbers":
            systemImage = "tablecells.fill"
            foreground = Color(red: 0.05, green: 0.54, blue: 0.28)
            background = Color(red: 0.82, green: 0.95, blue: 0.87)
        case "ppt", "pptx", "key", "odp":
            systemImage = "chart.bar.doc.horizontal.fill"
            foreground = Color(red: 0.86, green: 0.31, blue: 0.14)
            background = Color(red: 1.0, green: 0.88, blue: 0.80)
        case "txt", "md", "markdown", "log":
            systemImage = "doc.plaintext.fill"
            foreground = AppPalette.textPrimary
            background = AppPalette.cardStrong
        case "json", "xml", "yaml", "yml", "html", "css", "js", "ts", "jsx", "tsx", "swift", "kt", "java", "py", "rb", "go", "rs", "c", "h", "cpp", "hpp", "cs", "php", "sh", "sql":
            systemImage = "chevron.left.forwardslash.chevron.right"
            foreground = Color(red: 0.33, green: 0.36, blue: 0.86)
            background = Color(red: 0.87, green: 0.89, blue: 1.0)
        default:
            systemImage = "doc.fill"
            foreground = AppPalette.textPrimary
            background = AppPalette.cardStrong
        }
    }

    private static func fileExtension(from name: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercasedName = trimmedName.lowercased()

        if lowercasedName.hasSuffix(".tar.gz") || lowercasedName.hasSuffix(".tar.bz2") || lowercasedName.hasSuffix(".tar.xz") {
            return "tar"
        }

        return URL(fileURLWithPath: trimmedName).pathExtension.lowercased()
    }
}
