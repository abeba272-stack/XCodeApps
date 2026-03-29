import Foundation
import SwiftData

@Model
final class AppSettings {
    static let defaultLocalServerEndpoint = "http://localhost:11434/api/generate"

    @Attribute(.unique) var id: UUID = UUID()
    var appLanguageRaw: String = ""
    var themeRaw: String = AppThemePreference.dark.rawValue
    var providerModeRaw: String = AIProviderMode.mock.rawValue
    var apiKey: String = ""
    var apiEndpoint: String = ""
    var apiModel: String = "content-engine-v1"
    var starterTemplateSeedVersion: Int = 0
    var generationWindowStartedAt: Date?
    var freeGenerationCountInWindow: Int = 0
    var lastExportedAt: Date?
    var currentUserID: UUID?

    init(
        id: UUID = UUID(),
        appLanguage: AppLanguage? = nil,
        theme: AppThemePreference = .dark,
        providerMode: AIProviderMode = .mock,
        apiKey: String = "",
        apiEndpoint: String = "",
        apiModel: String = "content-engine-v1",
        starterTemplateSeedVersion: Int = 0,
        generationWindowStartedAt: Date? = nil,
        freeGenerationCountInWindow: Int = 0,
        lastExportedAt: Date? = nil,
        currentUserID: UUID? = nil
    ) {
        self.id = id
        self.appLanguageRaw = appLanguage?.rawValue ?? ""
        self.themeRaw = theme.rawValue
        self.providerModeRaw = providerMode.rawValue
        self.apiKey = apiKey
        self.apiEndpoint = apiEndpoint
        self.apiModel = apiModel
        self.starterTemplateSeedVersion = starterTemplateSeedVersion
        self.generationWindowStartedAt = generationWindowStartedAt
        self.freeGenerationCountInWindow = freeGenerationCountInWindow
        self.lastExportedAt = lastExportedAt
        self.currentUserID = currentUserID
    }
}

extension AppSettings {
    static func endpointURL(from value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }

        guard let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = url.host,
              !host.isEmpty else {
            return nil
        }

        return url
    }

    var appLanguage: AppLanguage {
        get { AppLanguage(rawValue: appLanguageRaw) ?? AppLanguage.systemDefault() }
        set { appLanguageRaw = newValue.rawValue }
    }

    var theme: AppThemePreference {
        get { AppThemePreference(rawValue: themeRaw) ?? .dark }
        set { themeRaw = newValue.rawValue }
    }

    var providerMode: AIProviderMode {
        get { AIProviderMode(rawValue: providerModeRaw) ?? .mock }
        set { providerModeRaw = newValue.rawValue }
    }

    var localServerEndpoint: String {
        get {
            let trimmed = apiEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? Self.defaultLocalServerEndpoint : trimmed
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            apiEndpoint = trimmed.isEmpty ? Self.defaultLocalServerEndpoint : trimmed
        }
    }

    var localServerURL: URL? {
        Self.endpointURL(from: localServerEndpoint)
    }

    var snapshot: AppSettingsSnapshot {
        AppSettingsSnapshot(
            theme: themeRaw,
            providerMode: providerModeRaw,
            apiEndpoint: localServerEndpoint,
            apiModel: apiModel
        )
    }
}

enum AppExternalLinks {
    private static let manageSubscriptionsValue = "https://apps.apple.com/account/subscriptions"
    private static let termsValue = "https://abeba272-stack.github.io/XCodeApps/terms.html"
    private static let privacyValue = "https://abeba272-stack.github.io/XCodeApps/privacy.html"
    private static let supportValue = "mailto:sundermannabeba@gmail.com"

    static var manageSubscriptionsURL: URL? {
        safeURL(from: manageSubscriptionsValue, allowedSchemes: ["http", "https"])
    }

    static var termsURL: URL? {
        safeURL(from: termsValue, allowedSchemes: ["http", "https"])
    }

    static var privacyURL: URL? {
        safeURL(from: privacyValue, allowedSchemes: ["http", "https"])
    }

    static var supportURL: URL? {
        safeURL(from: supportValue, allowedSchemes: ["mailto"])
    }

    private static func safeURL(from value: String, allowedSchemes: Set<String>) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              allowedSchemes.contains(scheme) else {
            return nil
        }

        switch scheme {
        case "http", "https":
            guard let host = components.host, !host.isEmpty else { return nil }
        case "mailto":
            guard !components.path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        default:
            return nil
        }

        return components.url
    }
}
