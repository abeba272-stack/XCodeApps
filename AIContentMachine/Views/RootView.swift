import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    @Query private var profiles: [UserProfile]
    @Query private var settings: [AppSettings]
    @Query(sort: \ContentProject.updatedAt, order: .reverse) private var projects: [ContentProject]
    @Query(sort: \TemplateModel.name) private var templates: [TemplateModel]
    @Query(sort: \PlannerAssignment.date) private var assignments: [PlannerAssignment]

    @State private var isBootstrapped = false
    @State private var bootstrapError: String?

    var body: some View {
        ZStack {
            PremiumBackground()

            if !isBootstrapped {
                ProgressView("Preparing workspace")
                    .tint(AppTheme.accentGlow)
                    .foregroundStyle(AppTheme.textPrimary)
            } else if let profile = profiles.first, let appSettings = settings.first {
                if profile.onboardingCompleted {
                    MainShellView(
                        profile: profile,
                        settings: appSettings,
                        projects: projects,
                        templates: templates,
                        assignments: assignments
                    )
                } else {
                    OnboardingContainerView(profile: profile)
                }
            } else {
                Text(bootstrapError ?? "Unable to load app data.")
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .task {
            guard !isBootstrapped else { return }
            do {
                try AppBootstrapper.bootstrap(in: modelContext)
                themeManager.update(using: settings.first)
                isBootstrapped = true
            } catch {
                bootstrapError = error.localizedDescription
            }
        }
        .onChange(of: settings.first?.themeRaw) { _, _ in
            themeManager.update(using: settings.first)
        }
    }
}

private enum MainTab: Hashable {
    case dashboard
    case create
    case library
    case templates
    case planner
}

private struct MainShellView: View {
    let profile: UserProfile
    let settings: AppSettings
    let projects: [ContentProject]
    let templates: [TemplateModel]
    let assignments: [PlannerAssignment]

    @State private var selectedTab: MainTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(
                    profile: profile,
                    settings: settings,
                    projects: projects,
                    templates: templates,
                    assignments: assignments,
                    onCreateContent: { selectedTab = .create }
                )
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
            .tag(MainTab.dashboard)

            NavigationStack {
                CreateContentView(profile: profile, settings: settings, templates: templates)
            }
            .tabItem { Label("Create", systemImage: "wand.and.stars") }
            .tag(MainTab.create)

            NavigationStack {
                ContentLibraryView(projects: projects)
            }
            .tabItem { Label("Library", systemImage: "square.stack.3d.up.fill") }
            .tag(MainTab.library)

            NavigationStack {
                TemplatesView(templates: templates)
            }
            .tabItem { Label("Templates", systemImage: "rectangle.on.rectangle.angled") }
            .tag(MainTab.templates)

            NavigationStack {
                PlannerView(projects: projects, assignments: assignments)
            }
            .tabItem { Label("Planner", systemImage: "calendar") }
            .tag(MainTab.planner)
        }
        .tint(AppTheme.accentGlow)
    }
}
