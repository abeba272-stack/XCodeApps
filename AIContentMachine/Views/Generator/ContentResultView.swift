import SwiftUI

struct ContentResultView: View {
    @EnvironmentObject private var subscriptionStore: SubscriptionStore

    @ObservedObject var viewModel: ContentGeneratorViewModel
    @Bindable var session: GenerationSession
    let settings: AppSettings

    @State private var selectedSection: ContentSection = .overview
    @State private var isEditing = false

    private var scriptLines: [String] {
        session.script
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var videoPrompt: String {
        viewModel.videoPromptText(for: session)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                snapshotCard
                if !videoPrompt.isEmpty {
                    videoPromptCard
                }
                sectionPicker
                contentSectionCard
                insightsCard
                actionsCard
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: keepSelectedSectionValid)
        .onChange(of: session.generationMode) { _, _ in keepSelectedSectionValid() }
        .onChange(of: session.updatedAt) { _, _ in keepSelectedSectionValid() }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Image(systemName: session.isFavorite ? "star.fill" : "star")
                }

                Button {
                    viewModel.prepareSharePackage()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .foregroundStyle(subscriptionStore.isPro ? AppTheme.textPrimary : AppTheme.warning)
            }
        }
        .sheet(isPresented: Binding(
            get: { !viewModel.shareItems.isEmpty },
            set: { if !$0 { viewModel.shareItems = [] } }
        )) {
            ShareSheet(items: viewModel.shareItems)
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.didCopyMessage {
                Text(message)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.accentGradient, in: Capsule(style: .continuous))
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(1.2))
                        viewModel.didCopyMessage = nil
                    }
            }
        }
    }

    private var heroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: session.platform.accentStartHex).opacity(0.18))
                                .frame(width: 42, height: 42)
                                .overlay {
                                    Image(systemName: session.platform.icon)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(Color(hex: session.platform.accentStartHex))
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.system(size: 29, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("\(session.platform.rawValue) • \(session.category) • \(session.durationLabel)")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }

                        Text(session.contentAngle.isEmpty ? session.overview : session.contentAngle)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    StatusBadge(status: session.status)
                }

                HStack(spacing: 10) {
                    metricPill(title: "Score", value: "\(session.contentScore)", accent: AppTheme.accentGlow)
                    metricPill(title: "Goal", value: session.goal.rawValue, accent: AppTheme.success)
                    metricPill(title: "Tone", value: session.tone.rawValue, accent: AppTheme.accentSecondary)
                }
            }
        }
    }

    private var snapshotCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: "Package snapshot",
                    subtitle: "The key framing decisions behind this result.",
                    eyebrow: "Summary"
                )

                VStack(spacing: 12) {
                    snapshotRow(label: "Audience", value: session.audienceSummary.isEmpty ? session.audience : session.audienceSummary)
                    snapshotRow(label: "Best time", value: session.bestPostingTime.isEmpty ? "Local heuristic available in full packages." : session.bestPostingTime)
                    snapshotRow(label: "Trigger", value: session.emotionalTrigger.isEmpty ? "Tension and clarity are balanced for the selected platform." : session.emotionalTrigger)
                    if let templateUsed = session.templateUsed, !templateUsed.isEmpty {
                        snapshotRow(label: "Template", value: templateUsed)
                    }
                }
            }
        }
    }

    private func snapshotRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var videoPromptCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: "Video AI Prompt",
                    subtitle: "Copy this modular short-form prompt directly into Veo, Sora, Runway, Kling, Pika, or another video generator.",
                    eyebrow: "Production"
                )

                ScrollView {
                    Text(videoPrompt)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 240, maxHeight: 320)
                .padding(14)
                .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )

                HStack(spacing: 10) {
                    Button("Copy Video Prompt") {
                        viewModel.copyVideoPrompt()
                    }
                    .buttonStyle(AppPrimaryButtonStyle())

                    CopyButton(title: subscriptionStore.isPro ? "Copy Full Package" : "Copy Full Package • Pro") {
                        viewModel.copyFullPackage()
                    }
                }
            }
        }
    }

    private func metricPill(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.surfaceSecondary, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
    }

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(availableSections) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        TagChip(title: section.rawValue, isSelected: selectedSection == section, icon: section.icon)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var contentSectionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedSection.rawValue)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(sectionSubtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    CopyButton(title: "Copy") { viewModel.copy(section: selectedSection) }
                }

                if isEditing {
                    editableSection
                } else {
                    readOnlySection
                }

                HStack(spacing: 10) {
                    if [.hook, .caption, .hashtags, .cta].contains(selectedSection) {
                        Button {
                            Task { await viewModel.regenerate(section: selectedSection, settings: settings) }
                        } label: {
                            Label("Regenerate Section", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(AppSecondaryButtonStyle())
                    }

                    Button(isEditing ? "Done Editing" : "Edit Manually") {
                        withAnimation(.smooth) {
                            isEditing.toggle()
                        }
                    }
                    .buttonStyle(AppQuietButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var readOnlySection: some View {
        switch selectedSection {
        case .overview:
            Text(session.overview)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .hook:
            VStack(alignment: .leading, spacing: 14) {
                hookCard(text: session.hook, title: "Primary hook")
                if !session.alternateHooks.isEmpty {
                    Text("Alternate hooks")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    ForEach(session.alternateHooks, id: \.self) { alt in
                        hookCard(text: alt, title: nil)
                    }
                }
            }

        case .script:
            VStack(alignment: .leading, spacing: 12) {
                if !scriptLines.isEmpty {
                    ForEach(Array(scriptLines.enumerated()), id: \.offset) { index, line in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.accentGlow)
                                .frame(width: 24, alignment: .leading)
                            Text(line.replacingOccurrences(of: #"^\d+\.\s"#, with: "", options: .regularExpression))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .padding(14)
                        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                    }
                }

                if !session.voiceover.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voiceover")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(session.voiceover)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(14)
                    .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                }
            }

        case .caption:
            sectionTextBlock(session.caption, prominent: false)

        case .hashtags:
            FlowLayout(items: session.hashtags)

        case .cta:
            sectionTextBlock(session.cta, prominent: true)

        case .shotList:
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(session.shotList.enumerated()), id: \.offset) { index, shot in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.accentGlow)
                            .frame(width: 24, alignment: .leading)
                        Text(shot)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(14)
                    .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                }
            }

        case .notes:
            Text(session.notes)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var editableSection: some View {
        switch selectedSection {
        case .overview:
            editorContainer(text: $session.overview, minHeight: 130)
        case .hook:
            editorContainer(
                text: Binding(
                    get: { ([session.hook] + session.alternateHooks).joined(separator: "\n") },
                    set: { value in
                        let parts = value.split(separator: "\n").map(String.init)
                        session.hook = parts.first ?? ""
                        session.alternateHooks = Array(parts.dropFirst())
                    }
                ),
                minHeight: 150
            )
        case .script:
            editorContainer(text: $session.script, minHeight: 200)
        case .caption:
            editorContainer(text: $session.caption, minHeight: 160)
        case .hashtags:
            editorContainer(
                text: Binding(
                    get: { session.hashtags.joined(separator: " ") },
                    set: { session.hashtags = $0.split(separator: " ").map(String.init) }
                ),
                minHeight: 120
            )
        case .cta:
            editorContainer(text: $session.cta, minHeight: 100)
        case .shotList:
            editorContainer(
                text: Binding(
                    get: { session.shotList.joined(separator: "\n") },
                    set: { session.shotList = $0.split(separator: "\n").map(String.init) }
                ),
                minHeight: 160
            )
        case .notes:
            editorContainer(text: $session.notes, minHeight: 120)
        }
    }

    private func editorContainer(text: Binding<String>, minHeight: CGFloat) -> some View {
        TextEditor(text: text)
            .scrollContentBackground(.hidden)
            .foregroundStyle(AppTheme.textPrimary)
            .frame(minHeight: minHeight)
            .padding(10)
            .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }

    private func hookCard(text: String, title: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textMuted)
            }
            Text(text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func sectionTextBlock(_ text: String, prominent: Bool) -> some View {
        Text(text)
            .font(.system(size: prominent ? 18 : 15, weight: prominent ? .bold : .medium, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }

    private var insightsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(
                    title: "Why this may perform",
                    subtitle: session.bestPostingTime.isEmpty ? "Local performance heuristics" : "Best time: \(session.bestPostingTime)",
                    eyebrow: "Insights"
                )

                Text(session.performanceRationale.isEmpty ? "This result is optimized as a lightweight idea draft." : session.performanceRationale)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                if !session.postingTip.isEmpty {
                    snapshotRow(label: "Posting tip", value: session.postingTip)
                }

                if !session.thumbnailSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Thumbnail / cover text")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        FlowLayout(items: session.thumbnailSuggestions)
                    }
                }

                if !session.postingChecklist.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Posting checklist")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(Array(session.postingChecklist.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.success)
                                Text(item)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var actionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(
                    title: "Actions",
                    subtitle: "Save it, refine it, duplicate it, or shift the angle without leaving the result.",
                    eyebrow: "Ship"
                )

                HStack(spacing: 10) {
                    Button("Save Draft") {
                        viewModel.saveDraft()
                    }
                    .buttonStyle(AppPrimaryButtonStyle())

                    Button("Regenerate") {
                        Task { await viewModel.regenerateAll(settings: settings) }
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                }

                HStack(spacing: 10) {
                    Button("Duplicate") {
                        viewModel.duplicate()
                    }
                    .buttonStyle(AppSecondaryButtonStyle())

                    CopyButton(title: subscriptionStore.isPro ? "Copy Full" : "Copy Full • Pro") {
                        viewModel.copyFullPackage()
                    }
                }

                HStack(spacing: 10) {
                    Menu("Tone Shift") {
                        ForEach(ContentTone.allCases) { tone in
                            Button(tone.rawValue) {
                                Task { await viewModel.applyToneShift(tone, settings: settings) }
                            }
                        }
                    }
                    .buttonStyle(AppQuietButtonStyle())

                    Menu("Change Length") {
                        ForEach([15, 25, 35, 45, 60], id: \.self) { seconds in
                            Button("\(seconds)s") {
                                Task { await viewModel.applyLengthShift(seconds, settings: settings) }
                            }
                        }
                    }
                    .buttonStyle(AppQuietButtonStyle())
                }
            }
        }
    }

    private var sectionSubtitle: String {
        switch selectedSection {
        case .overview:
            return "The high-level angle and positioning for this package."
        case .hook:
            return "Open with tension and give yourself alternate lead-ins."
        case .script:
            return "Core beats for recording, plus voiceover-ready copy."
        case .caption:
            return "A packaged text block that supports the angle without repeating it."
        case .hashtags:
            return "Platform-fit discovery tags generated from the topic and goal."
        case .cta:
            return "The final behavioral push for the viewer."
        case .shotList:
            return "Visual sequence suggestions to make filming easier."
        case .notes:
            return "Local generator notes and creator reminders."
        }
    }

    private var availableSections: [ContentSection] {
        switch session.generationMode {
        case .singleIdea:
            return [.overview, .hook, .cta, .notes]
        case .batchIdeas:
            return [.overview, .notes]
        case .fullPackage:
            return ContentSection.allCases.filter { section in
                switch section {
                case .overview:
                    return !session.overview.isEmpty
                case .hook:
                    return !session.hook.isEmpty
                case .script:
                    return !session.script.isEmpty || !session.voiceover.isEmpty
                case .caption:
                    return !session.caption.isEmpty
                case .hashtags:
                    return !session.hashtags.isEmpty
                case .cta:
                    return !session.cta.isEmpty
                case .shotList:
                    return !session.shotList.isEmpty
                case .notes:
                    return !session.notes.isEmpty
                }
            }
        }
    }

    private func keepSelectedSectionValid() {
        if !availableSections.contains(selectedSection) {
            selectedSection = availableSections.first ?? .overview
        }
    }
}

struct FlowLayout: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
            ForEach(items, id: \.self) { item in
                TagChip(title: item, isSelected: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
