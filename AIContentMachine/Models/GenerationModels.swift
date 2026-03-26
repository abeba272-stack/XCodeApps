import Foundation

struct GenerationRequest: Hashable {
    var topic: String
    var platform: ContentPlatform
    var category: String
    var audience: String
    var tone: ContentTone
    var language: ContentLanguage
    var goal: ContentGoal
    var style: ContentStyle
    var durationSeconds: Int
    var mode: GenerationMode
    var templateName: String?
    var templateDescription: String?
    var templateRules: [String]

    init(
        topic: String,
        platform: ContentPlatform,
        category: String,
        audience: String,
        tone: ContentTone,
        language: ContentLanguage,
        goal: ContentGoal,
        style: ContentStyle,
        durationSeconds: Int,
        mode: GenerationMode,
        template: TemplateModel? = nil
    ) {
        self.topic = topic
        self.platform = platform
        self.category = category
        self.audience = audience
        self.tone = tone
        self.language = language
        self.goal = goal
        self.style = style
        self.durationSeconds = durationSeconds
        self.mode = mode
        self.templateName = template?.name
        self.templateDescription = template?.templateDescription
        self.templateRules = template?.structureRules ?? []
    }

    var durationLabel: String {
        "\(durationSeconds)s"
    }
}

struct GeneratedContent: Codable, Hashable {
    var title: String
    var topic: String
    var contentAngle: String
    var audienceSummary: String
    var overview: String
    var hook: String
    var alternateHooks: [String]
    var script: String
    var voiceover: String
    var caption: String
    var hashtags: [String]
    var cta: String
    var shotList: [String]
    var notes: String
    var performanceRationale: String
    var bestPostingTime: String
    var emotionalTrigger: String
    var templateUsed: String?
    var batchIdeas: [String]
    var thumbnailSuggestions: [String]
    var postingChecklist: [String]
    var postingTip: String
    var status: ProjectStatus
    var score: Int
}

struct ExportBundle: Codable {
    var profile: UserProfileSnapshot
    var settings: AppSettingsSnapshot
    var projects: [ContentProjectSnapshot]
    var assignments: [PlannerAssignmentSnapshot]
    var exportedAt: Date
}

struct UserProfileSnapshot: Codable {
    var selectedNiches: [String]
    var preferredPlatforms: [String]
    var preferredLanguage: String
    var preferredTone: String
    var goals: [String]
    var postingFrequency: Int
    var onboardingCompleted: Bool
}

struct AppSettingsSnapshot: Codable {
    var theme: String
    var providerMode: String
    var apiEndpoint: String
    var apiModel: String
}

struct ContentProjectSnapshot: Codable {
    var id: UUID
    var title: String
    var topic: String
    var category: String
    var platform: String
    var status: String
    var score: Int
}

struct PlannerAssignmentSnapshot: Codable {
    var id: UUID
    var date: Date
    var projectID: UUID?
    var projectTitle: String
    var status: String
    var isPosted: Bool
}
