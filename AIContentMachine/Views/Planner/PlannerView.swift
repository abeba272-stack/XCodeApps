import SwiftUI
import SwiftData

struct PlannerView: View {
    @Environment(\.modelContext) private var modelContext
    let projects: [ContentProject]
    let assignments: [PlannerAssignment]

    @StateObject private var viewModel = PlannerViewModel()
    @State private var selectedPlannerDate: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeaderView(title: "Content calendar", subtitle: viewModel.weekLabel)
                        HStack {
                            Text("Current streak")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text("\(PlannerService.streakCount(from: assignments)) days")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.accentGlow)
                        }

                        DatePicker("Week focus", selection: $viewModel.selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }

                ForEach(viewModel.days(assignments: assignments)) { day in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(day.date.formatted(.dateTime.weekday(.wide)))
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(day.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                if day.isToday {
                                    TagChip(title: "Today", isSelected: true)
                                }
                            }

                            if day.assignments.isEmpty {
                                Button("Assign Draft") {
                                    selectedPlannerDate = day.date
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.accentGlow)
                            } else {
                                ForEach(day.assignments, id: \.id) { assignment in
                                    let linkedProject = projects.first(where: { $0.id == assignment.projectID })
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text(assignment.projectTitle)
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundStyle(AppTheme.textPrimary)
                                            Spacer()
                                            Button(assignment.isPosted ? "Posted" : "Mark Posted") {
                                                viewModel.togglePosted(for: assignment, project: linkedProject, context: modelContext)
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(assignment.isPosted ? .green : AppTheme.textSecondary)
                                        }
                                        Text(linkedProject?.platform.rawValue ?? "Unassigned")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(AppTheme.textSecondary)
                                        StatusBadge(status: assignment.status)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Planner")
        .sheet(item: Binding(
            get: {
                selectedPlannerDate.map { IdentifiedDate(date: $0) }
            },
            set: { selectedPlannerDate = $0?.date }
        )) { item in
            NavigationStack {
                PlannerAssignmentPicker(
                    date: item.date,
                    projects: projects.filter { $0.status != .posted && $0.status != .archived }
                ) { project in
                    viewModel.assign(project: project, to: item.date, existingAssignments: assignments, context: modelContext)
                    selectedPlannerDate = nil
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

private struct IdentifiedDate: Identifiable {
    let id = UUID()
    let date: Date
}

private struct PlannerAssignmentPicker: View {
    let date: Date
    let projects: [ContentProject]
    let onSelect: (ContentProject) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(projects, id: \.id) { project in
                Button {
                    onSelect(project)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text("\(project.platform.rawValue) • \(project.status.rawValue)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                }
            }
        }
        .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
    }
}
