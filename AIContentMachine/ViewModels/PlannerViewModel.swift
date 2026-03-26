import Foundation
import SwiftData

@MainActor
final class PlannerViewModel: ObservableObject {
    @Published var selectedDate: Date = .now

    var weekLabel: String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 7 * 24 * 60 * 60)
        return formatter.string(from: interval.start, to: interval.end.addingTimeInterval(-1))
    }

    func days(assignments: [PlannerAssignment]) -> [PlannerDay] {
        PlannerService.week(for: selectedDate, assignments: assignments)
    }

    func assign(project: ContentProject, to date: Date, existingAssignments: [PlannerAssignment], context: ModelContext) {
        let assignment = PlannerService.assign(project: project, to: date, existingAssignments: existingAssignments)
        if !existingAssignments.contains(where: { $0.id == assignment.id }) {
            context.insert(assignment)
        }

        project.status = .ready
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
