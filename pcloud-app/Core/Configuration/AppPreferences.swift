import SwiftUI

enum AppThemePreference: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case mongolian

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .english:
            return "en"
        case .mongolian:
            return "mn"
        }
    }
}

struct AppStrings {
    let language: AppLanguage

    var appName: String { "PCloud" }

    var personalizeTitle: String {
        switch language {
        case .english: "Personalize"
        case .mongolian: "Тохируулга"
        }
    }

    var personalizeSubtitle: String {
        switch language {
        case .english: "Pick the look and language that feel right for you."
        case .mongolian: "Өөрт тохирсон харагдах байдал, хэлээ сонгоорой."
        }
    }

    var themeTitle: String {
        switch language {
        case .english: "Theme"
        case .mongolian: "Өнгө төрх"
        }
    }

    var languageTitle: String {
        switch language {
        case .english: "Language"
        case .mongolian: "Хэл"
        }
    }

    var lightMode: String {
        switch language {
        case .english: "Light"
        case .mongolian: "Гэгээтэй"
        }
    }

    var darkMode: String {
        switch language {
        case .english: "Dark"
        case .mongolian: "Харанхуй"
        }
    }

    var englishLanguage: String {
        switch language {
        case .english: "English"
        case .mongolian: "Англи"
        }
    }

    var mongolianLanguage: String {
        switch language {
        case .english: "Mongolian"
        case .mongolian: "Монгол"
        }
    }

    var signInTitle: String {
        switch language {
        case .english: "Sign In"
        case .mongolian: "Нэвтрэх"
        }
    }

    var loginTagline: String {
        switch language {
        case .english: "Your storage, shaped for iPhone."
        case .mongolian: "Таны үүлэн сан iPhone-д зориулан зохион бүтээгдэв."
        }
    }

    var cloudServer: String {
        switch language {
        case .english: "Cloud Server"
        case .mongolian: "Үүлэн сервер"
        }
    }

    var uploadFile: String {
        switch language {
        case .english: "Upload File"
        case .mongolian: "Файл оруулах"
        }
    }

    var uploadPhoto: String {
        switch language {
        case .english: "Upload Photo"
        case .mongolian: "Зураг оруулах"
        }
    }

    var newFolder: String {
        switch language {
        case .english: "New Folder"
        case .mongolian: "Шинэ хавтас"
        }
    }

    var createFolder: String {
        switch language {
        case .english: "Create Folder"
        case .mongolian: "Хавтас үүсгэх"
        }
    }

    var folderName: String {
        switch language {
        case .english: "Folder Name"
        case .mongolian: "Хавтасны нэр"
        }
    }

    var folderNamePlaceholder: String {
        switch language {
        case .english: "Enter folder name"
        case .mongolian: "Хавтасны нэр оруулна уу"
        }
    }

    var folderInfo: String {
        switch language {
        case .english: "Folder Info"
        case .mongolian: "Хавтасны мэдээлэл"
        }
    }

    var fileInfo: String {
        switch language {
        case .english: "File Info"
        case .mongolian: "Файлын мэдээлэл"
        }
    }

    var pathLabel: String {
        switch language {
        case .english: "Path"
        case .mongolian: "Зам"
        }
    }

    var permission: String {
        switch language {
        case .english: "Permission"
        case .mongolian: "Эрх"
        }
    }

    var parentFolder: String {
        switch language {
        case .english: "Parent Folder"
        case .mongolian: "Эцэг хавтас"
        }
    }

    var folderId: String {
        switch language {
        case .english: "Folder ID"
        case .mongolian: "Хавтасны ID"
        }
    }

    var fileId: String {
        switch language {
        case .english: "File ID"
        case .mongolian: "Файлын ID"
        }
    }

    var rootFolder: String {
        switch language {
        case .english: "Root"
        case .mongolian: "Root"
        }
    }

    var username: String {
        switch language {
        case .english: "Username"
        case .mongolian: "Нэвтрэх нэр"
        }
    }

    var password: String {
        switch language {
        case .english: "Password"
        case .mongolian: "Нууц үг"
        }
    }

    var email: String {
        switch language {
        case .english: "Email"
        case .mongolian: "И-мэйл"
        }
    }

