import SwiftUI

struct CreateContentView: View {
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var featureAccessController: FeatureAccessController
    @EnvironmentObject private var paywallController: PaywallController

    let profile: UserProfile
    let settings: AppSettings
    let templates: [TemplateModel]
    let container: AppContainer
    var initialTemplate: TemplateModel? = nil

    @StateObject private var viewModel: ContentGeneratorViewModel

    init(profile: UserProfile, settings: AppSettings, templates: [TemplateModel], container: AppContainer, initialTemplate: TemplateModel? = nil) {
        self.profile = profile
        self.settings = settings
        self.templates = templates
        self.container = container
        self.initialTemplate = initialTemplate
        _viewModel = StateObject(wrappedValue: container.makeContentGeneratorViewModel())
    }

    private var canGenerate: Bool {
        !viewModel.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.audience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                generatorForm

                if let errorMessage = viewModel.errorMessage {
                    errorCard(message: errorMessage)
                }

                if viewModel.isGenerating {
                    GenerationLoadingView()
                } else {
                    Button {
                        Task { await viewModel.generate(settings: settings) }
                    } label: {
                        Text("Create Content")
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .disabled(!canGenerate)
                    .opacity(canGenerate ? 1 : 0.65)

                    if !subscriptionStore.isPro {
                        Text("Free includes \(FeatureAccessPolicy.freeGenerationLimitPerMonth) generations per month, Offline Mock, and all base workflow features.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .navigationTitle("Create Content")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.preload(from: profile)
            if let initialTemplate {
                if featureAccessController.canUseTemplate(initialTemplate) {
                    viewModel.applyTemplate(initialTemplate)
                } else {
                    paywallController.present(PaywallContext(reason: .proTemplate(name: initialTemplate.name)))
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { viewModel.session != nil },
            set: { if !$0 { viewModel.session = nil } }
        )) {
            if let session = viewModel.session {
                if session.generationMode == .batchIdeas {
                    BatchIdeasView(viewModel: viewModel, session: session)
                } else {
                    ContentResultView(viewModel: viewModel, session: session, settings: settings)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { !viewModel.shareItems.isEmpty },
            set: { if !$0 { viewModel.shareItems = [] } }
        )) {
            ShareSheet(items: viewModel.shareItems)
        }
    }

    private var headerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Build a content package")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Give the generator clear signal so it can produce a stronger hook, tighter script, and more usable posting cues.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    TagChip(title: settings.providerMode.displayName, isSelected: true, icon: "bolt.horizontal.fill")
                }

                HStack(spacing: 10) {
                    summaryPill(title: viewModel.platform.rawValue, icon: viewModel.platform.icon)
                    summaryPill(title: viewModel.tone.rawValue, icon: "waveform.path.ecg")
                    summaryPill(title: viewModel.mode.rawValue, icon: "wand.and.stars")
                    summaryPill(title: subscriptionStore.entitlementTier.displayName, icon: subscriptionStore.isPro ? "crown.fill" : "sparkles")
                }

                if !subscriptionStore.isPro {
                    Text(featureAccessController.usageStatusText(settings: settings))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
    }

    private func summaryPill(title: String, icon: String) -> some View {
        TagChip(title: title, icon: icon)
    }

    private var generatorForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeaderView(
                        title: "Brief",
                        subtitle: "State the topic, the audience, and the category clearly. Better inputs lead to stronger outputs.",
                        eyebrow: "Signal"
                    )

                    promptField(title: "Topic or subject", text: $viewModel.topic, placeholder: "What should this piece be about?")
                    promptField(title: "Audience", text: $viewModel.audience, placeholder: "Who is this for?")
                    promptField(title: "Category", text: $viewModel.category, placeholder: "Mental Health, Gaming, Education...")
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeaderView(
                        title: "Channel fit",
                        subtitle: "Shape the format, tone, goal, and platform behavior before you generate.",
                        eyebrow: "System"
                    )

                    selectionGrid

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

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach([15, 25, 35, 45, 60], id: \.self) { preset in
                                    Button {
                                        viewModel.durationSeconds = Double(preset)
                                    } label: {
                                        TagChip(title: "\(preset)s", isSelected: Int(viewModel.durationSeconds) == preset, icon: "timer")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeaderView(
                        title: "Template boost",
                        subtitle: "Optional reusable framing to make the generated structure more intentional.",
                        eyebrow: "Framework"
                    )

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

    private var selectionGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                menuTile(title: "Platform", value: viewModel.platform.rawValue, icon: viewModel.platform.icon) {
                    ForEach(ContentPlatform.allCases) { platform in
                        Button(platform.rawValue) { viewModel.platform = platform }
                    }
                }

                menuTile(title: "Tone", value: viewModel.tone.rawValue, icon: "waveform.path.ecg") {
                    ForEach(ContentTone.allCases) { tone in
                        Button(tone.rawValue) { viewModel.tone = tone }
                    }
                }
            }

            HStack(spacing: 12) {
                menuTile(title: "Goal", value: viewModel.goal.rawValue, icon: "target") {
                    ForEach(ContentGoal.allCases) { goal in
                        Button(goal.rawValue) { viewModel.goal = goal }
                    }
                }

                menuTile(title: "Style", value: viewModel.style.rawValue, icon: "rectangle.3.group.bubble.left") {
                    ForEach(ContentStyle.allCases) { style in
                        Button(style.rawValue) { viewModel.style = style }
                    }
                }
            }

            HStack(spacing: 12) {
                menuTile(title: "Language", value: viewModel.language.rawValue, icon: "globe") {
                    ForEach(ContentLanguage.allCases) { language in
                        Button(language.rawValue) { viewModel.language = language }
                    }
                }

                menuTile(title: "Mode", value: viewModel.mode.rawValue, icon: "wand.and.stars") {
                    ForEach(GenerationMode.allCases) { mode in
                        Button(modeTitle(mode)) {
                            guard featureAccessController.canUseGenerationMode(mode) else {
                                paywallController.present(PaywallContext(reason: .batchIdeas))
                                return
                            }

                            viewModel.mode = mode
                        }
                    }
                }
            }
        }
    }

    private func menuTile<MenuContent: View>(title: String, value: String, icon: String, @ViewBuilder content: () -> MenuContent) -> some View {
        Menu {
            content()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textMuted)

                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.accentGlow)
                    Text(value)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func promptField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(2...4)
                .foregroundStyle(AppTheme.textPrimary)
                .premiumInputStyle()
        }
    }

    private func modeTitle(_ mode: GenerationMode) -> String {
        if mode == .batchIdeas && !subscriptionStore.isPro {
            return "\(mode.rawValue) • Pro"
        }
        return mode.rawValue
    }

    private func templateOption(template: TemplateModel?, title: String, description: String) -> some View {
        let isSelected = viewModel.selectedTemplate?.id == template?.id || (template == nil && viewModel.selectedTemplate == nil)
        let isLocked = template?.isPro == true && !subscriptionStore.isPro

        return Button {
            guard let template else {
                viewModel.applyTemplate(nil)
                return
            }

            guard featureAccessController.canUseTemplate(template) else {
                paywallController.present(PaywallContext(reason: .proTemplate(name: template.name)))
                return
            }

            viewModel.applyTemplate(template)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? Color.black : AppTheme.textPrimary)
                        Text(description)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelected ? Color.black.opacity(0.78) : AppTheme.textSecondary)
                    }
                    Spacer(minLength: 8)

