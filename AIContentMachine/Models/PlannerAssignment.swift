import Foundation
import SwiftData

@Model
final class PlannerAssignment {
    @Attribute(.unique) var id: UUID
    var date: Date
    var projectID: UUID?
    var projectTitle: String
    var statusRaw: String
    var isPosted: Bool
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date,
        projectID: UUID? = nil,
        projectTitle: String = "",
        status: ProjectStatus = .idea,
        isPosted: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.projectID = projectID
        self.projectTitle = projectTitle
        self.statusRaw = status.rawValue
        self.isPosted = isPosted
        self.notes = notes
    }
}

extension PlannerAssignment {
    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .idea }
        set { statusRaw = newValue.rawValue }
    }

    var snapshot: PlannerAssignmentSnapshot {
        PlannerAssignmentSnapshot(
            id: id,
            date: date,
            projectID: projectID,
            projectTitle: projectTitle,
            status: statusRaw,
            isPosted: isPosted
        )
    }
}
