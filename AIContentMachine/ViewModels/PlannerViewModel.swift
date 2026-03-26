import Foundation
import SwiftData

@MainActor
final class PlannerViewModel: ObservableObject {
    @Published var selectedDate: Date = .now

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

    func assign(project: ContentProject, to date: Date, existingAssignments: [PlannerAssignment], context: ModelContext) {
        let assignment = PlannerService.assign(project: project, to: date, existingAssignments: existingAssignments)
        if !existingAssignments.contains(where: { $0.id == assignment.id }) {
            context.insert(assignment)
        }

        project.status = .ready
        project.updatedAt = .now
        assignment.status = .ready
        assignment.projectTitle = project.title

        try? context.save()
    }

    func togglePosted(for assignment: PlannerAssignment, project: ContentProject?, context: ModelContext) {
        assignment.isPosted.toggle()
        assignment.status = assignment.isPosted ? .posted : .ready
        project?.status = assignment.isPosted ? .posted : .ready
        project?.updatedAt = .now
        try? context.save()
    }
}
