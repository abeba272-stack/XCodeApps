import Foundation
import SwiftData

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var creatorName: String = ""
    @Published var nichesText: String = ""
    @Published var selectedPlatforms: Set<ContentPlatform> = []
    @Published var selectedLanguage: ContentLanguage = .english
    @Published var selectedTone: ContentTone = .direct
    @Published var selectedGoals: Set<ContentGoal> = []
    @Published var postingFrequency: Double = 4
    @Published var theme: AppThemePreference = .dark
    @Published var providerMode: AIProviderMode = .mock
    @Published var localServerEndpoint: String = AppSettings.defaultLocalServerEndpoint
    @Published var shareItems: [Any] = []
    @Published var errorMessage: String?
    @Published var toastMessage: String?

    private let settingsService: any SettingsService
    private let updateSettingsUseCase: UpdateSettingsUseCase
    private let exportWorkspaceUseCase: ExportWorkspaceUseCase
    private let persistenceService: any PersistenceService
    private let logger: any AppLogger

    init(
        settingsService: any SettingsService,
        updateSettingsUseCase: UpdateSettingsUseCase,
        exportWorkspaceUseCase: ExportWorkspaceUseCase,
        persistenceService: any PersistenceService,
        logger: any AppLogger
    ) {
        self.settingsService = settingsService
        self.updateSettingsUseCase = updateSettingsUseCase
        self.exportWorkspaceUseCase = exportWorkspaceUseCase
        self.persistenceService = persistenceService
        self.logger = logger
    }

    func load(profile: UserProfile, settings: AppSettings) {
        let draft = settingsService.loadDraft(profile: profile, settings: settings)
        creatorName = draft.creatorName
        nichesText = draft.nichesText
        selectedPlatforms = draft.selectedPlatforms
        selectedLanguage = draft.selectedLanguage
        selectedTone = draft.selectedTone
        selectedGoals = draft.selectedGoals
        postingFrequency = draft.postingFrequency
        theme = draft.theme
        providerMode = draft.providerMode
        localServerEndpoint = draft.localServerEndpoint
    }

    func toggle(platform: ContentPlatform) {
        if selectedPlatforms.contains(platform) {
            selectedPlatforms.remove(platform)
        } else {
            selectedPlatforms.insert(platform)
        }
    }

    func toggle(goal: ContentGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    func save(profile: UserProfile, settings: AppSettings) {
        let draft = SettingsDraft(
            creatorName: creatorName,
            nichesText: nichesText,
            selectedPlatforms: selectedPlatforms,
            selectedLanguage: selectedLanguage,
            selectedTone: selectedTone,
            selectedGoals: selectedGoals,
            postingFrequency: postingFrequency,
            theme: theme,
            providerMode: providerMode,
            localServerEndpoint: localServerEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try updateSettingsUseCase.execute(profile: profile, settings: settings, draft: draft)
            toastMessage = "Settings saved"
        } catch {
            logger.error("Save settings failed: \(error.localizedDescription)", category: "SettingsViewModel")
            errorMessage = AppError.from(error, fallback: "Settings could not be saved.").localizedDescription
        }
    }

    func clearLocalData(projects: [ContentProject], assignments: [PlannerAssignment]) {
        do {
            try persistenceService.clearLocalData(projects: projects, assignments: assignments)
            toastMessage = "Local projects cleared"
        } catch {
            logger.error("Clear local data failed: \(error.localizedDescription)", category: "SettingsViewModel")
            errorMessage = AppError.from(error, fallback: "Local data could not be cleared.").localizedDescription
        }
    }

    func resetOnboarding(profile: UserProfile) {
        do {
            try persistenceService.resetOnboarding(profile: profile)
            toastMessage = "Onboarding reset"
        } catch {
            logger.error("Reset onboarding failed: \(error.localizedDescription)", category: "SettingsViewModel")
            errorMessage = AppError.from(error, fallback: "Onboarding could not be reset.").localizedDescription
        }
    }

    func export(profile: UserProfile, settings: AppSettings, projects: [ContentProject], assignments: [PlannerAssignment]) {
        do {
            shareItems = [try exportWorkspaceUseCase.execute(profile: profile, settings: settings, projects: projects, assignments: assignments)]
            toastMessage = "Export ready"
        } catch {
            logger.error("Export workspace failed: \(error.localizedDescription)", category: "SettingsViewModel")
            errorMessage = AppError.from(error, fallback: "The export could not be prepared.").localizedDescription
        }
    }

    func importSampleData(profile: UserProfile, context: ModelContext) async {
        do {
            try await AppBootstrapper.importSampleData(context: context, profile: profile)
            toastMessage = "Sample data imported"
        } catch {
            logger.error("Import sample data failed: \(error.localizedDescription)", category: "SettingsViewModel")
            errorMessage = AppError.from(error, fallback: "Sample data could not be imported.").localizedDescription
        }
    }
}
