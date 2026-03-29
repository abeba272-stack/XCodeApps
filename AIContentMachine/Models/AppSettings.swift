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
        URL(string: localServerEndpoint)
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
