import Foundation
import SwiftData

@MainActor
final class TemplatesViewModel: ObservableObject {
    @Published var searchText: String = ""

    func filteredTemplates(from templates: [TemplateModel]) -> [TemplateModel] {
        guard !searchText.isEmpty else { return templates.sorted { $0.name < $1.name } }
        return templates.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.templateDescription.localizedCaseInsensitiveContains(searchText)
                || $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    func toggleFavorite(template: TemplateModel, context: ModelContext) {
        template.isFavorite.toggle()
        try? context.save()
    }
}
