import Foundation
import SwiftData
import UIKit

@MainActor
final class ContentGeneratorViewModel: ObservableObject {
    @Published var topic: String = ""
    @Published var platform: ContentPlatform = .tiktok
    @Published var category: String = ""
    @Published var audience: String = ""
    @Published var tone: ContentTone = .direct
    @Published var goal: ContentGoal = .views
    @Published var style: ContentStyle = .educational
    @Published var durationSeconds: Double = 30
    @Published var language: ContentLanguage = .english
    @Published var mode: GenerationMode = .fullPackage
    @Published var selectedTemplate: TemplateModel?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var previewProject: ContentProject?
    @Published var hasSavedCurrentProject = false
    @Published var shareItems: [Any] = []
    @Published var didCopyMessage: String?

    private(set) var latestRequest: GenerationRequest?

    func preload(from profile: UserProfile) {
        category = profile.selectedNiches.first ?? "Education"
        platform = profile.preferredPlatformEnums.first ?? .tiktok
        tone = profile.preferredTone
        language = profile.preferredLanguage
        goal = profile.goalEnums.first ?? .views
        if audience.isEmpty {
            audience = "Creators who want better short-form content"
        }
    }

    func buildRequest() throws -> GenerationRequest {
        let request = GenerationRequest(
            topic: topic,
            platform: platform,
            category: category.isEmpty ? "General" : category,
            audience: audience,
            tone: tone,
            language: language,
            goal: goal,
            style: style,
            durationSeconds: Int(durationSeconds),
            mode: mode,
            template: selectedTemplate
        )

        if request.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw GenerationError.missingInput("Add a topic to generate content.")
        }

        if request.audience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw GenerationError.missingInput("Add a target audience to generate content.")
        }

        return request
    }

    func generate(settings: AppSettings) async {
        do {
            let request = try buildRequest()
            latestRequest = request
            isGenerating = true
            errorMessage = nil

            let service = service(from: settings)
            let generated = try await service.generateContent(for: request)
            if let previewProject, previewProject.modelContext == nil {
                applyFullGeneration(request: request, generated: generated, to: previewProject)
            } else {
                previewProject = ContentProject.from(request: request, generated: generated)
                hasSavedCurrentProject = false
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isGenerating = false
    }

    func regenerateAll(settings: AppSettings) async {
        do {
            let request = try buildRequest()
            latestRequest = request
            isGenerating = true
            errorMessage = nil

            let service = service(from: settings)
            let generated = try await service.generateContent(for: request)

            if let previewProject {
                applyFullGeneration(request: request, generated: generated, to: previewProject)
                hasSavedCurrentProject = previewProject.modelContext != nil
            } else {
                previewProject = ContentProject.from(request: request, generated: generated)
                hasSavedCurrentProject = false
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isGenerating = false
    }

    func regenerate(section: ContentSection, settings: AppSettings) async {
        guard let request = latestRequest, let project = previewProject else { return }
        do {
            isGenerating = true
            let service = service(from: settings)
            let regenerated = try await service.regenerateSection(section, for: request)
            applySectionRegeneration(section, regenerated: regenerated, to: project)
            project.updatedAt = .now
            project.contentScore = ContentScoreCalculator.score(for: project)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isGenerating = false
    }

    func applyToneShift(_ newTone: ContentTone, settings: AppSettings) async {
        tone = newTone
        await regenerateAll(settings: settings)
    }

    func applyLengthShift(_ newDuration: Int, settings: AppSettings) async {
        durationSeconds = Double(newDuration)
        await regenerateAll(settings: settings)
    }

    func saveDraft(context: ModelContext) {
        guard let previewProject else { return }

        do {
            if previewProject.modelContext == nil {
                context.insert(previewProject)
            }
            previewProject.updatedAt = .now
            previewProject.status = previewProject.generationMode == .singleIdea ? .idea : .draft
            try context.save()
            hasSavedCurrentProject = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func duplicate(context: ModelContext) {
        guard let previewProject else { return }

        let copy = ContentProject(
            title: previewProject.title,
            topic: previewProject.topic,
            category: previewProject.category,
            platform: previewProject.platform,
            audience: previewProject.audience,
            tone: previewProject.tone,
            language: previewProject.language,
            goal: previewProject.goal,
            style: previewProject.style,
            durationSeconds: previewProject.durationSeconds,
            generationMode: previewProject.generationMode,
            status: previewProject.status,
            isFavorite: previewProject.isFavorite,
            contentAngle: previewProject.contentAngle,
            audienceSummary: previewProject.audienceSummary,
            overview: previewProject.overview,
            hook: previewProject.hook,
            alternateHooks: previewProject.alternateHooks,
            script: previewProject.script,
            voiceover: previewProject.voiceover,
            caption: previewProject.caption,
            hashtags: previewProject.hashtags,
            cta: previewProject.cta,
            shotList: previewProject.shotList,
            notes: previewProject.notes,
            performanceRationale: previewProject.performanceRationale,
            bestPostingTime: previewProject.bestPostingTime,
            emotionalTrigger: previewProject.emotionalTrigger,
            templateUsed: previewProject.templateUsed,
            batchIdeas: previewProject.batchIdeas,
            thumbnailSuggestions: previewProject.thumbnailSuggestions,
            postingChecklist: previewProject.postingChecklist,
            postingTip: previewProject.postingTip,
            contentScore: previewProject.contentScore
        )

        context.insert(copy)
        do {
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func copy(section: ContentSection) {
        guard let project = previewProject else { return }
        UIPasteboard.general.string = CopyExportService.sectionText(for: section, project: project)
        didCopyMessage = "\(section.rawValue) copied"
    }

    func copyFullPackage() {
        guard let project = previewProject else { return }
        UIPasteboard.general.string = CopyExportService.formattedPackage(for: project)
        didCopyMessage = "Full package copied"
    }

    func prepareSharePackage() {
        guard let project = previewProject else { return }
        shareItems = [CopyExportService.formattedPackage(for: project)]
    }

    private func service(from settings: AppSettings) -> ContentGenerationService {
        if settings.providerMode == .customEndpoint, let url = URL(string: settings.apiEndpoint) {
            return RealAIContentService(apiKey: settings.apiKey, endpoint: url, model: settings.apiModel)
        }
        return MockContentGenerationService()
    }

    private func applyFullGeneration(request: GenerationRequest, generated: GeneratedContent, to project: ContentProject) {
        project.topic = request.topic
        project.category = request.category
        project.platform = request.platform
        project.audience = request.audience
        project.tone = request.tone
        project.language = request.language
        project.goal = request.goal
        project.style = request.style
        project.durationSeconds = request.durationSeconds
        project.generationMode = request.mode
        project.apply(generated)
        project.updatedAt = .now
    }

    private func applySectionRegeneration(_ section: ContentSection, regenerated: GeneratedContent, to project: ContentProject) {
        switch section {
        case .overview:
            project.overview = regenerated.overview
        case .hook:
            project.hook = regenerated.hook
            project.alternateHooks = regenerated.alternateHooks
        case .script:
            project.script = regenerated.script
            project.voiceover = regenerated.voiceover
        case .caption:
            project.caption = regenerated.caption
        case .hashtags:
            project.hashtags = regenerated.hashtags
        case .cta:
            project.cta = regenerated.cta
        case .shotList:
            project.shotList = regenerated.shotList
        case .notes:
            project.notes = regenerated.notes
        }
    }
}
