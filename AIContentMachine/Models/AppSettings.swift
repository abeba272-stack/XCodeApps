import Foundation
import SwiftData

@Model
final class AppSettings {
    static let defaultLocalServerEndpoint = "http://192.168.1.23:3000/chat"

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
