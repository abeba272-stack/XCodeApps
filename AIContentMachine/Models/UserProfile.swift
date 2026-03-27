import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    private var selectedNichesData: Data
    private var preferredPlatformsData: Data
    var preferredLanguageRaw: String
    var preferredToneRaw: String
    private var goalsData: Data
    var postingFrequency: Int
    var onboardingCompleted: Bool
    var creatorName: String

    init(
        id: UUID = UUID(),
        selectedNiches: [String] = [],
        preferredPlatforms: [String] = [],
        preferredLanguage: ContentLanguage = .english,
        preferredTone: ContentTone = .direct,
        goals: [String] = [],
        postingFrequency: Int = 4,
        onboardingCompleted: Bool = false,
        creatorName: String = "Creator"
    ) {
        self.id = id
        self.selectedNichesData = StringListStorage.encode(selectedNiches)
        self.preferredPlatformsData = StringListStorage.encode(preferredPlatforms)
        self.preferredLanguageRaw = preferredLanguage.rawValue
        self.preferredToneRaw = preferredTone.rawValue
        self.goalsData = StringListStorage.encode(goals)
        self.postingFrequency = postingFrequency
        self.onboardingCompleted = onboardingCompleted
        self.creatorName = creatorName
    }
}

extension UserProfile {
    var selectedNiches: [String] {
        get { StringListStorage.decode(selectedNichesData) }
        set { selectedNichesData = StringListStorage.encode(newValue) }
    }

    var preferredPlatforms: [String] {
        get { StringListStorage.decode(preferredPlatformsData) }
        set { preferredPlatformsData = StringListStorage.encode(newValue) }
    }

    var goals: [String] {
        get { StringListStorage.decode(goalsData) }
        set { goalsData = StringListStorage.encode(newValue) }
    }

    var preferredLanguage: ContentLanguage {
        get { ContentLanguage(rawValue: preferredLanguageRaw) ?? .english }
        set { preferredLanguageRaw = newValue.rawValue }
    }

    var preferredTone: ContentTone {
        get { ContentTone(rawValue: preferredToneRaw) ?? .direct }
        set { preferredToneRaw = newValue.rawValue }
    }

    var preferredPlatformEnums: [ContentPlatform] {
        preferredPlatforms.compactMap(ContentPlatform.init(rawValue:))
    }

    var goalEnums: [ContentGoal] {
        goals.compactMap(ContentGoal.init(rawValue:))
    }

    var snapshot: UserProfileSnapshot {
        UserProfileSnapshot(
            selectedNiches: selectedNiches,
            preferredPlatforms: preferredPlatforms,
            preferredLanguage: preferredLanguageRaw,
            preferredTone: preferredToneRaw,
            goals: goals,
            postingFrequency: postingFrequency,
            onboardingCompleted: onboardingCompleted
        )
    }
}
