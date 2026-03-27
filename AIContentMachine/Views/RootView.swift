import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var paywallController: PaywallController
    let container: AppContainer

    @Query private var profiles: [UserProfile]
    @Query private var settings: [AppSettings]
    @Query(sort: \ContentProject.updatedAt, order: .reverse) private var projects: [ContentProject]
    @Query(sort: \TemplateModel.name) private var templates: [TemplateModel]
    @Query(sort: \PlannerAssignment.date) private var assignments: [PlannerAssignment]

    @State private var isBootstrapped = false
    @State private var isLaunchScreenVisible = true
    @State private var bootstrapError: String?
    @State private var launchProgress: CGFloat = 0.1
    @State private var launchPhaseIndex = 0

    var body: some View {
        ZStack {
            PremiumBackground()

            if isLaunchScreenVisible {
                AppLaunchView(
                    progress: launchProgress,
                    phaseIndex: clampedPhaseIndex,
                    phase: currentLaunchPhase,
                    phases: launchPhases
                )
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                resolvedContent
                    .transition(.opacity)
            }
        }
        .task {
            await startLaunchFlowIfNeeded()
        }
        .sheet(item: $paywallController.context) { context in
            NavigationStack {
                PaywallView(context: context)
            }
            .presentationDetents([.medium, .large])
        }
        .onChange(of: settings.first?.themeRaw) { _, _ in
            themeManager.update(using: settings.first)
        }
    }

    private var clampedPhaseIndex: Int {
        min(max(launchPhaseIndex, 0), launchPhases.count - 1)
    }

    private var currentLaunchPhase: LaunchPhase {
        launchPhases[clampedPhaseIndex]
    }

    private var launchPhases: [LaunchPhase] {
        [
            LaunchPhase(
                id: "setup",
                label: "Setup",
                symbol: "sparkles",
                title: "Preparing your creator workspace",
                subtitle: "Loading your profile, saved preferences, and the foundation of your content system."
            ),
            LaunchPhase(
                id: "library",
                label: "Library",
                symbol: "square.stack.3d.up.fill",
                title: "Gathering your content pipeline",
                subtitle: "Bringing drafts, templates, and planning context into a clean starting state."
            ),
            LaunchPhase(
                id: "engine",
                label: "Engine",
                symbol: "bolt.horizontal.fill",
                title: "Tuning the local content engine",
                subtitle: "Warming up the generator so the first prompt feels intentional, fast, and usable."
            ),
            LaunchPhase(
                id: "open",
                label: "Open",
                symbol: "arrow.up.right.circle.fill",
                title: "Opening your studio",
                subtitle: "Applying the final polish before the dashboard appears."
            )
        ]
    }

    @ViewBuilder
    private var resolvedContent: some View {
        if let profile = profiles.first, let appSettings = settings.first {
            if profile.onboardingCompleted {
                MainShellView(
                    container: container,
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
            VStack {
                EmptyStateView(
                    title: "Unable to load app data",
                    message: bootstrapError ?? "The app could not initialize local data.",
                    buttonTitle: nil,
                    action: nil,
                    icon: "exclamationmark.triangle.fill",
                    eyebrow: "Error"
                )
            }
            .padding(AppTheme.screenPadding)
        }
    }

    @MainActor
    private func startLaunchFlowIfNeeded() async {
        guard isLaunchScreenVisible else { return }

        let launchStartedAt = Date()
        let progressTask = Task { @MainActor in
            await animateLaunchProgress()
        }

        do {
            try AppBootstrapper.bootstrap(in: modelContext)
            themeManager.update(using: settings.first)
            isBootstrapped = true
        } catch {
            bootstrapError = error.localizedDescription
        }

        let minimumLaunchDuration = 1.9
        let elapsed = Date().timeIntervalSince(launchStartedAt)
        let remaining = max(0, minimumLaunchDuration - elapsed)
        if remaining > 0 {
            try? await Task.sleep(for: .seconds(remaining))
        }

        if isBootstrapped {
            for _ in 0..<8 where profiles.first == nil || settings.first == nil {
                try? await Task.sleep(for: .milliseconds(40))
            }
        }

        progressTask.cancel()

        withAnimation(.smooth(duration: 0.42)) {
            launchPhaseIndex = launchPhases.count - 1
            launchProgress = 1
        }

        try? await Task.sleep(for: .milliseconds(220))

        withAnimation(.easeInOut(duration: 0.42)) {
            isLaunchScreenVisible = false
        }
    }

    @MainActor
    private func animateLaunchProgress() async {
        let milestones: [(CGFloat, Int, Duration)] = [
            (0.18, 0, .milliseconds(240)),
            (0.34, 1, .milliseconds(380)),
            (0.56, 1, .milliseconds(420)),
            (0.74, 2, .milliseconds(480)),
            (0.88, 3, .milliseconds(560))
        ]

        while !Task.isCancelled && !isBootstrapped {
            for milestone in milestones {
                guard !Task.isCancelled, !isBootstrapped else { return }

                withAnimation(.smooth(duration: 0.55)) {
                    launchProgress = milestone.0
                    launchPhaseIndex = milestone.1
                }

                try? await Task.sleep(for: milestone.2)
            }

            guard !Task.isCancelled, !isBootstrapped else { return }

            withAnimation(.easeInOut(duration: 0.9)) {
                launchProgress = 0.92
                launchPhaseIndex = launchPhases.count - 1
            }

            try? await Task.sleep(for: .milliseconds(700))
        }
    }
}

private struct LaunchPhase: Identifiable {
    let id: String
    let label: String
    let symbol: String
    let title: String
    let subtitle: String
}

private enum MainTab: Hashable {
    case dashboard
    case create
    case library
    case templates
    case planner
}

private struct MainShellView: View {
    let container: AppContainer
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
                    container: container,
                    profile: profile,
                    settings: settings,
                    projects: projects,
                    templates: templates,
                    assignments: assignments,
                    onCreateContent: { selectedTab = .create },
                    onOpenPlanner: { selectedTab = .planner },
                    onOpenLibrary: { selectedTab = .library }
                )
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
            .tag(MainTab.dashboard)

            NavigationStack {
                CreateContentView(profile: profile, settings: settings, templates: templates, container: container)
            }
            .tabItem { Label("Create", systemImage: "wand.and.stars") }
            .tag(MainTab.create)

            NavigationStack {
                ContentLibraryView(projects: projects)
            }
            .tabItem { Label("Library", systemImage: "square.stack.3d.up.fill") }
            .tag(MainTab.library)

            NavigationStack {
                TemplatesView(templates: templates, container: container)
            }
            .tabItem { Label("Templates", systemImage: "rectangle.on.rectangle.angled") }
            .tag(MainTab.templates)

            NavigationStack {
                PlannerView(projects: projects, assignments: assignments, container: container)
            }
            .tabItem { Label("Planner", systemImage: "calendar") }
            .tag(MainTab.planner)
        }
        .tint(AppTheme.accentGlow)
    }
}

