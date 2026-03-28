import Foundation
import SwiftData

@MainActor
protocol LanguageService: AnyObject {
    func currentAppLanguage(settings: AppSettings?) -> AppLanguage
    func saveAppLanguage(_ language: AppLanguage, in settings: AppSettings) throws
    func preferredAccountLanguage(for profile: UserProfile) -> PreferredAccountLanguage
    func systemAppLanguage(locale: Locale) -> AppLanguage
}

@MainActor
final class DefaultLanguageService: LanguageService {
    private let modelContainer: ModelContainer
    private let logger: any AppLogger

    init(modelContainer: ModelContainer, logger: any AppLogger) {
        self.modelContainer = modelContainer
        self.logger = logger
    }

    func currentAppLanguage(settings: AppSettings?) -> AppLanguage {
        settings?.appLanguage ?? systemAppLanguage(locale: .current)
    }

    func saveAppLanguage(_ language: AppLanguage, in settings: AppSettings) throws {
        settings.appLanguage = language

        do {
            try modelContainer.mainContext.save()
        } catch {
            logger.error("Saving app language failed: \(error.localizedDescription)", category: "LanguageService")
            throw AppError.settings("The app language could not be saved.")
        }
    }

    func preferredAccountLanguage(for profile: UserProfile) -> PreferredAccountLanguage {
        profile.preferredAccountLanguage
    }

    func systemAppLanguage(locale: Locale = .current) -> AppLanguage {
        AppLanguage.systemDefault(locale: locale)
    }
}
