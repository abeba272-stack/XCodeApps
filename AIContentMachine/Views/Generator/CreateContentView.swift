import SwiftUI
import SwiftData

struct CreateContentView: View {
    @Environment(\.modelContext) private var modelContext

    let profile: UserProfile
    let settings: AppSettings
    let templates: [TemplateModel]
    var initialTemplate: TemplateModel? = nil

    @StateObject private var viewModel = ContentGeneratorViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                generatorForm

                if viewModel.isGenerating {
                    GenerationLoadingView()
                } else {
                    Button {
                        Task { await viewModel.generate(settings: settings) }
                    } label: {
                        Text("Create Content")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .navigationTitle("Create Content")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.preload(from: profile)
            if let initialTemplate {
                viewModel.selectedTemplate = initialTemplate
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { viewModel.previewProject != nil },
            set: { if !$0 { viewModel.previewProject = nil } }
        )) {
            if let project = viewModel.previewProject {
                if project.generationMode == .batchIdeas {
                    BatchIdeasView(viewModel: viewModel, project: project)
                } else {
                    ContentResultView(viewModel: viewModel, project: project, settings: settings)
                }
            }
        }
        .alert("Generation", isPresented: Binding(
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
    }

    private var generatorForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeaderView(title: "Brief", subtitle: "Give the generator enough signal to make the output useful.")

                    promptField(title: "Topic or subject", text: $viewModel.topic, placeholder: "What should this piece be about?")
                    promptField(title: "Audience", text: $viewModel.audience, placeholder: "Who is this for?")
                    promptField(title: "Category", text: $viewModel.category, placeholder: "Mental Health, Gaming, Education...")
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeaderView(title: "Channel fit", subtitle: "Shape the format, tone, and platform behavior.")

                    selectionRow(title: "Platform") {
                        Menu(viewModel.platform.rawValue) {
                            ForEach(ContentPlatform.allCases) { platform in
                                Button(platform.rawValue) { viewModel.platform = platform }
                            }
                        }
                    }

                    selectionRow(title: "Tone") {
                        Menu(viewModel.tone.rawValue) {
                            ForEach(ContentTone.allCases) { tone in
                                Button(tone.rawValue) { viewModel.tone = tone }
                            }
                        }
                    }

                    selectionRow(title: "Goal") {
                        Menu(viewModel.goal.rawValue) {
                            ForEach(ContentGoal.allCases) { goal in
                                Button(goal.rawValue) { viewModel.goal = goal }
                            }
                        }
                    }

                    selectionRow(title: "Style") {
                        Menu(viewModel.style.rawValue) {
                            ForEach(ContentStyle.allCases) { style in
                                Button(style.rawValue) { viewModel.style = style }
                            }
                        }
                    }

                    selectionRow(title: "Language") {
                        Menu(viewModel.language.rawValue) {
                            ForEach(ContentLanguage.allCases) { language in
                                Button(language.rawValue) { viewModel.language = language }
                            }
                        }
                    }

                    selectionRow(title: "Generate") {
                        Menu(viewModel.mode.rawValue) {
                            ForEach(GenerationMode.allCases) { mode in
                                Button(mode.rawValue) { viewModel.mode = mode }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Duration target")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text("\(Int(viewModel.durationSeconds))s")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Slider(value: $viewModel.durationSeconds, in: 10...90, step: 5)
                            .tint(AppTheme.accentGlow)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeaderView(title: "Template boost", subtitle: "Optional reusable angle to tighten the structure.")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            templateOption(template: nil, title: "No Template", description: "Generate freely")
                            ForEach(templates, id: \.id) { template in
                                templateOption(template: template, title: template.name, description: template.category)
                            }
                        }
                    }
                }
            }
        }
    }

    private func promptField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(2...4)
                .padding(14)
                .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func selectionRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            content()
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func templateOption(template: TemplateModel?, title: String, description: String) -> some View {
        let isSelected = viewModel.selectedTemplate?.id == template?.id || (template == nil && viewModel.selectedTemplate == nil)
        return Button {
            viewModel.selectedTemplate = template
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.black : AppTheme.textPrimary)
                Text(description)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? Color.black.opacity(0.8) : AppTheme.textSecondary)
                Spacer()
            }
            .frame(width: 180, height: 120, alignment: .topLeading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.surfaceSecondary))
            )
        }
        .buttonStyle(.plain)
    }
}
