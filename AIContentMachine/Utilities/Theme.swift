import SwiftUI

enum AppTheme {
    static let background = LinearGradient(
        colors: [
            Color(hex: "#0A0B11"),
            Color(hex: "#10131D"),
            Color(hex: "#161425")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            Color(hex: "#171B27"),
            Color(hex: "#1D2230")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [
            Color(hex: "#66D7FF"),
            Color(hex: "#6385FF"),
            Color(hex: "#9C6EFF")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGlow = Color(hex: "#75D8FF")
    static let surface = Color(hex: "#121722")
    static let surfaceSecondary = Color(hex: "#1B2131")
    static let border = Color.white.opacity(0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let textMuted = Color.white.opacity(0.52)
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
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppTheme.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.24), radius: 18, x: 0, y: 10)
    }
}
