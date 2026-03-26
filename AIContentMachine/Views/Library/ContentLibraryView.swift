import SwiftUI

struct ContentLibraryView: View {
    let projects: [ContentProject]

    @StateObject private var viewModel = ContentLibraryViewModel()

    private var categories: [String] {
        ["All"] + Array(Set(projects.map(\.category))).sorted()
    }

    private var filteredProjects: [ContentProject] {
        viewModel.filteredProjects(from: projects)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard
                filterBar

                if filteredProjects.isEmpty {
                    EmptyStateView(
                        title: projects.isEmpty ? "No saved content yet" : "No matching content",
                        message: projects.isEmpty
                            ? "Save your first strong draft so you can reuse, refine, and schedule it later."
                            : "Adjust the filters, clear the search, or generate a fresh package to widen the library.",
                        buttonTitle: nil,
                        action: nil,
                        icon: projects.isEmpty ? "square.stack.3d.up.slash.fill" : "line.3.horizontal.decrease.circle",
                        eyebrow: "Library"
                    )
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredProjects, id: \.id) { project in
                            NavigationLink {
                                ContentDetailView(project: project)
                            } label: {
                                libraryCard(for: project)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .background(PremiumBackground())
        .navigationTitle("Library")
        .searchable(text: $viewModel.searchText, prompt: "Search title, hook, caption, audience, hashtags")
    }

    private var summaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content library")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(viewModel.resultsSubtitle(for: filteredProjects.count, totalCount: projects.count))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    StatusBadge(status: filteredProjects.first?.status ?? .draft)
                        .opacity(filteredProjects.isEmpty ? 0 : 1)
                }

                HStack(spacing: 12) {
                    summaryPill(title: "Results", value: "\(filteredProjects.count)", icon: "magnifyingglass")
                    summaryPill(title: "Favorites", value: "\(projects.filter(\.isFavorite).count)", icon: "star.fill")
                    summaryPill(title: "Avg Score", value: averageScoreLabel, icon: "chart.bar.fill")
                }
            }
        }
    }

    private func summaryPill(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.accentGlow)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textMuted)
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(AppTheme.surfaceSecondary, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var filterBar: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeaderView(
                        title: "Filters",
                        subtitle: "Narrow the pipeline without losing speed.",
                        eyebrow: "Search"
                    )

                    if viewModel.activeFilterCount() > 0 || !viewModel.searchText.isEmpty {
                        Button("Clear") {
                            viewModel.clearFilters()
                        }
                        .buttonStyle(AppQuietButtonStyle())
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Menu {
                            ForEach(categories, id: \.self) { category in
                                Button(category) { viewModel.selectedCategory = category }
                            }
                        } label: {
                            TagChip(
                                title: viewModel.selectedCategory == "All" ? "Category" : viewModel.selectedCategory,
                                isSelected: viewModel.selectedCategory != "All",
                                icon: "square.grid.2x2"
                            )
                        }
                        .buttonStyle(.plain)

                        Menu {
                            Button("All Platforms") { viewModel.selectedPlatform = nil }
                            ForEach(ContentPlatform.allCases) { platform in
                                Button(platform.rawValue) { viewModel.selectedPlatform = platform }
                            }
                        } label: {
                            TagChip(
                                title: viewModel.selectedPlatform?.rawValue ?? "Platform",
                                isSelected: viewModel.selectedPlatform != nil,
                                icon: "play.square.stack.fill"
                            )
                        }
                        .buttonStyle(.plain)

                        Menu {
                            Button("All Statuses") { viewModel.selectedStatus = nil }
                            ForEach(ProjectStatus.allCases) { status in
                                Button(status.rawValue) { viewModel.selectedStatus = status }
                            }
                        } label: {
                            TagChip(
                                title: viewModel.selectedStatus?.rawValue ?? "Status",
                                isSelected: viewModel.selectedStatus != nil,
                                icon: "flag.fill"
                            )
                        }
                        .buttonStyle(.plain)

                        Menu {
                            ForEach(ContentSortOption.allCases) { sort in
                                Button(sort.rawValue) { viewModel.selectedSort = sort }
                            }
                        } label: {
                            TagChip(
                                title: viewModel.selectedSort.rawValue,
                                isSelected: viewModel.selectedSort != .newest,
                                icon: "arrow.up.arrow.down"
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.favoriteOnly.toggle()
                        } label: {
                            TagChip(title: "Favorites", isSelected: viewModel.favoriteOnly, icon: "star.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func libraryCard(for project: ContentProject) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: project.platform.icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: project.platform.accentStartHex))
                        Text(project.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                        if project.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(AppTheme.warning)
                        }
                    }

                    Text("\(project.platform.rawValue) • \(project.category) • \(project.durationLabel)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 0)
                StatusBadge(status: project.status)
            }

            Text(project.hook)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)

            Text(project.caption.isEmpty ? project.overview : project.caption)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(3)

            HStack(spacing: 10) {
                TagChip(title: "Score \(project.contentScore)", isSelected: project.contentScore >= 80, icon: "sparkles")
                if let firstTag = project.hashtags.first {
                    TagChip(title: firstTag, icon: "number")
                }
                TagChip(title: project.goal.rawValue, icon: "target")
            }

            HStack {
                Text("Updated \(project.updatedAt.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(18)
        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var averageScoreLabel: String {
        guard !projects.isEmpty else { return "0" }
        let average = projects.map(\.contentScore).reduce(0, +) / max(projects.count, 1)
        return "\(average)"
    }
}
