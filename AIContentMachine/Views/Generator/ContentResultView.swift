import SwiftUI
import SwiftData

struct ContentResultView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: ContentGeneratorViewModel
    @Bindable var project: ContentProject
    let settings: AppSettings

    @State private var selectedSection: ContentSection = .overview
    @State private var isEditing = false

    private var scriptLines: [String] {
        project.script
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                snapshotCard
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
        .onAppear {
            keepSelectedSectionValid()
        }
        .onChange(of: project.generationMode) { _, _ in keepSelectedSectionValid() }
        .onChange(of: project.updatedAt) { _, _ in keepSelectedSectionValid() }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    project.isFavorite.toggle()
                    try? modelContext.save()
                } label: {
                    Image(systemName: project.isFavorite ? "star.fill" : "star")
                }

                Button {
                    viewModel.prepareSharePackage()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
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
                                .fill(Color(hex: project.platform.accentStartHex).opacity(0.18))
                                .frame(width: 42, height: 42)
                                .overlay {
                                    Image(systemName: project.platform.icon)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(Color(hex: project.platform.accentStartHex))
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.title)
                                    .font(.system(size: 29, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("\(project.platform.rawValue) • \(project.category) • \(project.durationLabel)")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }

                        Text(project.contentAngle.isEmpty ? project.overview : project.contentAngle)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    StatusBadge(status: project.status)
                }

                HStack(spacing: 10) {
                    metricPill(title: "Score", value: "\(project.contentScore)", accent: AppTheme.accentGlow)
                    metricPill(title: "Goal", value: project.goal.rawValue, accent: AppTheme.success)
                    metricPill(title: "Tone", value: project.tone.rawValue, accent: AppTheme.accentSecondary)
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
                    snapshotRow(label: "Audience", value: project.audienceSummary.isEmpty ? project.audience : project.audienceSummary)
                    snapshotRow(label: "Best time", value: project.bestPostingTime.isEmpty ? "Local heuristic available in full packages." : project.bestPostingTime)
                    snapshotRow(label: "Trigger", value: project.emotionalTrigger.isEmpty ? "Tension and clarity are balanced for the selected platform." : project.emotionalTrigger)
                    if let templateUsed = project.templateUsed, !templateUsed.isEmpty {
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
                        withAnimation(.smooth) { isEditing.toggle() }
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
            Text(project.overview)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .hook:
            VStack(alignment: .leading, spacing: 14) {
                hookCard(text: project.hook, title: "Primary hook")
                if !project.alternateHooks.isEmpty {
                    Text("Alternate hooks")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    ForEach(project.alternateHooks, id: \.self) { alt in
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

                if !project.voiceover.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voiceover")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(project.voiceover)
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
            Text(project.caption)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )

        case .hashtags:
            FlowLayout(items: project.hashtags)

        case .cta:
            Text(project.cta)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )

        case .shotList:
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(project.shotList.enumerated()), id: \.offset) { index, shot in
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
            Text(project.notes)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var editableSection: some View {
        switch selectedSection {
        case .overview:
            editorContainer(text: $project.overview, minHeight: 130)
        case .hook:
            editorContainer(
                text: Binding(
                    get: { ([project.hook] + project.alternateHooks).joined(separator: "\n") },
                    set: { value in
                        let parts = value.split(separator: "\n").map(String.init)
                        project.hook = parts.first ?? ""
                        project.alternateHooks = Array(parts.dropFirst())
                    }
                ),
                minHeight: 150
            )
        case .script:
            editorContainer(text: $project.script, minHeight: 200)
        case .caption:
            editorContainer(text: $project.caption, minHeight: 160)
        case .hashtags:
            editorContainer(
                text: Binding(
                    get: { project.hashtags.joined(separator: " ") },
                    set: { project.hashtags = $0.split(separator: " ").map(String.init) }
                ),
                minHeight: 120
            )
        case .cta:
            editorContainer(text: $project.cta, minHeight: 100)
        case .shotList:
            editorContainer(
                text: Binding(
                    get: { project.shotList.joined(separator: "\n") },
                    set: { project.shotList = $0.split(separator: "\n").map(String.init) }
                ),
                minHeight: 160
            )
        case .notes:
            editorContainer(text: $project.notes, minHeight: 120)
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

    private var insightsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(
                    title: "Why this may perform",
                    subtitle: project.bestPostingTime.isEmpty ? "Local performance heuristics" : "Best time: \(project.bestPostingTime)",
                    eyebrow: "Insights"
                )

                Text(project.performanceRationale.isEmpty ? "This result is optimized as a lightweight idea draft." : project.performanceRationale)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                if !project.postingTip.isEmpty {
                    snapshotRow(label: "Posting tip", value: project.postingTip)
                }

                if !project.thumbnailSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Thumbnail / cover text")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        FlowLayout(items: project.thumbnailSuggestions)
                    }
                }

                if !project.postingChecklist.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Posting checklist")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(Array(project.postingChecklist.enumerated()), id: \.offset) { index, item in
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
                        viewModel.saveDraft(context: modelContext)
                    }
                    .buttonStyle(AppPrimaryButtonStyle())

                    Button("Regenerate") {
                        Task { await viewModel.regenerateAll(settings: settings) }
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                }

                HStack(spacing: 10) {
                    Button("Duplicate") {
                        viewModel.duplicate(context: modelContext)
                    }
                    .buttonStyle(AppSecondaryButtonStyle())

                    CopyButton(title: "Copy Full") {
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
        switch project.generationMode {
        case .singleIdea:
            return [.overview, .hook, .cta, .notes]
        case .batchIdeas:
            return [.overview, .notes]
        case .fullPackage:
            return ContentSection.allCases.filter { section in
                switch section {
                case .overview:
                    return !project.overview.isEmpty
                case .hook:
                    return !project.hook.isEmpty
                case .script:
                    return !project.script.isEmpty || !project.voiceover.isEmpty
                case .caption:
                    return !project.caption.isEmpty
                case .hashtags:
                    return !project.hashtags.isEmpty
                case .cta:
                    return !project.cta.isEmpty
                case .shotList:
                    return !project.shotList.isEmpty
                case .notes:
                    return !project.notes.isEmpty
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
