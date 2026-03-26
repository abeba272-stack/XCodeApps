import Foundation
import SwiftData

@Model
final class ContentProject {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var topic: String
    var category: String
    var platformRaw: String
    var audience: String
    var toneRaw: String
    var languageRaw: String
    var goalRaw: String
    var styleRaw: String
    var durationSeconds: Int
    var generationModeRaw: String
    var statusRaw: String
    var isFavorite: Bool
    var contentAngle: String
    var audienceSummary: String
    var overview: String
    var hook: String
    private var alternateHooksData: Data
    var script: String
    var voiceover: String
    var caption: String
    private var hashtagsData: Data
    var cta: String
    private var shotListData: Data
    var notes: String
    var performanceRationale: String
    var bestPostingTime: String
    var emotionalTrigger: String
    var templateUsed: String?
    private var batchIdeasData: Data
    private var thumbnailSuggestionsData: Data
    private var postingChecklistData: Data
    var postingTip: String
    var contentScore: Int

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        title: String,
        topic: String,
        category: String,
        platform: ContentPlatform,
        audience: String,
        tone: ContentTone,
        language: ContentLanguage,
        goal: ContentGoal,
        style: ContentStyle,
        durationSeconds: Int,
        generationMode: GenerationMode,
        status: ProjectStatus = .draft,
        isFavorite: Bool = false,
        contentAngle: String,
        audienceSummary: String,
        overview: String,
        hook: String,
        alternateHooks: [String],
        script: String,
        voiceover: String,
        caption: String,
        hashtags: [String],
        cta: String,
        shotList: [String],
        notes: String,
        performanceRationale: String,
        bestPostingTime: String,
        emotionalTrigger: String,
        templateUsed: String?,
        batchIdeas: [String],
        thumbnailSuggestions: [String],
        postingChecklist: [String],
        postingTip: String,
        contentScore: Int
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.topic = topic
        self.category = category
        self.platformRaw = platform.rawValue
        self.audience = audience
        self.toneRaw = tone.rawValue
        self.languageRaw = language.rawValue
        self.goalRaw = goal.rawValue
        self.styleRaw = style.rawValue
        self.durationSeconds = durationSeconds
        self.generationModeRaw = generationMode.rawValue
        self.statusRaw = status.rawValue
        self.isFavorite = isFavorite
        self.contentAngle = contentAngle
        self.audienceSummary = audienceSummary
        self.overview = overview
        self.hook = hook
        self.alternateHooksData = StringListStorage.encode(alternateHooks)
        self.script = script
        self.voiceover = voiceover
        self.caption = caption
        self.hashtagsData = StringListStorage.encode(hashtags)
        self.cta = cta
        self.shotListData = StringListStorage.encode(shotList)
        self.notes = notes
        self.performanceRationale = performanceRationale
        self.bestPostingTime = bestPostingTime
        self.emotionalTrigger = emotionalTrigger
        self.templateUsed = templateUsed
        self.batchIdeasData = StringListStorage.encode(batchIdeas)
        self.thumbnailSuggestionsData = StringListStorage.encode(thumbnailSuggestions)
        self.postingChecklistData = StringListStorage.encode(postingChecklist)
        self.postingTip = postingTip
        self.contentScore = contentScore
    }
}

extension ContentProject {
    var alternateHooks: [String] {
        get { StringListStorage.decode(alternateHooksData) }
        set { alternateHooksData = StringListStorage.encode(newValue) }
    }

    var hashtags: [String] {
        get { StringListStorage.decode(hashtagsData) }
        set { hashtagsData = StringListStorage.encode(newValue) }
    }

    var shotList: [String] {
        get { StringListStorage.decode(shotListData) }
        set { shotListData = StringListStorage.encode(newValue) }
    }

    var batchIdeas: [String] {
        get { StringListStorage.decode(batchIdeasData) }
        set { batchIdeasData = StringListStorage.encode(newValue) }
    }

