import Foundation
import SwiftData

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var selectedNiches: [String] = []
    @Published var customNiche: String = ""
    @Published var selectedPlatforms: Set<ContentPlatform> = []
    @Published var selectedLanguage: ContentLanguage = .english
    @Published var selectedTone: ContentTone = .direct
    @Published var selectedGoals: Set<ContentGoal> = [.views]
    @Published var postingFrequency: Double = 4
    @Published var creatorName: String = ""
    @Published var errorMessage: String?

    func preload(from profile: UserProfile) {
        selectedNiches = profile.selectedNiches
        selectedPlatforms = Set(profile.preferredPlatformEnums)
        selectedLanguage = profile.preferredLanguage
        selectedTone = profile.preferredTone
        selectedGoals = Set(profile.goalEnums)
        postingFrequency = Double(profile.postingFrequency)
        creatorName = profile.creatorName == "Creator" ? "" : profile.creatorName
    }

    func toggle(niche: String) {
        if selectedNiches.contains(niche) {
            selectedNiches.removeAll { $0 == niche }
        } else {
            selectedNiches.append(niche)
        }
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

    func appendCustomNicheIfNeeded() {
        let trimmed = customNiche.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedNiches.contains(trimmed) else { return }
        selectedNiches.append(trimmed)
        customNiche = ""
    }

    func save(into profile: UserProfile, context: ModelContext) -> Bool {
        appendCustomNicheIfNeeded()

        guard !selectedNiches.isEmpty else {
            errorMessage = "Pick at least one niche to personalize the dashboard."
            return false
        }

        guard !selectedPlatforms.isEmpty else {
            errorMessage = "Choose at least one platform to continue."
            return false
        }

        errorMessage = nil
        profile.selectedNiches = selectedNiches
        profile.preferredPlatforms = selectedPlatforms.map(\.rawValue).sorted()
        profile.preferredLanguage = selectedLanguage
        profile.preferredTone = selectedTone
        profile.goals = selectedGoals.map(\.rawValue).sorted()
        profile.postingFrequency = Int(postingFrequency)
        profile.creatorName = creatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Creator" : creatorName
        profile.onboardingCompleted = true

        do {
            try context.save()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
