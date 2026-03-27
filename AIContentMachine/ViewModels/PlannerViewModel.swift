import Foundation

@MainActor
final class PlannerViewModel: ObservableObject {
    @Published var selectedDate: Date = .now
    @Published var errorMessage: String?

    private let assignProjectUseCase: AssignProjectUseCase
    private let togglePostedUseCase: TogglePostedUseCase
    private let logger: any AppLogger

    init(
        assignProjectUseCase: AssignProjectUseCase,
        togglePostedUseCase: TogglePostedUseCase,
        logger: any AppLogger
    ) {
        self.assignProjectUseCase = assignProjectUseCase
        self.togglePostedUseCase = togglePostedUseCase
        self.logger = logger
    }

    var weekLabel: String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let interval = PlannerService.weekInterval(for: selectedDate)
        return formatter.string(from: interval.start, to: interval.end.addingTimeInterval(-1))
    }

    func days(assignments: [PlannerAssignment]) -> [PlannerDay] {
        PlannerService.week(for: selectedDate, assignments: assignments)
    }

    func shiftWeek(by offset: Int) {
        if let next = Calendar.current.date(byAdding: .day, value: offset * 7, to: selectedDate) {
            selectedDate = next
        }
    }

    func selectedDay(assignments: [PlannerAssignment]) -> PlannerDay? {
        days(assignments: assignments).first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })
    }

    func backlogProjects(from projects: [ContentProject], assignments: [PlannerAssignment]) -> [ContentProject] {
        let scheduledIDs = PlannerService.scheduledProjectIDs(inWeekOf: selectedDate, assignments: assignments)
        return projects
            .filter { ($0.status == .draft || $0.status == .ready || $0.status == .idea) && !scheduledIDs.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.contentScore == rhs.contentScore { return lhs.updatedAt > rhs.updatedAt }
                return lhs.contentScore > rhs.contentScore
            }
    }

    func assign(project: ContentProject, to date: Date, existingAssignments: [PlannerAssignment]) {
        do {
            _ = try assignProjectUseCase.execute(project: project, date: date, existingAssignments: existingAssignments)
        } catch {
            logger.error("Assign project failed: \(error.localizedDescription)", category: "PlannerViewModel")
            errorMessage = AppError.from(error, fallback: "The project could not be assigned.").localizedDescription
        }
    }

    func togglePosted(for assignment: PlannerAssignment, project: ContentProject?) {
        do {
            try togglePostedUseCase.execute(assignment: assignment, project: project)
        } catch {
            logger.error("Toggle posted failed: \(error.localizedDescription)", category: "PlannerViewModel")
            errorMessage = AppError.from(error, fallback: "The posting state could not be updated.").localizedDescription
        }
    }
}
