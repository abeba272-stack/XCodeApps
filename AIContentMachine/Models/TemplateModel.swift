import Foundation
import SwiftData

@Model
final class TemplateModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var templateDescription: String
    var category: String
    var exampleHook: String
    private var structureRulesData: Data
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: String,
        exampleHook: String,
        structureRules: [String],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.templateDescription = description
        self.category = category
        self.exampleHook = exampleHook
        self.structureRulesData = StringListStorage.encode(structureRules)
        self.isFavorite = isFavorite
    }
}

extension TemplateModel {
    var structureRules: [String] {
        get { StringListStorage.decode(structureRulesData) }
        set { structureRulesData = StringListStorage.encode(newValue) }
    }
}
