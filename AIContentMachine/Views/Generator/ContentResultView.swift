import SwiftUI
import SwiftData

struct ContentResultView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: ContentGeneratorViewModel
    @Bindable var project: ContentProject
    let settings: AppSettings

    @State private var selectedSection: ContentSection = .overview
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                sectionPicker
                contentSectionCard
                insightsCard
                actionsCard
            }
            .padding(20)
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !availableSections.contains(selectedSection) {
                selectedSection = availableSections.first ?? .overview
            }
        }
        .onChange(of: project.generationMode) { _, _ in
            if !availableSections.contains(selectedSection) {
                selectedSection = availableSections.first ?? .overview
            }
        }
        .onChange(of: project.updatedAt) { _, _ in
            if !availableSections.contains(selectedSection) {
                selectedSection = availableSections.first ?? .overview
            }
        }
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
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(project.platform.rawValue) • \(project.category) • \(project.durationLabel)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    StatusBadge(status: project.status)
                }

                HStack(spacing: 12) {
                    metricPill(title: "Score", value: "\(project.contentScore)")
                    metricPill(title: "Goal", value: project.goal.rawValue)
                    metricPill(title: "Tone", value: project.tone.rawValue)
                }
            }
        }
    }

    private func metricPill(title: String, value: String) -> some View {
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
    }

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(availableSections) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        TagChip(title: section.rawValue, isSelected: selectedSection == section)
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
                HStack {
                    Text(selectedSection.rawValue)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    CopyButton(title: "Copy") { viewModel.copy(section: selectedSection) }
                }

                if isEditing {
                    editableSection
                } else {
                    readOnlySection
                }

                HStack(spacing: 12) {
                    if [.hook, .caption, .hashtags, .cta].contains(selectedSection) {
                        Button {
                            Task { await viewModel.regenerate(section: selectedSection, settings: settings) }
                        } label: {
                            Label("Regenerate Section", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .buttonStyle(.bordered)
                        .tint(AppTheme.accentGlow)
                    }

                    Button(isEditing ? "Done Editing" : "Edit Manually") {
                        withAnimation(.smooth) { isEditing.toggle() }
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.textSecondary)
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
                .foregroundStyle(AppTheme.textSecondary)
        case .hook:
            VStack(alignment: .leading, spacing: 12) {
                Text(project.hook)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                ForEach(project.alternateHooks, id: \.self) { alt in
                    Text("• \(alt)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        case .script:
            VStack(alignment: .leading, spacing: 16) {
                if !project.script.isEmpty {
                    Text(project.script)
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !project.voiceover.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voiceover")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(project.voiceover)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        case .caption:
            Text(project.caption)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        case .hashtags:
            FlowLayout(items: project.hashtags)
        case .cta:
            Text(project.cta)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        case .shotList:
            VStack(alignment: .leading, spacing: 10) {
                ForEach(project.shotList, id: \.self) { shot in
                    Text("• \(shot)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        case .notes:
            Text(project.notes)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var editableSection: some View {
        switch selectedSection {
        case .overview:
            TextEditor(text: $project.overview).frame(minHeight: 120)
        case .hook:
            TextEditor(text: Binding(
                get: { ([project.hook] + project.alternateHooks).joined(separator: "\n") },
                set: { value in
                    let parts = value.split(separator: "\n").map(String.init)
                    project.hook = parts.first ?? ""
                    project.alternateHooks = Array(parts.dropFirst())
                }
            )).frame(minHeight: 150)
        case .script:
            TextEditor(text: $project.script).frame(minHeight: 200)
        case .caption:
            TextEditor(text: $project.caption).frame(minHeight: 160)
        case .hashtags:
            TextEditor(text: Binding(
                get: { project.hashtags.joined(separator: " ") },
                set: { project.hashtags = $0.split(separator: " ").map(String.init) }
            )).frame(minHeight: 120)
        case .cta:
            TextEditor(text: $project.cta).frame(minHeight: 100)
        case .shotList:
            TextEditor(text: Binding(
                get: { project.shotList.joined(separator: "\n") },
                set: { project.shotList = $0.split(separator: "\n").map(String.init) }
            )).frame(minHeight: 160)
        case .notes:
            TextEditor(text: $project.notes).frame(minHeight: 120)
        }
    }

    private var insightsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(title: "Why this may perform", subtitle: project.bestPostingTime.isEmpty ? nil : "Best time: \(project.bestPostingTime)")
                Text(project.performanceRationale.isEmpty ? "This result is optimized as a lightweight idea draft." : project.performanceRationale)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                if !project.thumbnailSuggestions.isEmpty {
                    Text("Thumbnail / cover text")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    FlowLayout(items: project.thumbnailSuggestions)
                }

                if !project.postingChecklist.isEmpty {
                    Text("Posting checklist")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(project.postingChecklist, id: \.self) { item in
                            Text("• \(item)")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var actionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(title: "Actions", subtitle: "Ship, refine, duplicate, or shift the angle.")

                HStack(spacing: 12) {
                    Button("Save Draft") {
                        viewModel.saveDraft(context: modelContext)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentGlow)

                    Button("Regenerate") {
                        Task { await viewModel.regenerateAll(settings: settings) }
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.textSecondary)

                    Button("Duplicate") {
                        viewModel.duplicate(context: modelContext)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.textSecondary)
                }

                HStack(spacing: 12) {
                    CopyButton(title: "Copy Full") { viewModel.copyFullPackage() }
                    Menu("Tone Shift") {
                        ForEach(ContentTone.allCases) { tone in
                            Button(tone.rawValue) {
                                Task { await viewModel.applyToneShift(tone, settings: settings) }
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.textSecondary)

                    Menu("Change Length") {
                        ForEach([15, 25, 35, 45, 60], id: \.self) { seconds in
                            Button("\(seconds)s") {
                                Task { await viewModel.applyLengthShift(seconds, settings: settings) }
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.textSecondary)
                }
            }
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
