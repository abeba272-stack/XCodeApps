import Foundation

@MainActor
protocol PersistenceService: AnyObject {
    func saveDraft(from session: GenerationSession) throws -> ContentProject
    func duplicateDraft(from session: GenerationSession) throws -> ContentProject
    func persistFavoriteState(for session: GenerationSession) throws
    func clearLocalData(projects: [ContentProject], assignments: [PlannerAssignment]) throws
    func resetOnboarding(profile: UserProfile) throws
    func assign(project: ContentProject, to date: Date, existingAssignments: [PlannerAssignment]) throws -> PlannerAssignment
    func togglePosted(for assignment: PlannerAssignment, project: ContentProject?) throws
}

protocol ExportService {
    func formattedPackage(for session: GenerationSession) -> String
    func videoPrompt(for session: GenerationSession) -> String
    func sectionText(for section: ContentSection, session: GenerationSession) -> String
    func exportWorkspace(profile: UserProfile, settings: AppSettings, projects: [ContentProject], assignments: [PlannerAssignment]) throws -> URL
}

@MainActor
protocol SettingsService: AnyObject {
    func loadDraft(profile: UserProfile, settings: AppSettings) -> SettingsDraft
    func saveDraft(profile: UserProfile, settings: AppSettings, draft: SettingsDraft) throws
}

@MainActor
protocol ContentGenerationServiceFactory: Sendable {
    func makeService(for settings: AppSettings) throws -> any ContentGenerationService
}

struct SettingsDraft {
    var creatorName: String
    var nichesText: String
    var selectedPlatforms: Set<ContentPlatform>
    var selectedLanguage: ContentLanguage
    var selectedTone: ContentTone
    var selectedGoals: Set<ContentGoal>
    var postingFrequency: Double
    var theme: AppThemePreference
    var providerMode: AIProviderMode
    var localServerEndpoint: String
}

@MainActor
struct GenerateContentUseCase {
    let factory: any ContentGenerationServiceFactory

    func execute(request: GenerationRequest, settings: AppSettings) async throws -> GeneratedContent {
        let service = try factory.makeService(for: settings)
        return try await service.generateContent(for: request)
    }
}

@MainActor
struct RegenerateSectionUseCase {
    let factory: any ContentGenerationServiceFactory

    func execute(section: ContentSection, request: GenerationRequest, settings: AppSettings) async throws -> GeneratedContent {
        let service = try factory.makeService(for: settings)
        return try await service.regenerateSection(section, for: request)
    }
}

@MainActor
struct SaveDraftUseCase {
    let persistence: any PersistenceService

    func execute(session: GenerationSession) throws -> ContentProject {
        try persistence.saveDraft(from: session)
    }
}

@MainActor
struct DuplicateProjectUseCase {
    let persistence: any PersistenceService

    func execute(session: GenerationSession) throws -> ContentProject {
        try persistence.duplicateDraft(from: session)
    }
}

struct ExportWorkspaceUseCase {
    let exportService: any ExportService

    func execute(profile: UserProfile, settings: AppSettings, projects: [ContentProject], assignments: [PlannerAssignment]) throws -> URL {
        try exportService.exportWorkspace(profile: profile, settings: settings, projects: projects, assignments: assignments)
    }
}

@MainActor
struct UpdateSettingsUseCase {
    let settingsService: any SettingsService

    func execute(profile: UserProfile, settings: AppSettings, draft: SettingsDraft) throws {
        try settingsService.saveDraft(profile: profile, settings: settings, draft: draft)
    }
}

@MainActor
struct AssignProjectUseCase {
    let persistence: any PersistenceService

    func execute(project: ContentProject, date: Date, existingAssignments: [PlannerAssignment]) throws -> PlannerAssignment {
        try persistence.assign(project: project, to: date, existingAssignments: existingAssignments)
    }
}

@MainActor
struct TogglePostedUseCase {
    let persistence: any PersistenceService

    func execute(assignment: PlannerAssignment, project: ContentProject?) throws {
        try persistence.togglePosted(for: assignment, project: project)
    }
}
