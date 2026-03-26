import Foundation

struct DashboardMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var greeting: String = "Hello"
    @Published private(set) var dailyPrompt: String = ""
    @Published private(set) var suggestedIdea: String = ""
    @Published private(set) var pipelineCounts: [ProjectStatus: Int] = [:]
    @Published private(set) var weeklyProgress: Double = 0
    @Published private(set) var categoriesOverview: [String: Int] = [:]
    @Published private(set) var metrics: [DashboardMetric] = []

    func refresh(profile: UserProfile, projects: [ContentProject], assignments: [PlannerAssignment], templates: [TemplateModel]) {
        greeting = makeGreeting(for: profile)
        dailyPrompt = DailyPromptProvider.prompt(for: .now, niches: profile.selectedNiches, language: profile.preferredLanguage)
        suggestedIdea = buildSuggestedIdea(profile: profile)

        pipelineCounts = Dictionary(grouping: projects, by: \.status).mapValues(\.count)
        categoriesOverview = Dictionary(grouping: projects, by: \.category).mapValues(\.count)

        let weeklyGoal = max(profile.postingFrequency, 1)
        let postedThisWeek = assignments.filter {
            Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) && $0.isPosted
        }.count
        weeklyProgress = min(Double(postedThisWeek) / Double(weeklyGoal), 1)

        metrics = [
            DashboardMetric(title: "Drafts", value: "\(projects.filter { $0.status == .draft }.count)", subtitle: "Saved drafts"),
            DashboardMetric(title: "Ready", value: "\(projects.filter { $0.status == .ready }.count)", subtitle: "Ready to post"),
            DashboardMetric(title: "Templates", value: "\(templates.filter(\.isFavorite).count)", subtitle: "Favorite templates"),
            DashboardMetric(title: "Streak", value: "\(PlannerService.streakCount(from: assignments))", subtitle: "Posting streak")
        ]
    }

    private func makeGreeting(for profile: UserProfile) -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        let salutation: String
        switch hour {
        case 5..<12: salutation = "Good morning"
        case 12..<18: salutation = "Good afternoon"
        default: salutation = "Good evening"
        }
        return "\(salutation), \(profile.creatorName)"
    }

    private func buildSuggestedIdea(profile: UserProfile) -> String {
        let niche = profile.selectedNiches.first ?? "your niche"
        let platform = profile.preferredPlatformEnums.first ?? .tiktok
        let goal = profile.goalEnums.first ?? .views
        return "Create a \(platform.rawValue) piece about \(niche) framed around a strong tension point that drives \(goal.rawValue.lowercased())."
    }
}
