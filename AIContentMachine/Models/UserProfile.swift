import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    private var selectedNichesData: Data
    private var preferredPlatformsData: Data
    var preferredLanguageRaw: String
    var preferredAccountLanguageRaw: String
    var preferredToneRaw: String
    private var goalsData: Data
    var postingFrequency: Int
    var onboardingCompleted: Bool
    var creatorName: String
    var email: String
    var passwordHash: String
    var authProviderRaw: String
    var subscriptionPlanRaw: String
    var createdAt: Date
    var lastSignedInAt: Date?
    var isSpecialProUser: Bool
    var appleUserID: String
    var googleUserID: String
    var defaultAudience: String
    var persistentPromptNotes: String

    init(
        id: UUID = UUID(),
        selectedNiches: [String] = [],
        preferredPlatforms: [String] = [],
        preferredLanguage: ContentLanguage = .english,
        preferredAccountLanguage: PreferredAccountLanguage? = nil,
        preferredTone: ContentTone = .direct,
        goals: [String] = [],
        postingFrequency: Int = 4,
        onboardingCompleted: Bool = false,
        creatorName: String = "Creator",
        email: String = "",
        passwordHash: String = "",
        authProvider: AuthProvider = .deviceMigration,
        subscriptionPlan: SubscriptionPlan = .standard,
        createdAt: Date = .now,
        lastSignedInAt: Date? = nil,
        isSpecialProUser: Bool = false,
        appleUserID: String = "",
        googleUserID: String = "",
        defaultAudience: String = "Creators who want better short-form content",
        persistentPromptNotes: String = ""
    ) {
        self.id = id
        self.selectedNichesData = StringListStorage.encode(selectedNiches)
        self.preferredPlatformsData = StringListStorage.encode(preferredPlatforms)
        self.preferredLanguageRaw = preferredLanguage.rawValue
        self.preferredAccountLanguageRaw = (preferredAccountLanguage ?? PreferredAccountLanguage(contentLanguage: preferredLanguage)).rawValue
        self.preferredToneRaw = preferredTone.rawValue
        self.goalsData = StringListStorage.encode(goals)
        self.postingFrequency = postingFrequency
        self.onboardingCompleted = onboardingCompleted
        self.creatorName = creatorName
        self.email = email
        self.passwordHash = passwordHash
        self.authProviderRaw = authProvider.rawValue
        self.subscriptionPlanRaw = subscriptionPlan.rawValue
        self.createdAt = createdAt
        self.lastSignedInAt = lastSignedInAt
        self.isSpecialProUser = isSpecialProUser
        self.appleUserID = appleUserID
        self.googleUserID = googleUserID
        self.defaultAudience = defaultAudience
        self.persistentPromptNotes = persistentPromptNotes
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

    var preferredAccountLanguage: PreferredAccountLanguage {
        get {
            PreferredAccountLanguage(rawValue: preferredAccountLanguageRaw)
                ?? PreferredAccountLanguage(contentLanguage: preferredLanguage)
        }
        set { preferredAccountLanguageRaw = newValue.rawValue }
    }

    var preferredTone: ContentTone {
        get { ContentTone(rawValue: preferredToneRaw) ?? .direct }
        set { preferredToneRaw = newValue.rawValue }
    }

    var authProvider: AuthProvider {
        get { AuthProvider(rawValue: authProviderRaw) ?? .deviceMigration }
        set { authProviderRaw = newValue.rawValue }
    }

    var subscriptionPlan: SubscriptionPlan {
        get { SubscriptionPlan(rawValue: subscriptionPlanRaw) ?? .standard }
        set { subscriptionPlanRaw = newValue.rawValue }
    }

    var preferredPlatformEnums: [ContentPlatform] {
        preferredPlatforms.compactMap(ContentPlatform.init(rawValue:))
    }

    var goalEnums: [ContentGoal] {
        goals.compactMap(ContentGoal.init(rawValue:))
    }

    var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var hasPasswordLogin: Bool {
        !passwordHash.isEmpty
    }

    var hasAuthIdentity: Bool {
        !normalizedEmail.isEmpty || !appleUserID.isEmpty || !googleUserID.isEmpty
    }

    var promptContextBlock: String {
        var lines: [String] = []

        if !creatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Creator: \(creatorName)")
        }
        if !selectedNiches.isEmpty {
            lines.append("Niche: \(selectedNiches.joined(separator: ", "))")
        }
        if !defaultAudience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Target audience: \(defaultAudience)")
        }
        lines.append("Preferred tone: \(preferredTone.rawValue)")
        if let primaryPlatform = preferredPlatformEnums.first {
            lines.append("Primary platform: \(primaryPlatform.rawValue)")
        }
        if !goalEnums.isEmpty {
            lines.append("Content goals: \(goalEnums.map(\.rawValue).joined(separator: ", "))")
        }
        if !persistentPromptNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Persistent notes: \(persistentPromptNotes.trimmingCharacters(in: .whitespacesAndNewlines))")
        }

        return lines.joined(separator: "\n")
    }

    var snapshot: UserProfileSnapshot {
        UserProfileSnapshot(
            selectedNiches: selectedNiches,
            preferredPlatforms: preferredPlatforms,
            preferredLanguage: preferredLanguageRaw,
            preferredTone: preferredToneRaw,
            goals: goals,
            postingFrequency: postingFrequency,
            onboardingCompleted: onboardingCompleted,
            creatorName: creatorName,
            defaultAudience: defaultAudience,
            persistentPromptNotes: persistentPromptNotes
        )
    }
}
