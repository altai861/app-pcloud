import SwiftUI
import UIKit

private extension Color {
    static func appDynamic(light: UIColor, dark: UIColor) -> Color {
        Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}

enum AppPalette {
    static let backgroundTop = Color.appDynamic(
        light: UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1),
        dark: UIColor(red: 0.07, green: 0.11, blue: 0.16, alpha: 1)
    )
    static let backgroundBottom = Color.appDynamic(
        light: UIColor(red: 0.89, green: 0.95, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.03, green: 0.06, blue: 0.1, alpha: 1)
    )
    static let card = Color.appDynamic(
        light: UIColor(red: 1, green: 1, blue: 1, alpha: 0.82),
        dark: UIColor(red: 0.12, green: 0.16, blue: 0.21, alpha: 0.86)
    )
    static let cardStrong = Color.appDynamic(
        light: UIColor(red: 1, green: 1, blue: 1, alpha: 0.94),
        dark: UIColor(red: 0.16, green: 0.2, blue: 0.26, alpha: 0.94)
    )
    static let stroke = Color.appDynamic(
        light: UIColor(red: 0, green: 0, blue: 0, alpha: 0.08),
        dark: UIColor(red: 1, green: 1, blue: 1, alpha: 0.08)
    )
    static let shadow = Color.appDynamic(
        light: UIColor(red: 0, green: 0, blue: 0, alpha: 0.08),
        dark: UIColor(red: 0, green: 0, blue: 0, alpha: 0.26)
    )
    static let textPrimary = Color.appDynamic(
        light: UIColor(red: 0.13, green: 0.17, blue: 0.21, alpha: 1),
        dark: UIColor(red: 0.93, green: 0.96, blue: 0.99, alpha: 1)
    )
    static let textSecondary = Color.appDynamic(
        light: UIColor(red: 0.38, green: 0.45, blue: 0.5, alpha: 1),
        dark: UIColor(red: 0.65, green: 0.72, blue: 0.78, alpha: 1)
    )
    static let accent = Color(red: 0.13, green: 0.84, blue: 0.73)
    static let accentDeep = Color(red: 0.07, green: 0.67, blue: 0.6)
    static let softBlue = Color.appDynamic(
        light: UIColor(red: 0.78, green: 0.91, blue: 1.0, alpha: 1),
        dark: UIColor(red: 0.12, green: 0.3, blue: 0.43, alpha: 1)
    )
    static let softBlueDeep = Color.appDynamic(
        light: UIColor(red: 0.42, green: 0.72, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.56, green: 0.79, blue: 1.0, alpha: 1)
    )
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(AppPalette.accent.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 24)
                .offset(x: 110, y: -240)

            Circle()
                .fill(AppPalette.softBlueDeep.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 28)
                .offset(x: -130, y: 260)
        }
    }
}

struct AppCardModifier: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppPalette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppPalette.stroke, lineWidth: 1)
            )
            .shadow(color: AppPalette.shadow, radius: 18, x: 0, y: 12)
    }
}

extension View {
    func appCard(padding: CGFloat = 18) -> some View {
        modifier(AppCardModifier(padding: padding))
    }
}

struct PrimaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppPalette.textPrimary)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [AppPalette.accent, AppPalette.accentDeep],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: AppPalette.accent.opacity(configuration.isPressed ? 0.12 : 0.28),
                radius: configuration.isPressed ? 6 : 14,
                x: 0,
                y: configuration.isPressed ? 3 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
