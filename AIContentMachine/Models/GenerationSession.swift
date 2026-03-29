import Foundation
import Observation

@Observable
final class GenerationSession {
    let id: UUID
    var savedProjectID: UUID?
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var topic: String
    var category: String
    var platform: ContentPlatform
    var audience: String
    var tone: ContentTone
    var language: ContentLanguage
    var goal: ContentGoal
    var style: ContentStyle
    var durationSeconds: Int
    var generationMode: GenerationMode
    var status: ProjectStatus
    var isFavorite: Bool
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
    var contentScore: Int
    var generationOrigin: GenerationOrigin
    var hasSavedDraft: Bool

    init(
        id: UUID = UUID(),
        savedProjectID: UUID? = nil,
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
        status: ProjectStatus,
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
        contentScore: Int,
        generationOrigin: GenerationOrigin = .fallback,
        hasSavedDraft: Bool = false
    ) {
        self.id = id
        self.savedProjectID = savedProjectID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.topic = topic
        self.category = category
        self.platform = platform
        self.audience = audience
        self.tone = tone
        self.language = language
        self.goal = goal
        self.style = style
        self.durationSeconds = durationSeconds
        self.generationMode = generationMode
        self.status = status
        self.isFavorite = isFavorite
        self.contentAngle = contentAngle
        self.audienceSummary = audienceSummary
        self.overview = overview
        self.hook = hook
        self.alternateHooks = alternateHooks
        self.script = script
        self.voiceover = voiceover
        self.caption = caption
        self.hashtags = hashtags
        self.cta = cta
        self.shotList = shotList
        self.notes = notes
        self.performanceRationale = performanceRationale
        self.bestPostingTime = bestPostingTime
        self.emotionalTrigger = emotionalTrigger
        self.templateUsed = templateUsed
        self.batchIdeas = batchIdeas
        self.thumbnailSuggestions = thumbnailSuggestions
        self.postingChecklist = postingChecklist
        self.postingTip = postingTip
        self.contentScore = contentScore
        self.generationOrigin = generationOrigin
        self.hasSavedDraft = hasSavedDraft
    }

    var durationLabel: String {
        "\(durationSeconds)s"
    }

    func apply(request: GenerationRequest, generated: GeneratedContent) {
        updatedAt = .now
        topic = request.topic
        category = request.category
        platform = request.platform
        audience = request.audience
        tone = request.tone
        language = request.language
        goal = request.goal
        style = request.style
        durationSeconds = request.durationSeconds
        generationMode = request.mode
        apply(generated)
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
        generationOrigin = generated.origin
        status = generated.status
    }

    func applySection(_ section: ContentSection, regenerated: GeneratedContent) {
        updatedAt = .now
        switch section {
        case .overview:
            overview = regenerated.overview
        case .hook:
            hook = regenerated.hook
            alternateHooks = regenerated.alternateHooks
        case .script:
            script = regenerated.script
            voiceover = regenerated.voiceover
        case .caption:
            caption = regenerated.caption
        case .hashtags:
            hashtags = regenerated.hashtags
        case .cta:
            cta = regenerated.cta
        case .shotList:
            shotList = regenerated.shotList
        case .notes:
            notes = regenerated.notes
        }
        generationOrigin = regenerated.origin
    }

    func asContentProject(newID: UUID? = nil) -> ContentProject {
        ContentProject(
            id: newID ?? savedProjectID ?? id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            topic: topic,
            category: category,
            platform: platform,
            audience: audience,
            tone: tone,
            language: language,
            goal: goal,
            style: style,
            durationSeconds: durationSeconds,
            generationMode: generationMode,
            status: status,
            isFavorite: isFavorite,
            contentAngle: contentAngle,
            audienceSummary: audienceSummary,
            overview: overview,
            hook: hook,
            alternateHooks: alternateHooks,
            script: script,
            voiceover: voiceover,
            caption: caption,
            hashtags: hashtags,
            cta: cta,
            shotList: shotList,
            notes: notes,
            performanceRationale: performanceRationale,
            bestPostingTime: bestPostingTime,
            emotionalTrigger: emotionalTrigger,
            templateUsed: templateUsed,
            batchIdeas: batchIdeas,
            thumbnailSuggestions: thumbnailSuggestions,
            postingChecklist: postingChecklist,
            postingTip: postingTip,
            contentScore: contentScore
        )
    }
}

extension GenerationSession {
    static func from(request: GenerationRequest, generated: GeneratedContent) -> GenerationSession {
        GenerationSession(
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
            contentScore: generated.score,
            generationOrigin: generated.origin
        )
    }
}
