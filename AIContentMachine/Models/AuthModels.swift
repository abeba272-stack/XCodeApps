import Foundation

enum SubscriptionPlan: String, Codable, CaseIterable, Identifiable {
    case standard
    case pro

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .pro:
            return "Pro"
        }
    }
}

enum AuthProvider: String, Codable, CaseIterable, Identifiable {
    case email
    case apple
    case google
    case special
    case deviceMigration

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .email:
            return "Email"
        case .apple:
            return "Apple"
        case .google:
            return "Google"
        case .special:
            return "Email"
        case .deviceMigration:
            return "Local"
        }
    }
}

struct GoogleIdentityConfiguration {
    static let clientID = ""
    static let callbackScheme = ""

    static var isConfigured: Bool {
        !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !callbackScheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct AuthProviderAvailability {
    // Keep third-party sign-in off in local builds until the external setup is complete.
    static let appleSignInEnabled = false

    static var googleSignInEnabled: Bool {
        GoogleIdentityConfiguration.isConfigured
    }
}

#if DEBUG
struct AuthConstants {
    static let specialProEmail = "abeba272@icloud.com"
    static let specialProPassword = "1900Ai+Gmg"
}
#endif
