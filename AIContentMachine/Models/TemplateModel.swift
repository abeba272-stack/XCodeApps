import Foundation
import SwiftData

@Model
final class TemplateModel {
    @Attribute(.unique) var id: UUID = UUID()
    var seedKey: String = ""
    var name: String = ""
    var templateDescription: String = ""
    var category: String = ""
    var exampleHook: String = ""
    private var structureRulesData: Data = Data()
    private var idealPlatformsData: Data = Data()
    var recommendedToneRaw: String = ContentTone.direct.rawValue
    var recommendedGoalRaw: String = ContentGoal.views.rawValue
    var recommendedStyleRaw: String = ContentStyle.educational.rawValue
    var blueprint: String = ""
    var exampleScriptDirection: String = ""
    var exampleCaptionDirection: String = ""
    var tierRaw: String = TemplateAccessTier.free.rawValue
    var isStarterTemplate: Bool = true
    var sortOrder: Int = 0
    var isFavorite: Bool = false

    init(
        id: UUID = UUID(),
        seedKey: String = "",
        name: String,
        description: String,
        category: String,
        exampleHook: String,
        structureRules: [String],
        idealPlatforms: [ContentPlatform] = [.tiktok],
        recommendedTone: ContentTone = .direct,
        recommendedGoal: ContentGoal = .views,
        recommendedStyle: ContentStyle = .educational,
        blueprint: String = "",
        exampleScriptDirection: String = "",
        exampleCaptionDirection: String = "",
        tier: TemplateAccessTier = .free,
        isStarterTemplate: Bool = true,
        sortOrder: Int = 0,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.seedKey = seedKey
        self.name = name
        self.templateDescription = description
        self.category = category
        self.exampleHook = exampleHook
        self.structureRulesData = StringListStorage.encode(structureRules)
        self.idealPlatformsData = StringListStorage.encode(idealPlatforms.map(\.rawValue))
        self.recommendedToneRaw = recommendedTone.rawValue
        self.recommendedGoalRaw = recommendedGoal.rawValue
        self.recommendedStyleRaw = recommendedStyle.rawValue
        self.blueprint = blueprint
        self.exampleScriptDirection = exampleScriptDirection
        self.exampleCaptionDirection = exampleCaptionDirection
        self.tierRaw = tier.rawValue
        self.isStarterTemplate = isStarterTemplate
        self.sortOrder = sortOrder
        self.isFavorite = isFavorite
    }
}

extension TemplateModel {
    var structureRules: [String] {
        get { StringListStorage.decode(structureRulesData) }
        set { structureRulesData = StringListStorage.encode(newValue) }
    }

    var idealPlatforms: [ContentPlatform] {
        get {
            StringListStorage.decode(idealPlatformsData)
                .compactMap(ContentPlatform.init(rawValue:))
        }
        set {
            idealPlatformsData = StringListStorage.encode(newValue.map(\.rawValue))
        }
    }

    var recommendedTone: ContentTone {
        get { ContentTone(rawValue: recommendedToneRaw) ?? .direct }
        set { recommendedToneRaw = newValue.rawValue }
    }

    var recommendedGoal: ContentGoal {
        get { ContentGoal(rawValue: recommendedGoalRaw) ?? .views }
        set { recommendedGoalRaw = newValue.rawValue }
    }

    var recommendedStyle: ContentStyle {
        get { ContentStyle(rawValue: recommendedStyleRaw) ?? .educational }
        set { recommendedStyleRaw = newValue.rawValue }
    }

    var tier: TemplateAccessTier {
        get { TemplateAccessTier(rawValue: tierRaw) ?? .free }
        set { tierRaw = newValue.rawValue }
    }

    var isPro: Bool {
        tier == .pro
    }

    var accessLabel: String {
        tier.rawValue
    }

    func applyStarterContent(from template: TemplateModel) {
        seedKey = template.seedKey
        name = template.name
        templateDescription = template.templateDescription
        category = template.category
        exampleHook = template.exampleHook
        structureRules = template.structureRules
        idealPlatforms = template.idealPlatforms
        recommendedTone = template.recommendedTone
        recommendedGoal = template.recommendedGoal
        recommendedStyle = template.recommendedStyle
        blueprint = template.blueprint
        exampleScriptDirection = template.exampleScriptDirection
        exampleCaptionDirection = template.exampleCaptionDirection
        tier = template.tier
        isStarterTemplate = template.isStarterTemplate
        sortOrder = template.sortOrder
    }
}