    var fullName: String {
        switch language {
        case .english: "Full Name"
        case .mongolian: "Бүтэн нэр"
        }
    }

    var usernamePlaceholder: String {
        switch language {
        case .english: "Enter your username"
        case .mongolian: "Нэвтрэх нэрээ оруулна уу"
        }
    }

    var passwordPlaceholder: String {
        switch language {
        case .english: "Enter your password"
        case .mongolian: "Нууц үгээ оруулна уу"
        }
    }

    var simulatorHelp: String {
        switch language {
        case .english:
            return "For simulator testing, `http://127.0.0.1:8080` works when the backend is running on this Mac. On a physical iPhone, use your Mac's LAN IP instead."
        case .mongolian:
            return "Симулятор дээр туршихдаа backend энэ Mac дээр ажиллаж байвал `http://127.0.0.1:8080` ашиглана. Бодит iPhone дээр бол Mac-ийнхаа дотоод сүлжээний IP-г ашиглана."
        }
    }

    var usernameRequired: String {
        switch language {
        case .english: "Username is required."
        case .mongolian: "Нэвтрэх нэр шаардлагатай."
        }
    }

    var passwordRequired: String {
        switch language {
        case .english: "Password is required."
        case .mongolian: "Нууц үг шаардлагатай."
        }
    }

    func welcomeBack(name: String?) -> String {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedName.isEmpty else {
            switch language {
            case .english: return "Welcome back"
            case .mongolian: return "Тавтай морил"
            }
        }

        switch language {
        case .english:
            return "Welcome back, \(trimmedName)"
        case .mongolian:
            return "Тавтай морил, \(trimmedName)"
        }
    }

    var homeSubtitle: String {
        switch language {
        case .english: "A calmer, native home for your personal cloud."
        case .mongolian: "Таны хувийн үүлэн сангийн тайван, iOS-д нийцсэн нүүр хуудас."
        }
    }

    var quickAccess: String {
        switch language {
        case .english: "Quick Access"
        case .mongolian: "Түргэн хандалт"
        }
    }

    var recentInRoot: String {
        switch language {
        case .english: "Recent In Root"
        case .mongolian: "Root доторх сүүлийн файлууд"
        }
    }

    var seeAll: String {
        switch language {
        case .english: "See All"
        case .mongolian: "Бүгдийг харах"
        }
    }

    var loadingWorkspace: String {
        switch language {
        case .english: "Loading workspace..."
        case .mongolian: "Ажлын орчныг ачаалж байна..."
        }
    }

    var workspaceLoadErrorTitle: String {
        switch language {
        case .english: "Couldn't load your workspace."
        case .mongolian: "Ажлын орчныг ачаалж чадсангүй."
        }
    }

    var emptyRoot: String {
        switch language {
        case .english: "Your root folder is empty for now."
        case .mongolian: "Таны root хавтас одоогоор хоосон байна."
        }
    }

    var home: String {
        switch language {
        case .english: "Home"
        case .mongolian: "Нүүр"
        }
    }

    var starred: String {
        switch language {
        case .english: "Starred"
        case .mongolian: "Одолсон"
        }
    }

    var storage: String {
        switch language {
        case .english: "Storage"
        case .mongolian: "Сан"
        }
    }

    var shared: String {
        switch language {
        case .english: "Shared"
        case .mongolian: "Хуваалцсан"
        }
    }

    var trash: String {
        switch language {
        case .english: "Trash"
        case .mongolian: "Хог"
        }
    }

    var admin: String {
        switch language {
        case .english: "Admin"
        case .mongolian: "Админ"
        }
    }

    var starredSubtitle: String {
        switch language {
        case .english: "Files and folders you star will show up here."
        case .mongolian: "Одолсон файл, хавтаснууд энд харагдана."
        }
    }

    var noStarredItemsTitle: String {
        switch language {
        case .english: "No starred items yet."
        case .mongolian: "Одоогоор одолсон зүйл алга."
        }
    }

    var noStarredItemsSubtitle: String {
        switch language {
        case .english: "Star a file or folder to keep it close at hand."
        case .mongolian: "Файл эсвэл хавтсыг одолж энд хурдан гаргаж ирээрэй."
        }
    }

