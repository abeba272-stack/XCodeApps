import Foundation
import SwiftData

@MainActor
final class SwiftDataStore: PersistenceService, SettingsService {
    private let modelContainer: ModelContainer
    private let logger: any AppLogger

    init(modelContainer: ModelContainer, logger: any AppLogger) {
        self.modelContainer = modelContainer
        self.logger = logger
    }

    func saveDraft(from session: GenerationSession) throws -> ContentProject {
        let context = modelContainer.mainContext
        let project = try existingProject(for: session) ?? session.asContentProject()

        if project.modelContext == nil {
            context.insert(project)
        }

        apply(session, to: project)
        project.updatedAt = .now
        project.status = session.generationMode == .singleIdea ? .idea : .draft

        do {
            try context.save()
            session.savedProjectID = project.id
            session.hasSavedDraft = true
            session.status = project.status
            return project
        } catch {
            logger.error("Saving draft failed: \(error.localizedDescription)", category: "SwiftDataStore")
            throw AppError.persistence("The draft could not be saved.")
        }
    }

    func duplicateDraft(from session: GenerationSession) throws -> ContentProject {
        let context = modelContainer.mainContext
        let project = session.asContentProject(newID: UUID())
        context.insert(project)

        do {
            try context.save()
            return project
        } catch {
            logger.error("Duplicating draft failed: \(error.localizedDescription)", category: "SwiftDataStore")
            throw AppError.persistence("The draft copy could not be saved.")
        }
    }

    func persistFavoriteState(for session: GenerationSession) throws {
        guard let project = try existingProject(for: session) else { return }
        project.isFavorite = session.isFavorite

        do {
            try modelContainer.mainContext.save()
        } catch {
            logger.error("Persisting favorite state failed: \(error.localizedDescription)", category: "SwiftDataStore")
            throw AppError.persistence("The favorite state could not be saved.")
        }
    }

    func clearLocalData(projects: [ContentProject], assignments: [PlannerAssignment]) throws {
        let context = modelContainer.mainContext
        projects.forEach(context.delete)
        assignments.forEach(context.delete)

        do {
            try context.save()
        } catch {
            logger.error("Clearing local data failed: \(error.localizedDescription)", category: "SwiftDataStore")
            throw AppError.persistence("Local data could not be cleared.")
        }
    }

    func resetOnboarding(profile: UserProfile) throws {
        profile.onboardingCompleted = false

        do {
            try modelContainer.mainContext.save()
        } catch {
            logger.error("Resetting onboarding failed: \(error.localizedDescription)", category: "SwiftDataStore")
            throw AppError.persistence("Onboarding could not be reset.")
        }
    }

    func assign(project: ContentProject, to date: Date, existingAssignments: [PlannerAssignment]) throws -> PlannerAssignment {
        let context = modelContainer.mainContext
        let assignment = PlannerService.assign(project: project, to: date, existingAssignments: existingAssignments)

        if !existingAssignments.contains(where: { $0.id == assignment.id }) {
            context.insert(assignment)
        }

        project.status = .ready
        project.updatedAt = .now
        assignment.status = .ready
        assignment.projectTitle = project.title

        do {
            try context.save()
            return assignment
        } catch {
            logger.error("Assigning planner slot failed: \(error.localizedDescription)", category: "SwiftDataStore")
            throw AppError.persistence("The project could not be assigned to the planner.")
        }
    }

    func togglePosted(for assignment: PlannerAssignment, project: ContentProject?) throws {
        assignment.isPosted.toggle()
        assignment.status = assignment.isPosted ? .posted : .ready
        project?.status = assignment.isPosted ? .posted : .ready
        project?.updatedAt = .now

        do {
            try modelContainer.mainContext.save()
        } catch {
            logger.error("Updating posted state failed: \(error.localizedDescription)", category: "SwiftDataStore")
            throw AppError.persistence("The posting state could not be updated.")
        }
    }