private struct AppLaunchView: View {
    let progress: CGFloat
    let phaseIndex: Int
    let phase: LaunchPhase
    let phases: [LaunchPhase]

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppTheme.accentGradient)
                            .frame(width: 62, height: 62)

                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            .frame(width: 62, height: 62)

                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.88))
                    }
                    .shadow(color: AppTheme.accentGlow.opacity(0.24), radius: 20, x: 0, y: 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("AI Content Machine")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("A calm start before the studio opens")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("OPENING")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)

                    Text(phase.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(phase.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 14) {
                    AppLaunchProgressBar(progress: progress)

                    HStack(spacing: 10) {
                        ForEach(Array(phases.enumerated()), id: \.offset) { index, item in
                            LaunchStageChip(
                                title: item.label,
                                symbol: item.symbol,
                                state: state(for: index)
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: 410, alignment: .leading)
            .premiumCardStyle()
            .padding(.horizontal, AppTheme.screenPadding)

            Spacer()

            Text("Quietly preparing your local workspace and content engine.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
                .padding(.bottom, 22)
        }
    }

    private func state(for index: Int) -> LaunchStageChip.State {
        if index < phaseIndex {
            return .complete
        }
        if index == phaseIndex {
            return .active
        }
        return .upcoming
    }
}

private struct AppLaunchProgressBar: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let clamped = min(max(progress, 0), 1)
            let fillWidth = max(34, proxy.size.width * clamped)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AppTheme.surfaceMuted)
                    .frame(height: 12)

                Capsule(style: .continuous)
                    .fill(AppTheme.accentGradient)
                    .frame(width: fillWidth, height: 12)
                    .overlay(alignment: .trailing) {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 58, height: 12)
                            .blur(radius: 6)
                    }
                    .shadow(color: AppTheme.accentGlow.opacity(0.22), radius: 16, x: 0, y: 8)

                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { index in
                        Rectangle()
                            .fill(Color.white.opacity(index == 3 ? 0 : 0.08))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 12)
                .clipShape(Capsule(style: .continuous))
            }
        }
        .frame(height: 12)
    }
}

private struct LaunchStageChip: View {
    enum State {
        case upcoming
        case active
        case complete
    }

    let title: String
    let symbol: String
    let state: State

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(foregroundStyle)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(backgroundStyle, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var foregroundStyle: Color {
        switch state {
        case .upcoming:
            return AppTheme.textMuted
        case .active:
            return AppTheme.textPrimary
        case .complete:
            return AppTheme.textPrimary
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        switch state {
        case .upcoming:
            return AnyShapeStyle(AppTheme.surfaceMuted)
        case .active:
            return AnyShapeStyle(AppTheme.surfaceTertiary)
        case .complete:
            return AnyShapeStyle(AppTheme.surfaceSecondary)
        }
    }

    private var borderColor: Color {
        switch state {
        case .upcoming:
            return AppTheme.border
        case .active:
            return AppTheme.borderStrong
        case .complete:
            return AppTheme.accentGlow.opacity(0.22)
        }
    }
}
