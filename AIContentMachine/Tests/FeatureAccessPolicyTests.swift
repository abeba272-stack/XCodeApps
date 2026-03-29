import XCTest
import SwiftData
@testable import AIContentMachine

final class FeatureAccessPolicyTests: XCTestCase {
    func testFreePolicyMatchesProductModel() {
        XCTAssertEqual(FeatureAccessPolicy.freeGenerationLimitPerMonth, 8)
        XCTAssertTrue(FeatureAccessPolicy.freeGenerationModes.contains(.singleIdea))
        XCTAssertTrue(FeatureAccessPolicy.freeGenerationModes.contains(.fullPackage))
        XCTAssertFalse(FeatureAccessPolicy.freeGenerationModes.contains(.batchIdeas))
        XCTAssertEqual(FeatureAccessPolicy.freeProviderModes, [.mock])
        XCTAssertEqual(FeatureAccessPolicy.proProviderModes, [.customEndpoint])
    }

    func testUsageWindowStartNormalizesToMonthBoundary() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 27
        components.hour = 16
        components.minute = 42

        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!
        let windowStart = FeatureAccessPolicy.usageWindowStart(for: date, calendar: calendar)

        let normalized = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: windowStart)
        XCTAssertEqual(normalized.year, 2026)
        XCTAssertEqual(normalized.month, 3)
        XCTAssertEqual(normalized.day, 1)
        XCTAssertEqual(normalized.hour, 0)
        XCTAssertEqual(normalized.minute, 0)
    }
}

@MainActor
final class ContentGeneratorViewModelTests: XCTestCase {
    func testBuildRequestRejectsEmptyTopic() throws {
        let viewModel = try makeViewModel()
        viewModel.audience = "Founders"

        XCTAssertThrowsError(try viewModel.buildRequest()) { error in
            XCTAssertEqual(error.localizedDescription, "Add a topic to generate content.")
        }
    }

    func testBuildRequestRejectsShortAndLongTopic() throws {
        let viewModel = try makeViewModel()
        viewModel.audience = "Founders"

        viewModel.topic = "Hi"
        XCTAssertThrowsError(try viewModel.buildRequest()) { error in
            XCTAssertEqual(error.localizedDescription, "The topic must be at least 3 characters.")
        }

        viewModel.topic = String(repeating: "A", count: 201)
        XCTAssertThrowsError(try viewModel.buildRequest()) { error in
            XCTAssertEqual(error.localizedDescription, "The topic must be 200 characters or fewer.")
        }
    }

    func testBuildRequestRejectsEmptyAndShortAudience() throws {
        let viewModel = try makeViewModel()
        viewModel.topic = "Content systems"

        XCTAssertThrowsError(try viewModel.buildRequest()) { error in
            XCTAssertEqual(error.localizedDescription, "Add a target audience to generate content.")
        }

        viewModel.audience = "AI"
        XCTAssertThrowsError(try viewModel.buildRequest()) { error in
            XCTAssertEqual(error.localizedDescription, "The audience must be at least 3 characters.")
        }
    }

    func testBuildRequestSanitizesUserContext() throws {
        let viewModel = try makeViewModel()
        let profile = UserProfile(
            selectedNiches: ["Business"],
            preferredPlatforms: [ContentPlatform.tiktok.rawValue],
            preferredLanguage: .english,
            preferredTone: .direct,
            goals: [ContentGoal.views.rawValue],
            creatorName: "Abeba",
            defaultAudience: "Creators",
            persistentPromptNotes: String(repeating: "A", count: 520) + "\u{0007}\u{0001}end"
        )

        viewModel.preload(from: profile)
        viewModel.topic = "Content systems"
        viewModel.audience = "Founders"

        let request = try viewModel.buildRequest()

        XCTAssertLessThanOrEqual(request.userContext.count, 500)
        XCTAssertFalse(request.userContext.unicodeScalars.contains(where: { $0 == "\u{0007}" }))
        XCTAssertFalse(request.userContext.unicodeScalars.contains(where: { $0 == "\u{0001}" }))
    }

