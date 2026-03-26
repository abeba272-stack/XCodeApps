import SwiftUI

struct DashboardView: View {
    let profile: UserProfile
    let settings: AppSettings
    let projects: [ContentProject]
    let templates: [TemplateModel]
    let assignments: [PlannerAssignment]
    let onCreateContent: () -> Void

    @StateObject private var viewModel = DashboardViewModel()
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                metricsGrid
                dailyPromptCard
                pipelineCard
                recentProjectsCard
                favoriteTemplatesCard
                categoriesCard
            }
            .padding(20)
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
            viewModel.refresh(profile: profile, projects: projects, assignments: assignments, templates: templates)
        }
        .onChange(of: projects.count) { _, _ in
            viewModel.refresh(profile: profile, projects: projects, assignments: assignments, templates: templates)
        }
    }

    private var hero: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.greeting)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Today’s suggested idea")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    Spacer()
                    StatusBadge(status: .draft)
                }

                Text(viewModel.suggestedIdea)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 12) {
                    Button(action: onCreateContent) {
                        Text("Quick Generate")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(AppTheme.accentGradient, in: Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(projects.filter(\.isFavorite).count) favorites")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(projects.count) projects in your machine")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(viewModel.metrics) { metric in
                MetricCard(title: metric.title, value: metric.value, subtitle: metric.subtitle)
            }
        }
    }

    private var dailyPromptCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderView(title: "Daily prompt", subtitle: "A creator challenge you can shoot today.")
                Text(viewModel.dailyPrompt)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly goal")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                    ProgressView(value: viewModel.weeklyProgress)
                        .tint(AppTheme.accentGlow)
                    Text("\(Int(viewModel.weeklyProgress * 100))% of your weekly posting target")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private var pipelineCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(title: "Pipeline", subtitle: "At-a-glance content status")

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
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(status.color)
            Text("\(viewModel.pipelineCounts[status, default: 0])")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var recentProjectsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(title: "Recent projects", subtitle: "Resume work fast.")

                if projects.isEmpty {
                    EmptyStateView(
                        title: "No projects yet",
                        message: "Create your first content package to start building a repeatable pipeline.",
                        buttonTitle: "Create Content",
                        action: onCreateContent
                    )
                } else {
                    ForEach(projects.prefix(3), id: \.id) { project in
                        NavigationLink {
                            ContentDetailView(project: project)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(project.title)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .multilineTextAlignment(.leading)
                                    Text("\(project.platform.rawValue) • \(project.category)")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Text(project.hook)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.textMuted)
                                        .lineLimit(2)
                                }
                                Spacer()
                                StatusBadge(status: project.status)
                            }
                            .padding(14)
                            .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                SectionHeaderView(title: "Favorite templates", subtitle: "Reusable starting points.")
                if templates.filter(\.isFavorite).isEmpty {
                    Text("Mark templates as favorites to pin them here.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    ForEach(templates.filter(\.isFavorite).prefix(3), id: \.id) { template in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(template.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(template.templateDescription)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
        }
    }

    private var categoriesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(title: "Categories overview", subtitle: "What you are building most often.")

                if viewModel.categoriesOverview.isEmpty {
                    Text("Once you save content, your category mix appears here.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    ForEach(viewModel.categoriesOverview.keys.sorted(), id: \.self) { category in
                        HStack {
                            Text(category)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text("\(viewModel.categoriesOverview[category, default: 0])")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }
}
