import SwiftUI

struct ContentLibraryView: View {
    let projects: [ContentProject]

    @StateObject private var viewModel = ContentLibraryViewModel()

    private var categories: [String] {
        ["All"] + Array(Set(projects.map(\.category))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            filters
            if viewModel.filteredProjects(from: projects).isEmpty {
                ScrollView {
                    EmptyStateView(
                        title: "No matching content",
                        message: "Adjust your filters or create a new project to fill the library.",
                        buttonTitle: nil,
                        action: nil
                    )
                    .padding(20)
                }
            } else {
                List {
                    ForEach(viewModel.filteredProjects(from: projects), id: \.id) { project in
                        NavigationLink {
                            ContentDetailView(project: project)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(project.title)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    if project.isFavorite {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(AppTheme.accentGlow)
                                    }
                                }
                                Text("\(project.platform.rawValue) • \(project.category) • \(project.durationLabel)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text(project.hook)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .lineLimit(2)
                                HStack {
                                    StatusBadge(status: project.status)
                                    Spacer()
                                    Text("Score \(project.contentScore)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(PremiumBackground())
        .navigationTitle("Library")
        .searchable(text: $viewModel.searchText, prompt: "Search title or keyword")
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Menu(viewModel.selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Button(category) { viewModel.selectedCategory = category }
                    }
                }

                Menu(viewModel.selectedPlatform) {
                    Button("All") { viewModel.selectedPlatform = "All" }
                    ForEach(ContentPlatform.allCases) { platform in
                        Button(platform.rawValue) { viewModel.selectedPlatform = platform.rawValue }
                    }
                }

                Menu(viewModel.selectedStatus) {
                    Button("All") { viewModel.selectedStatus = "All" }
                    ForEach(ProjectStatus.allCases) { status in
                        Button(status.rawValue) { viewModel.selectedStatus = status.rawValue }
                    }
                }

                Menu(viewModel.selectedSort.rawValue) {
                    ForEach(ContentSortOption.allCases) { sort in
                        Button(sort.rawValue) { viewModel.selectedSort = sort }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 14)
            .foregroundStyle(AppTheme.textPrimary)
        }
    }
}
