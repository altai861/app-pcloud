import SwiftUI

struct QuickPreferencesCard: View {
    var body: some View {
        HStack(spacing: 12) {
            ThemePreferenceToggle()
            LanguagePreferenceToggle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 12)
    }
}

struct ThemePreferenceToggle: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                settingsStore.updateThemePreference(nextTheme)
            }
        } label: {
            Image(systemName: currentThemeSystemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppPalette.softBlue)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppPalette.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(settingsStore.strings.themeTitle)
        .accessibilityValue(currentThemeAccessibilityValue)
    }

    private var nextTheme: AppThemePreference {
        settingsStore.themePreference == .light ? .dark : .light
    }

    private var currentThemeSystemImage: String {
        settingsStore.themePreference == .light ? "sun.max.fill" : "moon.fill"
    }

    private var currentThemeAccessibilityValue: String {
        settingsStore.themePreference == .light
            ? settingsStore.strings.lightMode
            : settingsStore.strings.darkMode
    }
}

struct LanguagePreferenceToggle: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                settingsStore.updateAppLanguage(nextLanguage)
            }
        } label: {
            Text(currentFlag)
                .font(.system(size: 20))
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppPalette.cardStrong)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppPalette.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(settingsStore.strings.languageTitle)
        .accessibilityValue(currentLanguageAccessibilityValue)
    }

    private var nextLanguage: AppLanguage {
        settingsStore.appLanguage == .mongolian ? .english : .mongolian
    }

    private var currentFlag: String {
        settingsStore.appLanguage == .mongolian ? "🇲🇳" : "🇬🇧"
    }

    private var currentLanguageAccessibilityValue: String {
        settingsStore.appLanguage == .mongolian
            ? settingsStore.strings.mongolianLanguage
            : settingsStore.strings.englishLanguage
    }
}
