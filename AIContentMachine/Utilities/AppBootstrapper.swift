import Foundation
import SwiftData

@MainActor
enum AppBootstrapper {
    static let nichePresets = [
        "Mental Health",
        "Self Improvement",
        "Anime",
        "Gaming",
        "Business",
        "Motivation",
        "Storytelling",
        "Education"
    ]

    static func bootstrap(in context: ModelContext) throws {
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        if profiles.isEmpty {
            context.insert(UserProfile())
        }

        let settings = try context.fetch(FetchDescriptor<AppSettings>())
        let activeSettings: AppSettings
        if let existingSettings = settings.first {
            activeSettings = existingSettings
        } else {
            let newSettings = AppSettings()
            context.insert(newSettings)
            activeSettings = newSettings
        }

        TemplateSeedService.seedStarterTemplates(in: context, settings: activeSettings)

        try context.save()
    }

    static func importSampleData(context: ModelContext, profile: UserProfile) async throws {
        let service = MockContentGenerationService()
        let requests: [GenerationRequest] = [
            GenerationRequest(
                topic: "Why people stay stuck even when they know what to do",
                platform: .tiktok,
                category: profile.selectedNiches.first ?? "Self Improvement",
                audience: "Creators who want more consistency",
                tone: profile.preferredTone,
                language: profile.preferredLanguage,
                goal: .engagement,
                style: .controversialOpinion,
                durationSeconds: 35,
                mode: .fullPackage,
                template: TemplateEngine.makeDefaultTemplates().first
            ),
            GenerationRequest(
                topic: "The one mindset shift that improves content quality",
                platform: .instagramReels,
                category: profile.selectedNiches.dropFirst().first ?? "Education",
                audience: "Ambitious solo founders",
                tone: .educational,
                language: profile.preferredLanguage,
                goal: .authority,
                style: .tutorial,
                durationSeconds: 30,
                mode: .fullPackage,
                template: TemplateEngine.makeDefaultTemplates().dropFirst().first
            )
        ]

        for request in requests {
            let generated = try await service.generateContent(for: request)
            let project = ContentProject.from(request: request, generated: generated)
            context.insert(project)
        }

        if let firstProject = try context.fetch(FetchDescriptor<ContentProject>()).first {
            let monday = Calendar.current.startOfDay(for: .now)
            let assignment = PlannerAssignment(
                date: monday,
                projectID: firstProject.id,
                projectTitle: firstProject.title,
                status: .ready,
                notes: "Imported sample slot"
            )
            context.insert(assignment)
        }

        try context.save()
    }
}
