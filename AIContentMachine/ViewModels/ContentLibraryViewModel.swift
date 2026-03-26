import Foundation

@MainActor
final class ContentLibraryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    @Published var selectedPlatform: String = "All"
    @Published var selectedStatus: String = "All"
    @Published var selectedSort: ContentSortOption = .newest

    func filteredProjects(from projects: [ContentProject]) -> [ContentProject] {
        let filtered = projects.filter { project in
            let matchesSearch = searchText.isEmpty
                || project.title.localizedCaseInsensitiveContains(searchText)
                || project.topic.localizedCaseInsensitiveContains(searchText)
                || project.category.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == "All" || project.category == selectedCategory
            let matchesPlatform = selectedPlatform == "All" || project.platform.rawValue == selectedPlatform
            let matchesStatus = selectedStatus == "All" || project.status.rawValue == selectedStatus
            return matchesSearch && matchesCategory && matchesPlatform && matchesStatus
        }

        switch selectedSort {
        case .newest:
            return filtered.sorted(by: { $0.updatedAt > $1.updatedAt })
        case .oldest:
            return filtered.sorted(by: { $0.updatedAt < $1.updatedAt })
        case .favorites:
            return filtered.sorted { lhs, rhs in
                if lhs.isFavorite == rhs.isFavorite { return lhs.updatedAt > rhs.updatedAt }
                return lhs.isFavorite && !rhs.isFavorite
            }
        }
    }
}
