import Foundation
import SwiftUI

struct DashboardMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let accent: Color
}

struct DashboardCategoryInsight: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let share: Double
}

struct DashboardFocusItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var greeting: String = "Hello"
    @Published private(set) var dailyPrompt: String = ""
    @Published private(set) var suggestedIdea: String = ""
    @Published private(set) var pipelineCounts: [ProjectStatus: Int] = [:]
    @Published private(set) var weeklyProgress: Double = 0
    @Published private(set) var weeklyGoal: Int = 1
    @Published private(set) var postedThisWeek: Int = 0
    @Published private(set) var metrics: [DashboardMetric] = []
    @Published private(set) var topCategories: [DashboardCategoryInsight] = []
    @Published private(set) var todayFocusItems: [DashboardFocusItem] = []
    @Published private(set) var nextPublishingWindow: String = ""
    @Published private(set) var bestPerformerTitle: String = ""
    @Published private(set) var bestPerformerScore: Int = 0
    @Published private(set) var focusSummary: String = ""

    func refresh(profile: UserProfile, projects: [ContentProject], assignments: [PlannerAssignment], templates: [TemplateModel]) {
        greeting = makeGreeting(for: profile)
        dailyPrompt = DailyPromptProvider.prompt(for: .now, niches: profile.selectedNiches, language: profile.preferredLanguage)

        pipelineCounts = Dictionary(grouping: projects, by: \.status).mapValues(\.count)
        weeklyGoal = max(profile.postingFrequency, 1)
        postedThisWeek = assignments.filter {
            Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) && $0.isPosted
        }.count
        weeklyProgress = min(Double(postedThisWeek) / Double(weeklyGoal), 1)

        let readyCount = projects.filter { $0.status == .ready }.count
        let draftCount = projects.filter { $0.status == .draft }.count
        let todayAssignments = assignmentsForToday(assignments)
        let favoriteTemplates = templates.filter(\.isFavorite).count
        let streak = PlannerService.streakCount(from: assignments)

        suggestedIdea = buildSuggestedIdea(profile: profile, projects: projects, todayAssignments: todayAssignments)
        nextPublishingWindow = nextWindow(from: assignments, projects: projects)

        if let bestProject = projects.max(by: { $0.contentScore < $1.contentScore }) {
            bestPerformerTitle = bestProject.title
            bestPerformerScore = bestProject.contentScore
        } else {
            bestPerformerTitle = profile.preferredLanguage == .german ? "Noch kein High Performer" : "No high performer yet"
            bestPerformerScore = 0
        }

        focusSummary = makeFocusSummary(readyCount: readyCount, todayAssignments: todayAssignments.count, draftCount: draftCount)

        metrics = [
            DashboardMetric(title: "Draft Queue", value: "\(draftCount)", subtitle: "Ideas waiting for refinement", accent: AppTheme.warning),
            DashboardMetric(title: "Ready To Ship", value: "\(readyCount)", subtitle: "Packages that can post next", accent: AppTheme.success),
            DashboardMetric(title: "Posted This Week", value: "\(postedThisWeek)/\(weeklyGoal)", subtitle: "Weekly publishing goal", accent: AppTheme.accentGlow),
            DashboardMetric(title: "Pinned Templates", value: "\(favoriteTemplates)", subtitle: "Fast repeatable formats", accent: AppTheme.accentSecondary)
        ]

        let groupedCategories = Dictionary(grouping: projects, by: \.category)
            .map { DashboardCategoryInsight(name: $0.key, count: $0.value.count, share: Double($0.value.count) / Double(max(projects.count, 1))) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count { return lhs.name < rhs.name }
                return lhs.count > rhs.count
            }
        topCategories = Array(groupedCategories.prefix(4))

        todayFocusItems = [
            DashboardFocusItem(
                title: todayAssignments.isEmpty ? "No shoot scheduled" : "\(todayAssignments.count) scheduled today",
                subtitle: todayAssignments.first?.projectTitle ?? "Use the planner to lock the next publishing slot.",
                icon: todayAssignments.isEmpty ? "calendar.badge.plus" : "calendar.badge.clock",
                accent: todayAssignments.isEmpty ? AppTheme.warning : AppTheme.accentGlow
            ),
            DashboardFocusItem(
                title: "\(streak) day streak",
                subtitle: streak == 0 ? "A single post today restarts momentum." : "Consistency is compounding. Protect the streak.",
                icon: "flame.fill",
                accent: AppTheme.success
            ),
            DashboardFocusItem(
                title: bestPerformerTitle,
                subtitle: bestPerformerScore == 0 ? "Generate a stronger package and save it." : "Top score in your local content machine: \(bestPerformerScore)",
                icon: "sparkles",
                accent: AppTheme.accentSecondary
            )
        ]
    }

    private func assignmentsForToday(_ assignments: [PlannerAssignment]) -> [PlannerAssignment] {
        assignments
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted(by: { $0.date < $1.date })
    }

    private func nextWindow(from assignments: [PlannerAssignment], projects: [ContentProject]) -> String {
        if let nextAssignment = assignments
            .filter({ $0.date >= Calendar.current.startOfDay(for: .now) && !$0.isPosted })
            .sorted(by: { $0.date < $1.date })
            .first {
            let dateLabel = nextAssignment.date.formatted(.dateTime.weekday(.wide))
            return "\(dateLabel): \(nextAssignment.projectTitle)"
        }

        if let readyProject = projects
            .filter({ $0.status == .ready || $0.status == .draft })
            .sorted(by: { $0.contentScore > $1.contentScore })
            .first {
            return "Next best move: ship \(readyProject.title)"
        }

        return "Build one fresh package and place it on the planner."
    }

    private func makeGreeting(for profile: UserProfile) -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        let salutation: String
        switch hour {
        case 5..<12:
            salutation = "Good morning"
        case 12..<18:
            salutation = "Good afternoon"
        default:
            salutation = "Good evening"
        }

        return "\(salutation), \(profile.creatorName)"
    }

    private func buildSuggestedIdea(profile: UserProfile, projects: [ContentProject], todayAssignments: [PlannerAssignment]) -> String {
        let niche = profile.selectedNiches.first ?? "your niche"
        let platform = profile.preferredPlatformEnums.first ?? .tiktok
        let goal = profile.goalEnums.first ?? .views

        if let lastProject = projects.first {
            return "Take the same core tension as “\(lastProject.title)” and turn it into a sharper \(platform.rawValue) sequel for \(goal.rawValue.lowercased())."
        }

        if let scheduled = todayAssignments.first {
            return "Record a fast supporting angle for \(scheduled.projectTitle) so today’s post has a follow-up ready."
        }

        return "Create a \(platform.rawValue) piece about \(niche) that starts with a tension-heavy hook and ends with a clear next step for \(goal.rawValue.lowercased())."
    }

    private func makeFocusSummary(readyCount: Int, todayAssignments: Int, draftCount: Int) -> String {
        if readyCount > 0 && todayAssignments == 0 {
            return "You already have publishable material. The planner is the current bottleneck."
        }
        if draftCount > readyCount {
            return "Most of your pipeline is stuck in drafts. Tightening one existing piece will move faster than generating more."
        }
        if todayAssignments > 0 {
            return "Your next publishing slot is defined. Focus on making that one post undeniable."
        }
        return "Generate one strong package, save it, and lock it into the week before exploring new ideas."
    }
}