    var sharedSubtitle: String {
        switch language {
        case .english: "This area is ready for incoming shared folders and files when we hook up the shared resources API."
        case .mongolian: "Хуваалцсан нөөцийн API-г холбоход орж ирсэн файл, хавтаснууд энд гарч ирнэ."
        }
    }

    var trashSubtitle: String {
        switch language {
        case .english: "Trashed files and folders can land here once we connect the trash endpoints."
        case .mongolian: "Хогийн API-г холбоход устгасан файл, хавтаснууд энд харагдана."
        }
    }

    var storageUsage: String {
        switch language {
        case .english: "Storage Usage"
        case .mongolian: "Сан ашиглалт"
        }
    }

    var used: String {
        switch language {
        case .english: "Used"
        case .mongolian: "Ашигласан"
        }
    }

    var limit: String {
        switch language {
        case .english: "Limit"
        case .mongolian: "Дээд хэмжээ"
        }
    }

    var unlimited: String {
        switch language {
        case .english: "Unlimited"
        case .mongolian: "Хязгааргүй"
        }
    }

    var settings: String {
        switch language {
        case .english: "Settings"
        case .mongolian: "Тохиргоо"
        }
    }

    var signOut: String {
        switch language {
        case .english: "Sign Out"
        case .mongolian: "Гарах"
        }
    }

    var profile: String {
        switch language {
        case .english: "Profile"
        case .mongolian: "Профайл"
        }
    }

    var changeProfilePhoto: String {
        switch language {
        case .english: "Change Profile Photo"
        case .mongolian: "Профайлын зураг солих"
        }
    }

    var uploadingPhoto: String {
        switch language {
        case .english: "Uploading Photo..."
        case .mongolian: "Зураг байршуулж байна..."
        }
    }

    var accountAndPreferences: String {
        switch language {
        case .english: "Account and Preferences"
        case .mongolian: "Хэрэглэгч ба тохируулга"
        }
    }

    var server: String {
        switch language {
        case .english: "Server"
        case .mongolian: "Сервер"
        }
    }

    var notes: String {
        switch language {
        case .english: "Notes"
        case .mongolian: "Тэмдэглэл"
        }
    }

    var sort: String {
        switch language {
        case .english: "Sort"
        case .mongolian: "Эрэмбэ"
        }
    }

    var ascending: String {
        switch language {
        case .english: "Ascending"
        case .mongolian: "Өсөх"
        }
    }

    var descending: String {
        switch language {
        case .english: "Descending"
        case .mongolian: "Буурах"
        }
    }

    var newestFirst: String {
        switch language {
        case .english: "Newest First"
        case .mongolian: "Шинэ нь түрүүнд"
        }
    }

    var oldestFirst: String {
        switch language {
        case .english: "Oldest First"
        case .mongolian: "Хуучин нь түрүүнд"
        }
    }

    var foldersFirst: String {
        switch language {
        case .english: "Folders First"
        case .mongolian: "Хавтас түрүүнд"
        }
    }

    var filesFirst: String {
        switch language {
        case .english: "Files First"
        case .mongolian: "Файл түрүүнд"
        }
    }

    var layout: String {
        switch language {
        case .english: "Layout"
        case .mongolian: "Харагдац"
        }
    }

    var guest: String {
        switch language {
        case .english: "Guest"
        case .mongolian: "Зочин"
        }
    }

    var storageSearchPlaceholder: String {
        switch language {
        case .english: "Search in Storage"
        case .mongolian: "Сангаас хайх"
        }
    }

    var entries: String {
        switch language {
        case .english: "Entries"
        case .mongolian: "Файл, хавтас"
        }
    }

    var owner: String {
        switch language {
        case .english: "Owner"
        case .mongolian: "Эзэмшигч"
        }
    }

    var role: String {
        switch language {
        case .english: "Role"
        case .mongolian: "Эрх"
        }
    }

    var status: String {
        switch language {
        case .english: "Status"
        case .mongolian: "Төлөв"
        }
    }

    var createdBy: String {
        switch language {
        case .english: "Created By"
        case .mongolian: "Үүсгэсэн"
        }
    }

    var previewComingSoon: String {
        switch language {
        case .english: "File preview is coming soon."
        case .mongolian: "Файлын preview удахгүй нэмэгдэнэ."
        }
    }

