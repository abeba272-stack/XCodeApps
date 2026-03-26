import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    let profile: UserProfile
    let settings: AppSettings
    let projects: [ContentProject]
    let assignments: [PlannerAssignment]

    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section("Creator Profile") {
                TextField("Creator name", text: $viewModel.creatorName)
                TextField("Niches (comma separated)", text: $viewModel.nichesText, axis: .vertical)
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

            Section("AI Provider") {
                Picker("Provider mode", selection: $viewModel.providerMode) {
                    ForEach(AIProviderMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                SecureField("API key", text: $viewModel.apiKey)
                TextField("Endpoint URL", text: $viewModel.apiEndpoint)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                TextField("Model ID", text: $viewModel.apiModel)
                    .textInputAutocapitalization(.never)
            }

            Section("Data") {
                Button("Save Settings") {
                    viewModel.save(profile: profile, settings: settings, context: modelContext)
                    themeManager.preference = viewModel.theme
                }
                Button("Export Data") {
                    viewModel.export(profile: profile, settings: settings, projects: projects, assignments: assignments)
                }
                Button("Import Sample Data") {
                    Task {
                        await viewModel.importSampleData(profile: profile, context: modelContext)
                    }
                }
                Button("Clear Local Data", role: .destructive) {
                    viewModel.clearLocalData(projects: projects, assignments: assignments, context: modelContext)
                }
                Button("Reset Onboarding", role: .destructive) {
                    viewModel.resetOnboarding(profile: profile, context: modelContext)
                    dismiss()
                }
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(PremiumBackground())
        .onAppear {
            viewModel.load(profile: profile, settings: settings)
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
