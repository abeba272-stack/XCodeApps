import Foundation
import SwiftData

@MainActor
final class TemplatesViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var errorMessage: String?

    func filteredTemplates(from templates: [TemplateModel]) -> [TemplateModel] {
        let filtered: [TemplateModel]

        if searchText.isEmpty {
            filtered = templates
        } else {
            filtered = templates.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.templateDescription.localizedCaseInsensitiveContains(searchText)
                || $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.name < $1.name
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    func toggleFavorite(template: TemplateModel, context: ModelContext) {
        template.isFavorite.toggle()
        do {
            try context.save()
        } catch {
            template.isFavorite.toggle()
            errorMessage = "The template favorite state could not be saved right now."
        }
    }
}