    var fileViewerTodo: String {
        switch language {
        case .english: "TODO: wire the actual file viewer here."
        case .mongolian: "TODO: энд жинхэнэ file viewer-ийг холбоно."
        }
    }

    var starredStatus: String {
        switch language {
        case .english: "Starred"
        case .mongolian: "Одолсон"
        }
    }

    var notStarred: String {
        switch language {
        case .english: "No"
        case .mongolian: "Үгүй"
        }
    }

    var loadingStorage: String {
        switch language {
        case .english: "Loading storage..."
        case .mongolian: "Санг ачаалж байна..."
        }
    }

    var uploadingItemsTitle: String {
        switch language {
        case .english: "Uploading"
        case .mongolian: "Оруулж байна"
        }
    }

    var uploadsCompleteTitle: String {
        switch language {
        case .english: "Uploads Complete"
        case .mongolian: "Оруулалт дууслаа"
        }
    }

    func uploadProgressSummary(current: Int, total: Int) -> String {
        switch language {
        case .english:
            return "\(current) of \(total)"
        case .mongolian:
            return "\(total)-с \(current)"
        }
    }

    func uploadedItemsSummary(_ count: Int) -> String {
        switch language {
        case .english:
            return count == 1 ? "1 item uploaded" : "\(count) items uploaded"
        case .mongolian:
            return "\(count) зүйл амжилттай орлоо"
        }
    }

    var storageLoadErrorTitle: String {
        switch language {
        case .english: "Couldn't Load Storage"
        case .mongolian: "Санг ачаалж чадсангүй"
        }
    }

    var noEntriesTitle: String {
        switch language {
        case .english: "No entries yet."
        case .mongolian: "Одоогоор файл алга."
        }
    }

    var noMatchesTitle: String {
        switch language {
        case .english: "No matches found."
        case .mongolian: "Тохирох зүйл олдсонгүй."
        }
    }

    var noEntriesSubtitle: String {
        switch language {
        case .english: "Upload or create something to bring this screen to life."
        case .mongolian: "Энэ дэлгэцийг дүүргэхийн тулд файл оруулах эсвэл шинээр үүсгээрэй."
        }
    }

    var noMatchesSubtitle: String {
        switch language {
        case .english: "Try a different file or folder name."
        case .mongolian: "Өөр файл эсвэл хавтасны нэрээр оролдоно уу."
        }
    }

    var modifiedLong: String {
        switch language {
        case .english: "Date Modified"
        case .mongolian: "Засварласан огноо"
        }
    }

    var modifiedShort: String {
        switch language {
        case .english: "Modified"
        case .mongolian: "Засвар"
        }
    }

    var name: String {
        switch language {
        case .english: "Name"
        case .mongolian: "Нэр"
        }
    }

    var type: String {
        switch language {
        case .english: "Type"
        case .mongolian: "Төрөл"
        }
    }

    var updatedRecently: String {
        switch language {
        case .english: "Updated recently"
        case .mongolian: "Саяхан шинэчилсэн"
        }
    }

    func modifiedOn(_ date: Date, locale: Locale) -> String {
        let formattedDate = date.formatted(
            .dateTime
                .locale(locale)
                .month(.abbreviated)
                .day()
        )

        switch language {
        case .english:
            return "Modified \(formattedDate)"
        case .mongolian:
            return "\(formattedDate)-нд засварласан"
        }
    }

    var restoringSession: String {
        switch language {
        case .english: "Restoring session..."
        case .mongolian: "Session сэргээж байна..."
        }
    }

    var settingsTitle: String {
        switch language {
        case .english: "Settings"
        case .mongolian: "Тохиргоо"
        }
    }

    var adminUsersTitle: String {
        switch language {
        case .english: "User Management"
        case .mongolian: "Хэрэглэгчийн удирдлага"
        }
    }

    var adminUsersSubtitle: String {
        switch language {
        case .english: "Review the account list, add new users, and keep the workspace tidy."
        case .mongolian: "Хэрэглэгчдийн жагсаалтыг хянаж, шинэ хэрэглэгч нэмээд орчноо цэгцтэй байлгаарай."
        }
    }

