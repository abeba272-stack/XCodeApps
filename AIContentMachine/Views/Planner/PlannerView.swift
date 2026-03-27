import SwiftUI

struct PlannerView: View {
    let projects: [ContentProject]
    let assignments: [PlannerAssignment]
    let container: AppContainer

    @StateObject private var viewModel: PlannerViewModel
    @State private var selectedPlannerDate: Date?

    init(projects: [ContentProject], assignments: [PlannerAssignment], container: AppContainer) {
        self.projects = projects
        self.assignments = assignments
        self.container = container
        _viewModel = StateObject(wrappedValue: container.makePlannerViewModel())
    }

    private var weekDays: [PlannerDay] {
        viewModel.days(assignments: assignments)
    }

    private var selectedDay: PlannerDay? {
        viewModel.selectedDay(assignments: assignments)
    }

    private var backlogProjects: [ContentProject] {
        viewModel.backlogProjects(from: projects, assignments: assignments)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard
                weekStrip
                selectedDayCard
                backlogCard
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .navigationTitle("Planner")
        .sheet(item: Binding(
            get: { selectedPlannerDate.map(IdentifiedDate.init(date:)) },
            set: { selectedPlannerDate = $0?.date }
        )) { item in
            NavigationStack {
                PlannerAssignmentPicker(
                    date: item.date,
                    projects: projects.filter { $0.status != .posted && $0.status != .archived }
                ) { project in
                    viewModel.assign(project: project, to: item.date, existingAssignments: assignments)
                    selectedPlannerDate = nil
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Planner", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var headerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content calendar")
                            .font(.system(size: 29, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(viewModel.weekLabel)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    TagChip(title: "Streak \(PlannerService.streakCount(from: assignments))", isSelected: true, icon: "flame.fill")
                }

                HStack(spacing: 12) {
                    plannerMetric(title: "Due Today", value: "\(assignments.filter { Calendar.current.isDateInToday($0.date) && !$0.isPosted }.count)", subtitle: "Scheduled posts")
                    plannerMetric(title: "Ready Backlog", value: "\(projects.filter { $0.status == .ready }.count)", subtitle: "Ready to assign")
                    plannerMetric(title: "Posted", value: "\(assignments.filter(\.isPosted).count)", subtitle: "Logged in planner")
                }

                HStack(spacing: 10) {
                    Button {
                        viewModel.shiftWeek(by: -1)
                    } label: {
                        Label("Prev Week", systemImage: "chevron.left")
                    }
                    .buttonStyle(AppSecondaryButtonStyle())

                    Button {
                        viewModel.selectedDate = .now
                    } label: {
                        Text("Today")
                    }
                    .buttonStyle(AppQuietButtonStyle())

                    Button {
                        viewModel.shiftWeek(by: 1)
                    } label: {
                        Label("Next Week", systemImage: "chevron.right")
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                }
            }
        }
    }

    private func plannerMetric(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var weekStrip: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(
                    title: "Week view",
                    subtitle: "Tap a day to inspect the schedule or assign a project.",
                    eyebrow: "Schedule"
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(weekDays) { day in
                            Button {
                                viewModel.selectedDate = day.date
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundStyle(AppTheme.textMuted)

                                    Text(day.date.formatted(.dateTime.day()))
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(day.isToday || Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate) ? Color.black : AppTheme.textPrimary)

                                    Text(day.assignments.isEmpty ? "Open" : "\(day.assignments.count) item\(day.assignments.count == 1 ? "" : "s")")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(day.isToday || Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate) ? Color.black.opacity(0.72) : AppTheme.textSecondary)
                                }
                                .padding(16)
                                .frame(width: 104, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                                        .fill(
                                            Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate)
                                                ? AnyShapeStyle(AppTheme.accentGradient)
                                                : AnyShapeStyle(AppTheme.surfaceSecondary)
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                                        .stroke(AppTheme.border, lineWidth: Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate) ? 0 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var selectedDayCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: selectedDay?.date.formatted(.dateTime.weekday(.wide)) ?? "Selected day",
                    subtitle: selectedDay?.date.formatted(date: .abbreviated, time: .omitted),
                    eyebrow: "Day Plan",
                    actionTitle: "Assign",
                    action: { selectedPlannerDate = selectedDay?.date ?? viewModel.selectedDate }
                )

                if let selectedDay, !selectedDay.assignments.isEmpty {
                    ForEach(selectedDay.assignments, id: \.id) { assignment in
                        let linkedProject = projects.first(where: { $0.id == assignment.projectID })
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(assignment.projectTitle)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(linkedProject?.platform.rawValue ?? "Manual item")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                StatusBadge(status: assignment.status)
                            }

                            if let hook = linkedProject?.hook, !hook.isEmpty {
                                Text(hook)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(2)
                            }

                            HStack(spacing: 10) {
                                if assignment.isPosted {
                                    Button("Posted") {
                                        viewModel.togglePosted(for: assignment, project: linkedProject)
                                    }
                                    .buttonStyle(AppQuietButtonStyle())
                                } else {
                                    Button("Mark Posted") {
                                        viewModel.togglePosted(for: assignment, project: linkedProject)
                                    }
                                    .buttonStyle(AppSecondaryButtonStyle())
                                }

                                if let linkedProject {
                                    NavigationLink {
                                        ContentDetailView(project: linkedProject)
                                    } label: {
                                        Label("Open", systemImage: "arrow.up.right")
                                    }
                                    .buttonStyle(AppQuietButtonStyle())
                                }
                            }
                        }
                        .padding(16)
                        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                    }
                } else {
                    EmptyStateView(
                        title: "Nothing scheduled here",
                        message: "Assign a draft or ready package to this day so your week has a clear publishing cadence.",
                        buttonTitle: "Assign Project",
                        action: { selectedPlannerDate = selectedDay?.date ?? viewModel.selectedDate },
                        icon: "calendar.badge.plus",
                        eyebrow: "Open Slot"
                    )
                }
            }
        }
    }

    private var backlogCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: "Unscheduled backlog",
                    subtitle: "Drafts and ready projects not yet placed into the current week.",
                    eyebrow: "Queue"
                )

                if backlogProjects.isEmpty {
                    Text("Everything for this week is already scheduled. Either generate a new package or move to next week.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    ForEach(backlogProjects.prefix(4), id: \.id) { project in
                        HStack(alignment: .top, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(project.title)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("\(project.platform.rawValue) • Score \(project.contentScore)")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer(minLength: 0)

                            Button("Add") {
                                let targetDate = selectedDay?.date ?? viewModel.selectedDate
                                viewModel.assign(project: project, to: targetDate, existingAssignments: assignments)
                            }
                            .buttonStyle(AppQuietButtonStyle())
                        }
                        .padding(14)
                        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                    }
                }
            }
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
    @State private var searchText = ""

    private var filteredProjects: [ContentProject] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return projects
        }

        let needle = searchText.lowercased()
        return projects.filter {
            $0.title.lowercased().contains(needle)
                || $0.topic.lowercased().contains(needle)
                || $0.category.lowercased().contains(needle)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(filteredProjects, id: \.id) { project in
                    Button {
                        onSelect(project)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(project.title)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                StatusBadge(status: project.status)
                            }
                            Text("\(project.platform.rawValue) • \(project.category) • Score \(project.contentScore)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(project.hook)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textMuted)
                                .lineLimit(2)
                        }
                        .padding(16)
                        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppTheme.screenPadding)
        }
        .background(PremiumBackground())
        .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
        .searchable(text: $searchText, prompt: "Search project to assign")
    }
}