    func loadDraft(profile: UserProfile, settings: AppSettings) -> SettingsDraft {
        SettingsDraft(
            email: profile.email,
            creatorName: profile.creatorName,
            nichesText: profile.selectedNiches.joined(separator: ", "),
            defaultAudience: profile.defaultAudience,
            persistentPromptNotes: profile.persistentPromptNotes,
            selectedPlatforms: Set(profile.preferredPlatformEnums),
            selectedLanguage: profile.preferredLanguage,
            selectedTone: profile.preferredTone,
            selectedGoals: Set(profile.goalEnums),
            postingFrequency: Double(profile.postingFrequency),
            theme: settings.theme,
            providerMode: settings.providerMode,
            localServerEndpoint: settings.localServerEndpoint
        )
    }

    func saveDraft(profile: UserProfile, settings: AppSettings, draft: SettingsDraft) throws {
        profile.creatorName = draft.creatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Creator" : draft.creatorName
        profile.selectedNiches = draft.nichesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        profile.defaultAudience = draft.defaultAudience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Creators who want better short-form content"
            : draft.defaultAudience.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.persistentPromptNotes = draft.persistentPromptNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.preferredPlatforms = draft.selectedPlatforms.map(\.rawValue).sorted()
        profile.preferredLanguage = draft.selectedLanguage
        profile.preferredTone = draft.selectedTone
        profile.goals = draft.selectedGoals.map(\.rawValue).sorted()
        profile.postingFrequency = Int(draft.postingFrequency)

        settings.theme = draft.theme
        settings.providerMode = draft.providerMode
        settings.localServerEndpoint = draft.localServerEndpoint
        settings.apiKey = ""
        settings.apiModel = ""

        do {
            try modelContainer.mainContext.save()
        } catch {
            logger.error("Saving settings failed: \(error.localizedDescription)", category: "SwiftDataStore")
            throw AppError.settings("Settings could not be saved.")
        }
    }

    private func existingProject(for session: GenerationSession) throws -> ContentProject? {
        guard let savedProjectID = session.savedProjectID else { return nil }
        let descriptor = FetchDescriptor<ContentProject>(
            predicate: #Predicate { project in
                project.id == savedProjectID
            }
        )

        return try modelContainer.mainContext.fetch(descriptor).first
    }

    private func apply(_ session: GenerationSession, to project: ContentProject) {
        project.createdAt = session.createdAt
        project.updatedAt = session.updatedAt
        project.title = session.title
        project.topic = session.topic
        project.category = session.category
        project.platform = session.platform
        project.audience = session.audience
        project.tone = session.tone
        project.language = session.language
        project.goal = session.goal
        project.style = session.style
        project.durationSeconds = session.durationSeconds
        project.generationMode = session.generationMode
        project.status = session.status
        project.isFavorite = session.isFavorite
        project.contentAngle = session.contentAngle
        project.audienceSummary = session.audienceSummary
        project.overview = session.overview
        project.hook = session.hook
        project.alternateHooks = session.alternateHooks
        project.script = session.script
        project.voiceover = session.voiceover
        project.caption = session.caption
        project.hashtags = session.hashtags
        project.cta = session.cta
        project.shotList = session.shotList
        project.notes = session.notes
        project.performanceRationale = session.performanceRationale
        project.bestPostingTime = session.bestPostingTime
        project.emotionalTrigger = session.emotionalTrigger
        project.templateUsed = session.templateUsed
        project.batchIdeas = session.batchIdeas
        project.thumbnailSuggestions = session.thumbnailSuggestions
        project.postingChecklist = session.postingChecklist
        project.postingTip = session.postingTip
        project.contentScore = session.contentScore
    }
}

struct DefaultExportService: ExportService {
    func formattedPackage(for session: GenerationSession) -> String {
        CopyExportService.formattedPackage(for: session)
    }

    func videoPrompt(for session: GenerationSession) -> String {
        CopyExportService.videoPromptText(for: session)
    }

    func sectionText(for section: ContentSection, session: GenerationSession) -> String {
        CopyExportService.sectionText(for: section, session: session)
    }

    func exportWorkspace(profile: UserProfile, settings: AppSettings, projects: [ContentProject], assignments: [PlannerAssignment]) throws -> URL {
        try CopyExportService.exportURL(profile: profile, settings: settings, projects: projects, assignments: assignments)
    }
}