    var usersCount: String {
        switch language {
        case .english: "Users"
        case .mongolian: "Хэрэглэгч"
        }
    }

    var adminCount: String {
        switch language {
        case .english: "Admins"
        case .mongolian: "Админууд"
        }
    }

    var addUser: String {
        switch language {
        case .english: "Add User"
        case .mongolian: "Хэрэглэгч нэмэх"
        }
    }

    var addUserSubtitle: String {
        switch language {
        case .english: "Create a new regular account for the workspace."
        case .mongolian: "Ажлын орчинд шинэ энгийн хэрэглэгч үүсгэнэ."
        }
    }

    var loadingUsers: String {
        switch language {
        case .english: "Loading users..."
        case .mongolian: "Хэрэглэгчдийг ачаалж байна..."
        }
    }

    var adminLoadError: String {
        switch language {
        case .english: "Couldn't load users."
        case .mongolian: "Хэрэглэгчдийг ачаалж чадсангүй."
        }
    }

    var noUsersYet: String {
        switch language {
        case .english: "No users are available yet."
        case .mongolian: "Одоогоор хэрэглэгч алга байна."
        }
    }

    var viewDetails: String {
        switch language {
        case .english: "View Details"
        case .mongolian: "Дэлгэрэнгүй"
        }
    }

    var adminUserInfoSection: String {
        switch language {
        case .english: "User Info"
        case .mongolian: "Хэрэглэгчийн мэдээлэл"
        }
    }

    var adminSecuritySection: String {
        switch language {
        case .english: "Security"
        case .mongolian: "Нууцлал"
        }
    }

    var passwordConfirmation: String {
        switch language {
        case .english: "Password Confirmation"
        case .mongolian: "Нууц үг баталгаажуулах"
        }
    }

    var storageQuotaBytesLabel: String {
        switch language {
        case .english: "Storage Quota Bytes"
        case .mongolian: "Сангийн квот (байт)"
        }
    }

    var storageQuotaLabel: String {
        switch language {
        case .english: "Storage Quota"
        case .mongolian: "Сангийн квот"
        }
    }

    var storageQuotaUnit: String {
        switch language {
        case .english: "Unit"
        case .mongolian: "Нэгж"
        }
    }

    var exactBytes: String {
        switch language {
        case .english: "Exact Bytes"
        case .mongolian: "Нийт байт"
        }
    }

    var create: String {
        switch language {
        case .english: "Create"
        case .mongolian: "Үүсгэх"
        }
    }

    var saving: String {
        switch language {
        case .english: "Saving..."
        case .mongolian: "Хадгалж байна..."
        }
    }

    var userDetails: String {
        switch language {
        case .english: "User Details"
        case .mongolian: "Хэрэглэгчийн дэлгэрэнгүй"
        }
    }

    var userMeta: String {
        switch language {
        case .english: "Account Meta"
        case .mongolian: "Профайлын мэдээлэл"
        }
    }

    var createdOn: String {
        switch language {
        case .english: "Created On"
        case .mongolian: "Үүсгэсэн огноо"
        }
    }

    var saveChanges: String {
        switch language {
        case .english: "Save Changes"
        case .mongolian: "Өөрчлөлт хадгалах"
        }
    }

    var deleteUser: String {
        switch language {
        case .english: "Delete User"
        case .mongolian: "Хэрэглэгч устгах"
        }
    }

    var apiBaseURL: String {
        switch language {
        case .english: "API Base URL"
        case .mongolian: "API суурь URL"
        }
    }

    var serverNotes: String {
        switch language {
        case .english: "Use the client server address, for example `http://127.0.0.1:8080` in the simulator or your Mac's LAN IP on a physical iPhone."
        case .mongolian: "Клиентэд ашиглах серверийн хаягийг оруулна уу. Жишээ нь симулятор дээр `http://127.0.0.1:8080`, бодит iPhone дээр Mac-ийнхаа дотоод сүлжээний IP-г ашиглана."
        }
    }

    var save: String {
        switch language {
        case .english: "Save"
        case .mongolian: "Хадгалах"
        }
    }

    var cancel: String {
        switch language {
        case .english: "Cancel"
        case .mongolian: "Болих"
        }
    }
}
