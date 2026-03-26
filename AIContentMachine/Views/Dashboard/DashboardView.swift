import SwiftUI

struct DashboardView: View {
    let profile: UserProfile
    let settings: AppSettings
    let projects: [ContentProject]
    let templates: [TemplateModel]
    let assignments: [PlannerAssignment]
    let onCreateContent: () -> Void
    let onOpenPlanner: () -> Void
    let onOpenLibrary: () -> Void

    @StateObject private var viewModel = DashboardViewModel()
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                metricsGrid
                focusDeck
                publishingCard
                pipelineCard
                recentProjectsCard
                favoriteTemplatesCard
                categoriesCard
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(profile: profile, settings: settings, projects: projects, assignments: assignments)
            }
            .presentationDetents([.large])
        }
        .onAppear {
            refresh()
        }
        .onChange(of: projectRefreshKey) { _, _ in refresh() }
        .onChange(of: assignmentRefreshKey) { _, _ in refresh() }
        .onChange(of: templateRefreshKey) { _, _ in refresh() }
    }

    private var hero: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.greeting)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Create better content faster")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    TagChip(title: settings.providerMode.rawValue, isSelected: true, icon: "bolt.horizontal.fill")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested Move")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)

                    Text(viewModel.suggestedIdea)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(viewModel.focusSummary)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                HStack(spacing: 10) {
                    Button("Create Content", action: onCreateContent)
                        .buttonStyle(AppPrimaryButtonStyle())

                    Button("Planner", action: onOpenPlanner)
                        .buttonStyle(AppSecondaryButtonStyle())
                }

                HStack(spacing: 10) {
                    buttonChip(title: "Library", icon: "square.stack.3d.up.fill", action: onOpenLibrary)
                    buttonChip(title: "Prompt", icon: "sparkles", action: onCreateContent)
                    buttonChip(title: "Settings", icon: "slider.horizontal.3", action: { showSettings = true })
                }
            }
        }
    }

    private func buttonChip(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
        .buttonStyle(AppQuietButtonStyle())
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(viewModel.metrics) { metric in
                MetricCard(title: metric.title, value: metric.value, subtitle: metric.subtitle, accent: metric.accent)
            }
        }
    }

    private var focusDeck: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: "Today’s command deck",
                    subtitle: "The next actions that keep the machine moving.",
                    eyebrow: "Focus"
                )

                ForEach(viewModel.todayFocusItems) { item in
                    HStack(alignment: .top, spacing: 14) {
                        Circle()
                            .fill(item.accent.opacity(0.16))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: item.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(item.accent)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(item.subtitle)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer(minLength: 0)
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

    private var publishingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: "Publishing rhythm",
                    subtitle: "Local planner momentum and today’s creator challenge.",
                    eyebrow: "Planner"
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily prompt")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                    Text(viewModel.dailyPrompt)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Weekly goal")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text("\(viewModel.postedThisWeek) / \(viewModel.weeklyGoal)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    ProgressView(value: viewModel.weeklyProgress)
                        .tint(AppTheme.accentGlow)
                    Text(viewModel.nextPublishingWindow)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private var pipelineCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: "Pipeline health",
                    subtitle: "A quick read on where content is stacking up.",
                    eyebrow: "Status"
                )

                HStack(spacing: 12) {
                    pipelineMetric(for: .idea)
                    pipelineMetric(for: .draft)
                    pipelineMetric(for: .ready)
                    pipelineMetric(for: .posted)
                }
            }
        }
    }

    private func pipelineMetric(for status: ProjectStatus) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(status.rawValue)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(status.color)
            Text("\(viewModel.pipelineCounts[status, default: 0])")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var recentProjectsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: "Recent projects",
                    subtitle: "Resume work quickly or ship the strongest piece next.",
                    eyebrow: "Library",
                    actionTitle: projects.isEmpty ? nil : "Open Library",
                    action: projects.isEmpty ? nil : onOpenLibrary
                )

                if projects.isEmpty {
                    EmptyStateView(
                        title: "No projects yet",
                        message: "Create your first content package to start building a repeatable pipeline.",
                        buttonTitle: "Create Content",
                        action: onCreateContent,
                        icon: "wand.and.stars",
                        eyebrow: "Start"
                    )
                } else {
                    ForEach(projects.prefix(3), id: \.id) { project in
                        NavigationLink {
                            ContentDetailView(project: project)
                        } label: {
                            HStack(alignment: .top, spacing: 14) {
                                Circle()
                                    .fill(Color(hex: project.platform.accentStartHex).opacity(0.16))
                                    .frame(width: 42, height: 42)
                                    .overlay {
                                        Image(systemName: project.platform.icon)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(Color(hex: project.platform.accentStartHex))
                                    }

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(project.title)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(AppTheme.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        if project.isFavorite {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(AppTheme.warning)
                                        }
                                    }

                                    Text("\(project.platform.rawValue) • \(project.category) • Score \(project.contentScore)")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)

                                    Text(project.hook)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.textMuted)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 0)

                                StatusBadge(status: project.status)
                            }
                            .padding(14)
                            .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var favoriteTemplatesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: "Pinned templates",
                    subtitle: "Formats you can reuse when you want speed without losing structure.",
                    eyebrow: "Templates"
                )

                let favorites = templates.filter(\.isFavorite)

                if favorites.isEmpty {
                    Text("Pin strong templates to turn your best-performing angles into repeatable systems.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    ForEach(favorites.prefix(3), id: \.id) { template in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(template.name)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                TagChip(title: template.category, icon: "bookmark.fill")
                            }
                            Text(template.templateDescription)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var categoriesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: "Category mix",
                    subtitle: "Where your creative energy is concentrated right now.",
                    eyebrow: "Overview"
                )

                if viewModel.topCategories.isEmpty {
                    Text("Once you save content, your category balance will show up here.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    ForEach(viewModel.topCategories) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(category.name)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Text("\(category.count)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .fill(AppTheme.surfaceSecondary)
                                        .frame(height: 9)

                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .fill(AppTheme.accentGradient)
                                        .frame(width: max(proxy.size.width * category.share, 18), height: 9)
                                }
                            }
                            .frame(height: 9)
                        }
                    }
                }
            }
        }
    }

    private func refresh() {
        viewModel.refresh(profile: profile, projects: projects, assignments: assignments, templates: templates)
    }

    private var projectRefreshKey: String {
        projects.map {
            "\($0.id.uuidString)-\($0.updatedAt.timeIntervalSince1970)-\($0.statusRaw)-\($0.isFavorite)"
        }
        .joined(separator: "|")
    }

    private var assignmentRefreshKey: String {
        assignments.map {
            "\($0.id.uuidString)-\($0.date.timeIntervalSince1970)-\($0.statusRaw)-\($0.isPosted)"
        }
        .joined(separator: "|")
    }

    private var templateRefreshKey: String {
        templates.map {
            "\($0.id.uuidString)-\($0.isFavorite)"
        }
        .joined(separator: "|")
    }
}
