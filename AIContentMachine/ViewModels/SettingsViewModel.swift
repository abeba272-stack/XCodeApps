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
    @Published var apiKey: String = ""
    @Published var apiEndpoint: String = ""
    @Published var apiModel: String = "content-engine-v1"
    @Published var shareItems: [Any] = []
    @Published var errorMessage: String?
    @Published var toastMessage: String?

    func load(profile: UserProfile, settings: AppSettings) {
        creatorName = profile.creatorName
        nichesText = profile.selectedNiches.joined(separator: ", ")
        selectedPlatforms = Set(profile.preferredPlatformEnums)
        selectedLanguage = profile.preferredLanguage
        selectedTone = profile.preferredTone
        selectedGoals = Set(profile.goalEnums)
        postingFrequency = Double(profile.postingFrequency)
        theme = settings.theme
        providerMode = settings.providerMode
        apiKey = settings.apiKey
        apiEndpoint = settings.apiEndpoint
        apiModel = settings.apiModel
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

    func save(profile: UserProfile, settings: AppSettings, context: ModelContext) {
        profile.creatorName = creatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Creator" : creatorName
        profile.selectedNiches = nichesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        profile.preferredPlatforms = selectedPlatforms.map(\.rawValue).sorted()
        profile.preferredLanguage = selectedLanguage
        profile.preferredTone = selectedTone
        profile.goals = selectedGoals.map(\.rawValue).sorted()
        profile.postingFrequency = Int(postingFrequency)

        settings.theme = theme
        settings.providerMode = providerMode
        settings.apiKey = apiKey
        settings.apiEndpoint = apiEndpoint
        settings.apiModel = apiModel

        do {
            try context.save()
            toastMessage = "Settings saved"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearLocalData(projects: [ContentProject], assignments: [PlannerAssignment], context: ModelContext) {
        projects.forEach(context.delete)
        assignments.forEach(context.delete)
        do {
            try context.save()
            toastMessage = "Local projects cleared"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetOnboarding(profile: UserProfile, context: ModelContext) {
        profile.onboardingCompleted = false
        do {
            try context.save()
            toastMessage = "Onboarding reset"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func export(profile: UserProfile, settings: AppSettings, projects: [ContentProject], assignments: [PlannerAssignment]) {
        do {
            shareItems = [try CopyExportService.exportURL(profile: profile, settings: settings, projects: projects, assignments: assignments)]
            toastMessage = "Export ready"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importSampleData(profile: UserProfile, context: ModelContext) async {
        do {
            try await AppBootstrapper.importSampleData(context: context, profile: profile)
            toastMessage = "Sample data imported"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