                    if let template {
                        Text(template.accessLabel.uppercased())
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(isSelected ? Color.black.opacity(0.72) : (template.isPro ? AppTheme.warning : AppTheme.textMuted))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(isSelected ? Color.white.opacity(0.34) : (template.isPro ? AppTheme.warning.opacity(0.15) : AppTheme.surfaceTertiary))
                            )
                    }
                }

                Spacer()

                if let template {
                    Text(template.blueprint.isEmpty ? template.exampleHook : template.blueprint)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(isSelected ? Color.black.opacity(0.76) : AppTheme.textMuted)
                        .lineLimit(4)

                    HStack(spacing: 8) {
                        if let firstPlatform = template.idealPlatforms.first {
                            miniMetaPill(title: firstPlatform.rawValue, selected: isSelected)
                        }
                        miniMetaPill(title: template.recommendedTone.rawValue, selected: isSelected)
                        if isLocked {
                            miniMetaPill(title: "Locked", selected: isSelected)
                        }
                    }
                } else {
                    Text("Generate with more freedom.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(isSelected ? Color.black.opacity(0.76) : AppTheme.textMuted)
                        .lineLimit(3)
                }
            }
            .frame(width: 220, height: 170, alignment: .topLeading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.surfaceSecondary))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                    .stroke(isSelected ? Color.clear : AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func miniMetaPill(title: String, selected: Bool) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(selected ? Color.black.opacity(0.75) : AppTheme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? Color.white.opacity(0.26) : AppTheme.surfaceMuted)
            )
    }

    private func errorCard(message: String) -> some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.warning)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Check the brief")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(message)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Button {
                    viewModel.errorMessage = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.textMuted)
                        .padding(8)
                        .background(AppTheme.surfaceSecondary, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
