import Foundation

struct PlannerDay: Identifiable, Hashable {
    let id: Date
    let date: Date
    let assignments: [PlannerAssignment]

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

enum PlannerService {
    static func week(for referenceDate: Date, assignments: [PlannerAssignment]) -> [PlannerDay] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) ?? DateInterval(start: referenceDate, duration: 7 * 24 * 60 * 60)
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: interval.start) else { return nil }
            let dayAssignments = assignments
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .sorted(by: { $0.date < $1.date })
            return PlannerDay(id: calendar.startOfDay(for: date), date: date, assignments: dayAssignments)
        }
    }

    static func assign(project: ContentProject, to date: Date, existingAssignments: [PlannerAssignment]) -> PlannerAssignment {
        let calendar = Calendar.current
        if let existing = existingAssignments.first(where: { assignment in
            assignment.projectID == project.id && calendar.isDate(assignment.date, inSameDayAs: date)
        }) {
            return existing
        }

        return PlannerAssignment(
            date: calendar.startOfDay(for: date),
            projectID: project.id,
            projectTitle: project.title,
            status: project.status,
            isPosted: project.status == .posted,
            notes: ""
        )
    }

    static func streakCount(from assignments: [PlannerAssignment], referenceDate: Date = .now) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var cursor = calendar.startOfDay(for: referenceDate)

        while assignments.contains(where: { $0.isPosted && calendar.isDate($0.date, inSameDayAs: cursor) }) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }
}