    private func makeViewModel() throws -> ContentGeneratorViewModel {
        let schema = Schema([
            ContentProject.self,
            UserProfile.self,
            TemplateModel.self,
            PlannerAssignment.self,
            AppSettings.self
        ])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration("AIContentMachine-Tests", schema: schema, isStoredInMemoryOnly: true)]
        )
        let subscriptionStore = SubscriptionStore(logger: StubLogger())
        let featureAccessController = FeatureAccessController(
            modelContainer: container,
            subscriptionStore: subscriptionStore,
            logger: StubLogger()
        )

        return ContentGeneratorViewModel(
            generateContentUseCase: GenerateContentUseCase(factory: StubContentGenerationFactory()),
            regenerateSectionUseCase: RegenerateSectionUseCase(factory: StubContentGenerationFactory()),
            saveDraftUseCase: SaveDraftUseCase(persistence: StubPersistenceService()),
            duplicateProjectUseCase: DuplicateProjectUseCase(persistence: StubPersistenceService()),
            persistenceService: StubPersistenceService(),
            exportService: StubExportService(),
            userPreferencesService: DefaultUserPreferencesService(),
            featureAccessController: featureAccessController,
            paywallController: PaywallController(),
            logger: StubLogger()
        )
    }
}

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testValidateEndpointAllowsEmptyValue() {
        let viewModel = makeSettingsViewModel()
        viewModel.localServerEndpoint = ""

        XCTAssertTrue(viewModel.validateEndpoint())
        XCTAssertNil(viewModel.endpointValidationError)
    }

    func testValidateEndpointRejectsInvalidValue() {
        let viewModel = makeSettingsViewModel()
        viewModel.localServerEndpoint = "ftp://localhost:11434"

        XCTAssertFalse(viewModel.validateEndpoint())
        XCTAssertEqual(viewModel.endpointValidationError, "URL must start with http:// or https://")
    }

    func testConnectionTestMapsSuccessAndRejectedEndpointResponses() async {
        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/ok" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, Data("{\"ok\":true}".utf8))
            }

            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data("not found".utf8))
        }

        let successTester = DefaultEndpointConnectionTester(session: makeSession())
        let successViewModel = makeSettingsViewModel(endpointConnectionTester: successTester)
        successViewModel.localServerEndpoint = "http://localhost/ok"
        await successViewModel.testConnection()

        XCTAssertEqual(
            successViewModel.connectionTestResult,
            .init(success: true, message: "Connection successful (HTTP 200).")
        )

        let failureTester = DefaultEndpointConnectionTester(session: makeSession())
        let failureViewModel = makeSettingsViewModel(endpointConnectionTester: failureTester)
        failureViewModel.localServerEndpoint = "http://localhost/missing"
        await failureViewModel.testConnection()

        XCTAssertEqual(
            failureViewModel.connectionTestResult,
            .init(
                success: false,
                message: "Server is reachable, but this endpoint rejected the ACM probe (HTTP 404). Check the endpoint path."
            )
        )
    }

    private func makeSettingsViewModel(
        endpointConnectionTester: any EndpointConnectionTesting = StubEndpointConnectionTester()
    ) -> SettingsViewModel {
        SettingsViewModel(
            settingsService: StubSettingsService(),
            updateSettingsUseCase: UpdateSettingsUseCase(settingsService: StubSettingsService()),
            exportWorkspaceUseCase: ExportWorkspaceUseCase(exportService: StubExportService()),
            persistenceService: StubPersistenceService(),
            endpointConnectionTester: endpointConnectionTester,
            logger: StubLogger()
        )
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

@MainActor
private final class StubPersistenceService: PersistenceService {
    func saveDraft(from session: GenerationSession) throws -> ContentProject {
        throw AppError.persistence("Unused in test")
    }

    func duplicateDraft(from session: GenerationSession) throws -> ContentProject {
        throw AppError.persistence("Unused in test")
    }

    func persistFavoriteState(for session: GenerationSession) throws {}

    func clearLocalData(projects: [ContentProject], assignments: [PlannerAssignment]) throws {}

    func resetOnboarding(profile: UserProfile) throws {}

    func assign(project: ContentProject, to date: Date, existingAssignments: [PlannerAssignment]) throws -> PlannerAssignment {
        throw AppError.persistence("Unused in test")
    }

    func togglePosted(for assignment: PlannerAssignment, project: ContentProject?) throws {}
}

@MainActor
private final class StubSettingsService: SettingsService {
    func loadDraft(profile: UserProfile, settings: AppSettings) -> SettingsDraft {
        SettingsDraft(
            email: profile.email,
            creatorName: profile.creatorName,
            nichesText: "",
            defaultAudience: profile.defaultAudience,
            persistentPromptNotes: profile.persistentPromptNotes,
            selectedPlatforms: [],
            selectedLanguage: .english,
            selectedTone: .direct,
            selectedGoals: [],
            postingFrequency: 4,
            theme: .dark,
            providerMode: .mock,
            localServerEndpoint: AppSettings.defaultLocalServerEndpoint
        )
    }

    func saveDraft(profile: UserProfile, settings: AppSettings, draft: SettingsDraft) throws {}
}

private struct StubExportService: ExportService {
    func formattedPackage(for session: GenerationSession) -> String { "" }
    func videoPrompt(for session: GenerationSession) -> String { "" }
    func sectionText(for section: ContentSection, session: GenerationSession) -> String { "" }
    func exportWorkspace(profile: UserProfile, settings: AppSettings, projects: [ContentProject], assignments: [PlannerAssignment]) throws -> URL {
        URL(fileURLWithPath: "/tmp/acm-export.json")
    }
}

@MainActor
private struct StubContentGenerationFactory: ContentGenerationServiceFactory {
    func makeService(for settings: AppSettings) throws -> any ContentGenerationService {
        MockContentGenerationService()
    }
}

private struct StubEndpointConnectionTester: EndpointConnectionTesting, Sendable {
    func testConnection(to endpoint: URL) async -> SettingsViewModel.ConnectionTestResult {
        .init(success: true, message: "Connection successful (HTTP 200).")
    }
}

private struct StubLogger: AppLogger {
    func debug(_ message: String, category: String) {}
    func info(_ message: String, category: String) {}
    func warn(_ message: String, category: String) {}
    func error(_ message: String, category: String) {}
}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
