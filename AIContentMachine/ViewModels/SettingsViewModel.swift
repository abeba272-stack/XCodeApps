import Foundation
import SwiftData

protocol EndpointConnectionTesting: Sendable {
    func testConnection(to endpoint: URL) async -> SettingsViewModel.ConnectionTestResult
}

struct DefaultEndpointConnectionTester: EndpointConnectionTesting, @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func testConnection(to endpoint: URL) async -> SettingsViewModel.ConnectionTestResult {
        do {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.timeoutInterval = 6
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(ConnectionProbePayload(prompt: "ping"))

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .init(success: false, message: "Server returned an invalid response.")
            }

            switch httpResponse.statusCode {
            case 200..<300:
                let body = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !body.isEmpty else {
                    return .init(success: false, message: "Server responded, but the body was empty.")
                }
                return .init(success: true, message: "Connection successful (HTTP \(httpResponse.statusCode)).")
            case 404, 405:
                return .init(
                    success: false,
                    message: "Server is reachable, but this endpoint rejected the ACM probe (HTTP \(httpResponse.statusCode)). Check the endpoint path."
                )
            case 400..<500:
                return .init(success: false, message: "Server is reachable, but the endpoint returned HTTP \(httpResponse.statusCode).")
            case 500..<600:
                return .init(success: false, message: "Server is reachable, but it failed with HTTP \(httpResponse.statusCode).")
            default:
                return .init(success: false, message: "Server returned an unexpected response (HTTP \(httpResponse.statusCode)).")
            }
        } catch let error as URLError {
            return .init(success: false, message: "Could not reach server: \(error.localizedDescription)")
        } catch {
            return .init(success: false, message: "Connection test failed: \(error.localizedDescription)")
        }
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var creatorName: String = ""
    @Published var nichesText: String = ""
    @Published var defaultAudience: String = ""
    @Published var persistentPromptNotes: String = ""
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
    @Published var endpointValidationError: String?
    @Published var isTestingConnection = false
    @Published var connectionTestResult: ConnectionTestResult?

    struct ConnectionTestResult: Equatable {
        let success: Bool
        let message: String
    }

    private let settingsService: any SettingsService
    private let updateSettingsUseCase: UpdateSettingsUseCase
    private let exportWorkspaceUseCase: ExportWorkspaceUseCase
    private let persistenceService: any PersistenceService
    private let endpointConnectionTester: any EndpointConnectionTesting
    private let logger: any AppLogger

    init(
        settingsService: any SettingsService,
        updateSettingsUseCase: UpdateSettingsUseCase,
        exportWorkspaceUseCase: ExportWorkspaceUseCase,
        persistenceService: any PersistenceService,
        endpointConnectionTester: any EndpointConnectionTesting,
        logger: any AppLogger
    ) {
        self.settingsService = settingsService
        self.updateSettingsUseCase = updateSettingsUseCase
        self.exportWorkspaceUseCase = exportWorkspaceUseCase
        self.persistenceService = persistenceService
        self.endpointConnectionTester = endpointConnectionTester
        self.logger = logger
    }

    func load(profile: UserProfile, settings: AppSettings) {
        let draft = settingsService.loadDraft(profile: profile, settings: settings)
        email = draft.email
        creatorName = draft.creatorName
        nichesText = draft.nichesText
        defaultAudience = draft.defaultAudience
        persistentPromptNotes = draft.persistentPromptNotes
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

    func validateEndpoint() -> Bool {
        let trimmed = localServerEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            endpointValidationError = "Add a local server endpoint."
            return false
        }

        guard trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") else {
            endpointValidationError = "Enter a valid URL starting with http:// or https://."
            return false
        }

        guard AppSettings.endpointURL(from: trimmed) != nil else {
            endpointValidationError = "Enter a valid local server URL."
            return false
        }

        endpointValidationError = nil
        return true
    }

    func testConnection() async {
        connectionTestResult = nil
        guard validateEndpoint() else {
            connectionTestResult = ConnectionTestResult(
                success: false,
                message: endpointValidationError ?? "Enter a valid local server URL."
            )
            return
        }

        let trimmed = localServerEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = AppSettings.endpointURL(from: trimmed) else {
            connectionTestResult = ConnectionTestResult(success: false, message: "Enter a valid local server URL.")
            return
        }

        isTestingConnection = true
        defer { isTestingConnection = false }
        let endpointConnectionTester = endpointConnectionTester
        connectionTestResult = await endpointConnectionTester.testConnection(to: url)
    }

    func save(profile: UserProfile, settings: AppSettings) {
        if providerMode == .customEndpoint && !validateEndpoint() {
            errorMessage = endpointValidationError
            return
        }

        let draft = SettingsDraft(
            email: email,
            creatorName: creatorName,
            nichesText: nichesText,
            defaultAudience: defaultAudience,
            persistentPromptNotes: persistentPromptNotes,
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

private struct ConnectionProbePayload: Encodable {
    let prompt: String
}
