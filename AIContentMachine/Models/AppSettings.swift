import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var themeRaw: String
    var providerModeRaw: String
    var apiKey: String
    var apiEndpoint: String
    var apiModel: String
    var lastExportedAt: Date?

    init(
        id: UUID = UUID(),
        theme: AppThemePreference = .dark,
        providerMode: AIProviderMode = .mock,
        apiKey: String = "",
        apiEndpoint: String = "",
        apiModel: String = "content-engine-v1",
        lastExportedAt: Date? = nil
    ) {
        self.id = id
        self.themeRaw = theme.rawValue
        self.providerModeRaw = providerMode.rawValue
        self.apiKey = apiKey
        self.apiEndpoint = apiEndpoint
        self.apiModel = apiModel
        self.lastExportedAt = lastExportedAt
    }
}

extension AppSettings {
    var theme: AppThemePreference {
        get { AppThemePreference(rawValue: themeRaw) ?? .dark }
        set { themeRaw = newValue.rawValue }
    }

    var providerMode: AIProviderMode {
        get { AIProviderMode(rawValue: providerModeRaw) ?? .mock }
        set { providerModeRaw = newValue.rawValue }
    }

    var snapshot: AppSettingsSnapshot {
        AppSettingsSnapshot(
            theme: themeRaw,
            providerMode: providerModeRaw,
            apiEndpoint: apiEndpoint,
            apiModel: apiModel
        )
    }
}
