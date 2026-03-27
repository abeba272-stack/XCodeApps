import XCTest
@testable import AIContentMachine

final class PlannerServiceTests: XCTestCase {
    func testAssignReturnsExistingAssignmentForSameProjectAndDay() {
        let project = makeProject(title: "Daily hook", status: .draft)
        let date = Calendar.current.startOfDay(for: .now)
        let existing = PlannerAssignment(date: date, projectID: project.id, projectTitle: project.title, status: .ready)

        let assignment = PlannerService.assign(project: project, to: date, existingAssignments: [existing])

        XCTAssertEqual(assignment.id, existing.id)
    }

    func testStreakCountStopsOnGap() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        let assignments = [
            PlannerAssignment(date: today, status: .posted, isPosted: true),
            PlannerAssignment(date: yesterday, status: .posted, isPosted: true),
            PlannerAssignment(date: threeDaysAgo, status: .posted, isPosted: true)
        ]

        XCTAssertEqual(PlannerService.streakCount(from: assignments, referenceDate: today), 2)
    }

    private func makeProject(title: String, status: ProjectStatus) -> ContentProject {
        ContentProject(
            title: title,
            topic: "topic",
            category: "General",
            platform: .tiktok,
            audience: "Creators",
            tone: .direct,
            language: .english,
            goal: .views,
            style: .educational,
            durationSeconds: 30,
            generationMode: .fullPackage,
            status: status,
            contentAngle: "",
            audienceSummary: "",
            overview: "",
            hook: "",
            alternateHooks: [],
            script: "",
            voiceover: "",
            caption: "",
            hashtags: [],
            cta: "",
            shotList: [],
            notes: "",
            performanceRationale: "",
            bestPostingTime: "",
            emotionalTrigger: "",
            templateUsed: nil,
            batchIdeas: [],
            thumbnailSuggestions: [],
            postingChecklist: [],
            postingTip: "",
            contentScore: 0
        )
    }
}
