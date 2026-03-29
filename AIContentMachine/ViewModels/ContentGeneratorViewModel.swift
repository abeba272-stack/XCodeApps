import Foundation
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
    @Published var session: GenerationSession?
    @Published var shareItems: [Any] = []
    @Published var didCopyMessage: String?
    @Published var validationError: String?
    @Published var infoMessage: String?

    private let generateContentUseCase: GenerateContentUseCase
    private let regenerateSectionUseCase: RegenerateSectionUseCase
    private let saveDraftUseCase: SaveDraftUseCase
    private let duplicateProjectUseCase: DuplicateProjectUseCase
    private let persistenceService: any PersistenceService
    private let exportService: any ExportService
    private let userPreferencesService: any UserPreferencesService
    private let featureAccessController: FeatureAccessController
    private let paywallController: PaywallController
    private let logger: any AppLogger
    private var userContext: String = ""

    private(set) var latestRequest: GenerationRequest?

    init(
        generateContentUseCase: GenerateContentUseCase,
        regenerateSectionUseCase: RegenerateSectionUseCase,
        saveDraftUseCase: SaveDraftUseCase,
        duplicateProjectUseCase: DuplicateProjectUseCase,
        persistenceService: any PersistenceService,
        exportService: any ExportService,
        userPreferencesService: any UserPreferencesService,
        featureAccessController: FeatureAccessController,
        paywallController: PaywallController,
        logger: any AppLogger
    ) {
        self.generateContentUseCase = generateContentUseCase
        self.regenerateSectionUseCase = regenerateSectionUseCase
        self.saveDraftUseCase = saveDraftUseCase
        self.duplicateProjectUseCase = duplicateProjectUseCase
        self.persistenceService = persistenceService
        self.exportService = exportService
        self.userPreferencesService = userPreferencesService
        self.featureAccessController = featureAccessController
        self.paywallController = paywallController
        self.logger = logger
    }

    func preload(from profile: UserProfile) {
        category = profile.selectedNiches.first ?? "Education"
        platform = profile.preferredPlatformEnums.first ?? .tiktok
        tone = profile.preferredTone
        language = profile.preferredLanguage
        goal = profile.goalEnums.first ?? .views
        userContext = userPreferencesService.promptContext(for: profile)
        if audience.isEmpty {
            audience = profile.defaultAudience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Creators who want better short-form content"
                : profile.defaultAudience
        }
    }

    func buildRequest() throws -> GenerationRequest {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAudience = audience.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedTopic.isEmpty {
            throw GenerationError.missingInput("Add a topic to generate content.")
        }

        if trimmedTopic.count < 3 {
            throw GenerationError.missingInput("The topic must be at least 3 characters.")
        }

        if trimmedTopic.count > 200 {
            throw GenerationError.missingInput("The topic must be 200 characters or fewer.")
        }

        if trimmedAudience.isEmpty {
            throw GenerationError.missingInput("Add a target audience to generate content.")
        }

        if !trimmedAudience.isEmpty && trimmedAudience.count < 3 {
            throw GenerationError.missingInput("The audience must be at least 3 characters.")
        }

        let sanitizedContext = Self.sanitizeUserContext(userContext)

        let request = GenerationRequest(
            topic: trimmedTopic,
            platform: platform,
            category: category.isEmpty ? "General" : category,
            audience: trimmedAudience,
            tone: tone,
            language: language,
            goal: goal,
            style: style,
            durationSeconds: Int(durationSeconds),
            mode: mode,
            template: selectedTemplate,
            userContext: sanitizedContext
        )

        return request
    }

    private static func sanitizeUserContext(_ context: String) -> String {
        let cleaned = context.unicodeScalars.filter { scalar in
            !CharacterSet.controlCharacters.subtracting(.whitespaces).contains(scalar)
        }
        return String(String.UnicodeScalarView(cleaned)).prefix(500).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func generate(settings: AppSettings) async {
        guard !isGenerating else { return }

        do {
            let request = try buildRequest()
            switch featureAccessController.generationGate(settings: settings, mode: request.mode, template: selectedTemplate) {
            case .allowed:
                break
            case .paywall(let context):
                paywallController.present(context)
                return
            }

            latestRequest = request
            isGenerating = true
            errorMessage = nil
            validationError = nil
            infoMessage = nil

            let generated = try await generateContentUseCase.execute(request: request, settings: settings)
            applyGeneratedContent(generated, request: request)
            featureAccessController.recordSuccessfulGeneration(settings: settings)

            if settings.providerMode == .customEndpoint, generated.origin == .providerFallback {
                infoMessage = request.language == .german
                    ? "Der lokale AI-Server konnte nicht genutzt werden. Dein Entwurf wurde im Offline-Modus generiert."
                    : "The local AI server could not be used. Your draft was generated in offline mode."
            }
        } catch let error as GenerationError {
            switch error {
            case .missingInput:
                validationError = error.localizedDescription
            default:
                logger.error("Generate content failed: \(error.localizedDescription)", category: "ContentGeneratorViewModel")
                errorMessage = AppError.from(error, fallback: "The content package could not be generated.").localizedDescription
            }
        } catch {
            logger.error("Generate content failed: \(error.localizedDescription)", category: "ContentGeneratorViewModel")
            errorMessage = AppError.from(error, fallback: "The content package could not be generated.").localizedDescription
        }

        isGenerating = false
    }

    func regenerateAll(settings: AppSettings) async {
        await generate(settings: settings)
    }

    func regenerate(section: ContentSection, settings: AppSettings) async {
        guard let request = latestRequest, let session else { return }

        do {
            isGenerating = true
            let regenerated = try await regenerateSectionUseCase.execute(section: section, request: request, settings: settings)
            session.applySection(section, regenerated: regenerated)
            session.contentScore = ContentScoreCalculator.score(for: session)
        } catch {
            logger.error("Regenerate section failed: \(error.localizedDescription)", category: "ContentGeneratorViewModel")
            errorMessage = AppError.from(error, fallback: "This section could not be regenerated.").localizedDescription
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

    func saveDraft() {
        guard let session else { return }

        do {
            let project = try saveDraftUseCase.execute(session: session)
            session.savedProjectID = project.id
            session.hasSavedDraft = true
            didCopyMessage = "Draft saved"
        } catch {
            logger.error("Save draft failed: \(error.localizedDescription)", category: "ContentGeneratorViewModel")
            errorMessage = AppError.from(error, fallback: "The draft could not be saved.").localizedDescription
        }
    }

    func duplicate() {
        guard let session else { return }

        do {
            _ = try duplicateProjectUseCase.execute(session: session)
            didCopyMessage = "Draft duplicated"
        } catch {
            logger.error("Duplicate draft failed: \(error.localizedDescription)", category: "ContentGeneratorViewModel")
            errorMessage = AppError.from(error, fallback: "The draft copy could not be saved.").localizedDescription
        }
    }

    func toggleFavorite() {
        guard let session else { return }
        session.isFavorite.toggle()

        do {
            try persistenceService.persistFavoriteState(for: session)
        } catch {
            logger.error("Persist favorite failed: \(error.localizedDescription)", category: "ContentGeneratorViewModel")
            errorMessage = AppError.from(error, fallback: "The favorite state could not be updated.").localizedDescription
        }
    }

    func copy(section: ContentSection) {
        guard let session else { return }
        UIPasteboard.general.string = exportService.sectionText(for: section, session: session)
        didCopyMessage = "\(section.rawValue) copied"
    }

    func copyFullPackage() {
        guard let session else { return }
        guard featureAccessController.canCopyFullPackage() else {
            paywallController.present(PaywallContext(reason: .premiumCopy))
            return
        }
        UIPasteboard.general.string = exportService.formattedPackage(for: session)
        didCopyMessage = "Full package copied"
    }

    func copyVideoPrompt() {
        guard let session else { return }
        UIPasteboard.general.string = exportService.videoPrompt(for: session)
        didCopyMessage = "Video prompt copied"
    }

    func prepareSharePackage() {
        guard let session else { return }
        guard featureAccessController.canCopyFullPackage() else {
            paywallController.present(PaywallContext(reason: .premiumCopy))
            return
        }
        shareItems = [exportService.formattedPackage(for: session)]
    }

    func videoPromptText(for session: GenerationSession) -> String {
        exportService.videoPrompt(for: session)
    }

    func applyTemplate(_ template: TemplateModel?) {
        selectedTemplate = template

        guard let template else { return }

        if let idealPlatform = template.idealPlatforms.first {
            platform = idealPlatform
        }
        tone = template.recommendedTone
        goal = template.recommendedGoal
        style = template.recommendedStyle

        if let quickStart = template.quickStartBrief {
            topic = quickStart.topic
            audience = quickStart.audience
            category = quickStart.category
            mode = quickStart.mode
            durationSeconds = quickStart.durationSeconds
        } else if category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || category == "General" {
            category = template.category
        }
    }

    private func applyGeneratedContent(_ generated: GeneratedContent, request: GenerationRequest) {
        if let session {
            let savedProjectID = session.savedProjectID
            let hasSavedDraft = session.hasSavedDraft
            let isFavorite = session.isFavorite

            session.apply(request: request, generated: generated)
            session.savedProjectID = savedProjectID
            session.hasSavedDraft = hasSavedDraft
            session.isFavorite = isFavorite
        } else {
            session = GenerationSession.from(request: request, generated: generated)
        }
    }
}
