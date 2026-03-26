import SwiftUI

enum AppTheme {
    static let background = LinearGradient(
        colors: [
            Color(hex: "#06070B"),
            Color(hex: "#0A0E16"),
            Color(hex: "#101523"),
            Color(hex: "#151525")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            Color(hex: "#141A28").opacity(0.96),
            Color(hex: "#1C2332").opacity(0.92)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [
            Color(hex: "#77E2FF"),
            Color(hex: "#6A8EFF"),
            Color(hex: "#7E74FF")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [
            Color(hex: "#64F3C1"),
            Color(hex: "#3DC999")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGlow = Color(hex: "#7BDFFF")
    static let accentSecondary = Color(hex: "#8E82FF")
    static let success = Color(hex: "#64F3C1")
    static let warning = Color(hex: "#FFB86A")
    static let danger = Color(hex: "#FF7A8A")

    static let surface = Color(hex: "#111723")
    static let surfaceSecondary = Color(hex: "#1A2230")
    static let surfaceTertiary = Color(hex: "#243045")
    static let surfaceMuted = Color(hex: "#10141E").opacity(0.78)
    static let border = Color.white.opacity(0.08)
    static let borderStrong = Color.white.opacity(0.14)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.78)
    static let textMuted = Color.white.opacity(0.54)
    static let shadow = Color.black.opacity(0.34)

    static let radiusLarge: CGFloat = 28
    static let radiusMedium: CGFloat = 22
    static let radiusSmall: CGFloat = 18
    static let screenPadding: CGFloat = 20
}

final class ThemeManager: ObservableObject {
    @Published var preference: AppThemePreference = .dark

    var colorScheme: ColorScheme? {
        switch preference {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }

    func update(using settings: AppSettings?) {
        preference = settings?.theme ?? .dark
    }
}

extension Color {
    init(hex: String) {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch sanitized.count {
        case 8:
            a = (int >> 24) & 0xFF
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            a = 255
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func premiumCardStyle() -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous)
                    .fill(AppTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.06),
                                        Color.clear,
                                        Color.black.opacity(0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow, radius: 22, x: 0, y: 14)
    }

    func premiumInputStyle() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                    .fill(AppTheme.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(Color.black.opacity(configuration.isPressed ? 0.8 : 0.96))
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                    .fill(AppTheme.accentGradient)
                    .opacity(configuration.isPressed ? 0.88 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.smooth(duration: 0.16), value: configuration.isPressed)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary.opacity(configuration.isPressed ? 0.72 : 1))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                    .fill(AppTheme.surfaceSecondary.opacity(configuration.isPressed ? 0.76 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.smooth(duration: 0.16), value: configuration.isPressed)
    }
}

struct AppQuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textSecondary.opacity(configuration.isPressed ? 0.72 : 1))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.surfaceMuted.opacity(configuration.isPressed ? 0.8 : 1))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.smooth(duration: 0.16), value: configuration.isPressed)
    }
}
