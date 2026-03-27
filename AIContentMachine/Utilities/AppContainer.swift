import Foundation
import SwiftData

@MainActor
final class AppContainer: ObservableObject {
    let logger: any AppLogger
    let networkClient: any NetworkClient
    let persistenceService: any PersistenceService
    let exportService: any ExportService
    let settingsService: any SettingsService
    let contentGenerationFactory: any ContentGenerationServiceFactory
    let subscriptionStore: SubscriptionStore
    let featureAccessController: FeatureAccessController
    let paywallController: PaywallController

    let generateContentUseCase: GenerateContentUseCase
    let regenerateSectionUseCase: RegenerateSectionUseCase
    let saveDraftUseCase: SaveDraftUseCase
    let duplicateProjectUseCase: DuplicateProjectUseCase
    let exportWorkspaceUseCase: ExportWorkspaceUseCase
    let updateSettingsUseCase: UpdateSettingsUseCase
    let assignProjectUseCase: AssignProjectUseCase
    let togglePostedUseCase: TogglePostedUseCase

    init(modelContainer: ModelContainer) {
        let logger = ConsoleAppLogger()
        let networkClient = URLSessionNetworkClient(logger: logger)
        let dataStore = SwiftDataStore(modelContainer: modelContainer, logger: logger)
        let exportService = DefaultExportService()
        let generationFactory = DefaultContentGenerationServiceFactory(networkClient: networkClient, logger: logger)
        let subscriptionStore = SubscriptionStore(logger: logger)
        let featureAccessController = FeatureAccessController(
            modelContainer: modelContainer,
            subscriptionStore: subscriptionStore,
            logger: logger
        )
        let paywallController = PaywallController()

        self.logger = logger
        self.networkClient = networkClient
        self.persistenceService = dataStore
        self.exportService = exportService
        self.settingsService = dataStore
        self.contentGenerationFactory = generationFactory
        self.subscriptionStore = subscriptionStore
        self.featureAccessController = featureAccessController
        self.paywallController = paywallController

        self.generateContentUseCase = GenerateContentUseCase(factory: generationFactory)
        self.regenerateSectionUseCase = RegenerateSectionUseCase(factory: generationFactory)
        self.saveDraftUseCase = SaveDraftUseCase(persistence: dataStore)
        self.duplicateProjectUseCase = DuplicateProjectUseCase(persistence: dataStore)
        self.exportWorkspaceUseCase = ExportWorkspaceUseCase(exportService: exportService)
        self.updateSettingsUseCase = UpdateSettingsUseCase(settingsService: dataStore)
        self.assignProjectUseCase = AssignProjectUseCase(persistence: dataStore)
        self.togglePostedUseCase = TogglePostedUseCase(persistence: dataStore)
    }

    func makeContentGeneratorViewModel() -> ContentGeneratorViewModel {
        ContentGeneratorViewModel(
            generateContentUseCase: generateContentUseCase,
            regenerateSectionUseCase: regenerateSectionUseCase,
            saveDraftUseCase: saveDraftUseCase,
            duplicateProjectUseCase: duplicateProjectUseCase,
            persistenceService: persistenceService,
            exportService: exportService,
            featureAccessController: featureAccessController,
            paywallController: paywallController,
            logger: logger
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            settingsService: settingsService,
            updateSettingsUseCase: updateSettingsUseCase,
            exportWorkspaceUseCase: exportWorkspaceUseCase,
            persistenceService: persistenceService,
            logger: logger
        )
    }

    func makePlannerViewModel() -> PlannerViewModel {
        PlannerViewModel(
            assignProjectUseCase: assignProjectUseCase,
            togglePostedUseCase: togglePostedUseCase,
            logger: logger
        )
    }
}