    var thumbnailSuggestions: [String] {
        get { StringListStorage.decode(thumbnailSuggestionsData) }
        set { thumbnailSuggestionsData = StringListStorage.encode(newValue) }
    }

    var postingChecklist: [String] {
        get { StringListStorage.decode(postingChecklistData) }
        set { postingChecklistData = StringListStorage.encode(newValue) }
    }

    var platform: ContentPlatform {
        get { ContentPlatform(rawValue: platformRaw) ?? .tiktok }
        set { platformRaw = newValue.rawValue }
    }

    var tone: ContentTone {
        get { ContentTone(rawValue: toneRaw) ?? .direct }
        set { toneRaw = newValue.rawValue }
    }

    var language: ContentLanguage {
        get { ContentLanguage(rawValue: languageRaw) ?? .english }
        set { languageRaw = newValue.rawValue }
    }

    var goal: ContentGoal {
        get { ContentGoal(rawValue: goalRaw) ?? .views }
        set { goalRaw = newValue.rawValue }
    }

    var style: ContentStyle {
        get { ContentStyle(rawValue: styleRaw) ?? .educational }
        set { styleRaw = newValue.rawValue }
    }

    var generationMode: GenerationMode {
        get { GenerationMode(rawValue: generationModeRaw) ?? .fullPackage }
        set { generationModeRaw = newValue.rawValue }
    }

    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var durationLabel: String {
        "\(durationSeconds)s"
    }

    func apply(_ generated: GeneratedContent) {
        updatedAt = .now
        title = generated.title
        contentAngle = generated.contentAngle
        audienceSummary = generated.audienceSummary
        overview = generated.overview
        hook = generated.hook
        alternateHooks = generated.alternateHooks
        script = generated.script
        voiceover = generated.voiceover
        caption = generated.caption
        hashtags = generated.hashtags
        cta = generated.cta
        shotList = generated.shotList
        notes = generated.notes
        performanceRationale = generated.performanceRationale
        bestPostingTime = generated.bestPostingTime
        emotionalTrigger = generated.emotionalTrigger
        templateUsed = generated.templateUsed
        batchIdeas = generated.batchIdeas
        thumbnailSuggestions = generated.thumbnailSuggestions
        postingChecklist = generated.postingChecklist
        postingTip = generated.postingTip
        contentScore = generated.score
        status = generated.status
    }

    var snapshot: ContentProjectSnapshot {
        ContentProjectSnapshot(
            id: id,
            title: title,
            topic: topic,
            category: category,
            platform: platform.rawValue,
            status: status.rawValue,
            score: contentScore
        )
    }
}

extension ContentProject {
    static func from(request: GenerationRequest, generated: GeneratedContent) -> ContentProject {
        ContentProject(
            title: generated.title,
            topic: request.topic,
            category: request.category,
            platform: request.platform,
            audience: request.audience,
            tone: request.tone,
            language: request.language,
            goal: request.goal,
            style: request.style,
            durationSeconds: request.durationSeconds,
            generationMode: request.mode,
            status: generated.status,
            contentAngle: generated.contentAngle,
            audienceSummary: generated.audienceSummary,
            overview: generated.overview,
            hook: generated.hook,
            alternateHooks: generated.alternateHooks,
            script: generated.script,
            voiceover: generated.voiceover,
            caption: generated.caption,
            hashtags: generated.hashtags,
            cta: generated.cta,
            shotList: generated.shotList,
            notes: generated.notes,
            performanceRationale: generated.performanceRationale,
            bestPostingTime: generated.bestPostingTime,
            emotionalTrigger: generated.emotionalTrigger,
            templateUsed: generated.templateUsed,
            batchIdeas: generated.batchIdeas,
            thumbnailSuggestions: generated.thumbnailSuggestions,
            postingChecklist: generated.postingChecklist,
            postingTip: generated.postingTip,
            contentScore: generated.score
        )
    }
}
