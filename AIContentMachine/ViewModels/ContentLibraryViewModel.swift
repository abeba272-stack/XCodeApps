import Foundation

@MainActor
final class ContentLibraryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    @Published var selectedPlatform: ContentPlatform? = nil
    @Published var selectedStatus: ProjectStatus? = nil
    @Published var favoriteOnly = false
    @Published var selectedSort: ContentSortOption = .newest

    func filteredProjects(from projects: [ContentProject]) -> [ContentProject] {
        let tokens = searchText
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        let filtered = projects.filter { project in
            let searchableFields = [
                project.title,
                project.topic,
                project.category,
                project.audience,
                project.hook,
                project.caption,
                project.notes,
                project.templateUsed ?? "",
                project.hashtags.joined(separator: " ")
            ]
            .joined(separator: " ")
            .lowercased()

            let matchesSearch = tokens.isEmpty || tokens.allSatisfy { searchableFields.contains($0) }
            let matchesCategory = selectedCategory == "All" || project.category == selectedCategory
            let matchesPlatform = selectedPlatform == nil || project.platform == selectedPlatform
            let matchesStatus = selectedStatus == nil || project.status == selectedStatus
            let matchesFavorite = !favoriteOnly || project.isFavorite

            return matchesSearch && matchesCategory && matchesPlatform && matchesStatus && matchesFavorite
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
        case .topScore:
            return filtered.sorted { lhs, rhs in
                if lhs.contentScore == rhs.contentScore { return lhs.updatedAt > rhs.updatedAt }
                return lhs.contentScore > rhs.contentScore
            }
        }
    }

    func activeFilterCount() -> Int {
        var count = 0
        if selectedCategory != "All" { count += 1 }
        if selectedPlatform != nil { count += 1 }
        if selectedStatus != nil { count += 1 }
        if favoriteOnly { count += 1 }
        return count
    }

    func clearFilters() {
        selectedCategory = "All"
        selectedPlatform = nil
        selectedStatus = nil
        favoriteOnly = false
        selectedSort = .newest
        searchText = ""
    }

    func resultsSubtitle(for filteredCount: Int, totalCount: Int) -> String {
        if totalCount == 0 {
            return "Your content machine is empty. Save drafts to build a real library."
        }

        if filteredCount == totalCount && searchText.isEmpty && activeFilterCount() == 0 {
            return "\(totalCount) projects ready to search, sort, and ship."
        }

        return "\(filteredCount) of \(totalCount) projects match the current search and filters."
    }
}
