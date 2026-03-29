import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var userSessionManager: UserSessionManager
    @EnvironmentObject private var featureAccessController: FeatureAccessController
    @EnvironmentObject private var paywallController: PaywallController

    let profile: UserProfile
    let settings: AppSettings
    let projects: [ContentProject]
    let assignments: [PlannerAssignment]
    let container: AppContainer

    @StateObject private var viewModel: SettingsViewModel
    @State private var isRestoringPurchases = false
    @State private var showClearDataConfirmation = false
    @State private var showResetOnboardingConfirmation = false

    init(
        profile: UserProfile,
        settings: AppSettings,
        projects: [ContentProject],
        assignments: [PlannerAssignment],
        container: AppContainer
    ) {
        self.profile = profile
        self.settings = settings
        self.projects = projects
        self.assignments = assignments
        self.container = container
        _viewModel = StateObject(wrappedValue: container.makeSettingsViewModel())
    }

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Email") {
                    Text(viewModel.email.isEmpty ? "No email" : viewModel.email)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                LabeledContent("Sign-in method") {
                    Text(profile.authProvider.displayName)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                LabeledContent("Plan") {
                    Text(userSessionManager.currentPlan.displayName)
                        .foregroundStyle(userSessionManager.hasProAccess ? AppTheme.success : AppTheme.textSecondary)
                }

                if profile.isSpecialProUser {
                    Text("This device uses the internal special Pro account override. Store purchases are bypassed for this account.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Button("Sign Out", role: .destructive) {
                    userSessionManager.signOut()
                    dismiss()
                }
            }

            Section("Creator Profile") {
                TextField("Creator name", text: $viewModel.creatorName)
                TextField("Niches (comma separated)", text: $viewModel.nichesText, axis: .vertical)
            }

            Section("Prompt Defaults") {
                TextField("Default audience", text: $viewModel.defaultAudience, axis: .vertical)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Persistent prompt notes")
                    TextField(
                        "Add recurring context like your niche angle, positioning, offers, or visual direction.",
                        text: $viewModel.persistentPromptNotes,
                        axis: .vertical
                    )
                    .lineLimit(4...8)

                    Text("These notes are automatically injected into future AI prompt building to reduce repeated typing.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Section("Defaults") {
                platformSelector
                Picker("Language", selection: $viewModel.selectedLanguage) {
                    ForEach(ContentLanguage.allCases) { language in
                        Text(language.rawValue).tag(language)
                    }
                }

                Picker("Tone", selection: $viewModel.selectedTone) {
                    ForEach(ContentTone.allCases) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Goals")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        ForEach(ContentGoal.allCases) { goal in
                            Button {
                                viewModel.toggle(goal: goal)
                            } label: {
                                TagChip(title: goal.rawValue, isSelected: viewModel.selectedGoals.contains(goal))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Posting frequency")
                    Slider(value: $viewModel.postingFrequency, in: 1...14, step: 1)
                    Text("\(Int(viewModel.postingFrequency)) posts per week")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Section("Theme") {
                Picker("Theme preference", selection: $viewModel.theme) {
                    ForEach(AppThemePreference.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
            }

            Section(subscriptionStore.isPro ? "ACM Pro" : "Upgrade to Pro") {
                LabeledContent("Plan") {
                    Text(subscriptionStore.entitlementTier.displayName)
                        .foregroundStyle(subscriptionStore.isPro ? AppTheme.success : AppTheme.textSecondary)
                }

                if !subscriptionStore.isPro {
                    Text("Pro unlocks the full template library, unlimited generations, Batch Ideas, Local AI Server mode, and premium export tools.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)

                    Button("Upgrade to Pro") {
                        paywallController.present(PaywallContext(reason: .settingsUpgrade))
                    }
                }

                Button(isRestoringPurchases ? "Restoring…" : "Restore Purchases") {
                    isRestoringPurchases = true
                    Task {
                        await subscriptionStore.restorePurchases()
                        isRestoringPurchases = false
                    }
                }

                Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
            }

            Section("Legal & Support") {
                Link("Terms of Service", destination: URL(string: "https://abeba272-stack.github.io/XCodeApps/terms.html")!)
                Link("Privacy Policy", destination: URL(string: "https://abeba272-stack.github.io/XCodeApps/privacy.html")!)
                Link("Support Email", destination: URL(string: "mailto:sundermannabeba@gmail.com")!)
            }

#if DEBUG
            Section("Local Pro Testing") {
                Toggle(
                    "Unlock Pro locally on this device",
                    isOn: Binding(
                        get: { subscriptionStore.isLocalTestingProOverrideEnabled },
                        set: { newValue in
                            subscriptionStore.setLocalTestingProOverride(newValue)
                            userSessionManager.syncSubscriptionState()
                        }
                    )
                )

                Text("Use this only while StoreKit and App Store Connect are not fully live. It unlocks Pro features locally without requiring a real purchase.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }
#endif

            Section("AI Provider") {
                Picker("Provider mode", selection: $viewModel.providerMode) {
                    ForEach(AIProviderMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Text(viewModel.providerMode.subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)

                if viewModel.providerMode.requiresEndpoint {
                    TextField("Local server endpoint", text: $viewModel.localServerEndpoint)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if let endpointError = viewModel.endpointValidationError {
                        Text(endpointError)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.warning)
                    }

                    Button(viewModel.isTestingConnection ? "Testing…" : "Test Connection") {
                        Task { await viewModel.testConnection() }
                    }
                    .disabled(viewModel.isTestingConnection)

                    if let result = viewModel.connectionTestResult {
                        Text(result.message)
                            .font(.footnote)
                            .foregroundStyle(result.success ? AppTheme.success : AppTheme.warning)
                    }
                }
            }

            Section("Data") {
                Button("Save Settings") {
                    viewModel.save(profile: profile, settings: settings)
                    themeManager.preference = viewModel.theme
                }
                Button("Export Data") {
                    guard featureAccessController.canExportWorkspace() else {
                        paywallController.present(PaywallContext(reason: .workspaceExport))
                        return
                    }
                    viewModel.export(profile: profile, settings: settings, projects: projects, assignments: assignments)
                }
                Button("Import Sample Data") {
                    Task {
                        await viewModel.importSampleData(profile: profile, context: modelContext)
                    }
                }
                Button("Clear Local Data", role: .destructive) {
                    showClearDataConfirmation = true
                }
                Button("Reset Onboarding", role: .destructive) {
                    showResetOnboardingConfirmation = true
                }
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(PremiumBackground())
        .onAppear {
            viewModel.load(profile: profile, settings: settings)
        }
        .onChange(of: viewModel.providerMode) { _, newValue in
            guard !featureAccessController.canUseProviderMode(newValue) else { return }
            viewModel.providerMode = .mock
            paywallController.present(PaywallContext(reason: .localAIServer))
        }
        .alert("Settings", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: Binding(
            get: { !viewModel.shareItems.isEmpty },
            set: { if !$0 { viewModel.shareItems = [] } }
        )) {
            ShareSheet(items: viewModel.shareItems)
        }
        .overlay(alignment: .bottom) {
            if let toast = viewModel.toastMessage {
                Text(toast)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.accentGradient, in: Capsule(style: .continuous))
                    .padding(.bottom, 12)
                    .task {
                        try? await Task.sleep(for: .seconds(1.2))
                        viewModel.toastMessage = nil
                    }
            }
        }
        .alert("Clear Local Data", isPresented: $showClearDataConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                viewModel.clearLocalData(projects: projects, assignments: assignments)
            }
        } message: {
            Text("All saved projects, templates, and settings will be permanently deleted. Continue?")
        }
        .alert("Reset Onboarding", isPresented: $showResetOnboardingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetOnboarding(profile: profile)
                dismiss()
            }
        } message: {
            Text("Onboarding will be reset. Your profile will be preserved. Continue?")
        }
    }

    private var platformSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Platforms")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                ForEach(ContentPlatform.allCases) { platform in
                    Button {
                        viewModel.toggle(platform: platform)
                    } label: {
                        TagChip(title: platform.rawValue, isSelected: viewModel.selectedPlatforms.contains(platform))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
