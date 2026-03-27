import Foundation
import SwiftData

@MainActor
enum TemplateSeedService {
    static func seedStarterTemplates(in context: ModelContext, settings: AppSettings) {
        let starterTemplates = TemplateEngine.makeDefaultTemplates()

        guard settings.starterTemplateSeedVersion < FeatureAccessPolicy.starterTemplateSeedVersion else {
            return
        }

        let fetchDescriptor = FetchDescriptor<TemplateModel>()
        let existingTemplates = (try? context.fetch(fetchDescriptor)) ?? []

        for starter in starterTemplates {
            if let existing = existingTemplates.first(where: { matchesStarterTemplate($0, starter: starter) }) {
                let favorite = existing.isFavorite
                existing.applyStarterContent(from: starter)
                existing.isFavorite = favorite
            } else {
                context.insert(starter)
            }
        }

        settings.starterTemplateSeedVersion = FeatureAccessPolicy.starterTemplateSeedVersion
    }

    private static func matchesStarterTemplate(_ existing: TemplateModel, starter: TemplateModel) -> Bool {
        if !existing.seedKey.isEmpty, existing.seedKey == starter.seedKey {
            return true
        }

        return normalized(existing.name) == normalized(starter.name)
    }

    private static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
