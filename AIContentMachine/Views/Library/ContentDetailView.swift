import SwiftUI
import SwiftData
import UIKit

struct ContentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var paywallController: PaywallController
    @Bindable var project: ContentProject
    @State private var errorMessage: String?

    private var videoPrompt: String {
        CopyExportService.videoPromptText(for: project)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                projectCard
                if !videoPrompt.isEmpty {
                    videoPromptCard
                }
                coreCopyCard
                scriptCard
                listCard
                notesCard
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .background(PremiumBackground())
        .navigationTitle("Content Detail")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    project.updatedAt = .now
                    do {
                        try modelContext.save()
                    } catch {
                        errorMessage = "The project could not be saved right now."
                    }
                }
                .buttonStyle(AppQuietButtonStyle())
            }
        }
        .alert("Project", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var videoPromptCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(
                    title: "Video AI Prompt",
                    subtitle: "Built from this saved project as a modular short-form prompt for realistic video generators.",
                    eyebrow: "Production"
                )

                ScrollView {
                    Text(videoPrompt)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 220, maxHeight: 320)
                .padding(14)
                .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )

                HStack(spacing: 10) {
                    CopyButton(title: "Copy Prompt") {
                        UIPasteboard.general.string = videoPrompt
                    }

                    CopyButton(title: subscriptionStore.isPro ? "Copy Full Package" : "Copy Full Package • Pro") {
                        guard subscriptionStore.isPro else {
                            paywallController.present(PaywallContext(reason: .premiumCopy))
                            return
                        }
                        UIPasteboard.general.string = CopyExportService.formattedPackage(for: project)
                    }
                }
            }
        }
    }

    private var heroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.title)
                            .font(.system(size: 29, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(project.platform.rawValue) • \(project.category) • Score \(project.contentScore)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    StatusBadge(status: project.status)
                }

                HStack(spacing: 10) {
                    TagChip(title: project.goal.rawValue, icon: "target")
                    TagChip(title: project.tone.rawValue, icon: "waveform.path.ecg")
                    TagChip(title: project.durationLabel, icon: "timer")
                }
            }
        }
    }

    private var projectCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(title: "Project", subtitle: "Core metadata and pipeline status.", eyebrow: "Meta")
                inputField("Title", text: $project.title)
                inputField("Topic", text: $project.topic)
                inputField("Category", text: $project.category)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Picker("Status", selection: Binding(
                        get: { project.status },
                        set: { project.status = $0 }
                    )) {
                        ForEach(ProjectStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var coreCopyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(title: "Core copy", subtitle: "High-signal text blocks the viewer actually sees.", eyebrow: "Copy")
                editorField("Overview", text: $project.overview, height: 120)
                editorField("Hook", text: $project.hook, height: 120)
                editorField("Caption", text: $project.caption, height: 160)
                editorField("CTA", text: $project.cta, height: 100)
            }
        }
    }

    private var scriptCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(title: "Script", subtitle: "Recording beats and voiceover copy.", eyebrow: "Delivery")
                editorField("Script", text: $project.script, height: 220)
                editorField("Voiceover", text: $project.voiceover, height: 150)
            }
        }
    }

    private var listCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(title: "Lists", subtitle: "Hashtags, shot list, and supporting structure.", eyebrow: "Assets")

                editorField(
                    "Hashtags",
                    text: Binding(
                        get: { project.hashtags.joined(separator: " ") },
                        set: { project.hashtags = $0.split(separator: " ").map(String.init) }
                    ),
                    height: 100
                )

                editorField(
                    "Shot list",
                    text: Binding(
                        get: { project.shotList.joined(separator: "\n") },
                        set: { project.shotList = $0.split(separator: "\n").map(String.init) }
                    ),
                    height: 150
                )
            }
        }
    }

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(title: "Notes", subtitle: "Local reminders and refinements.", eyebrow: "Notes")
                editorField("Notes", text: $project.notes, height: 150)
            }
        }
    }

    private func inputField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            TextField(title, text: text)
                .foregroundStyle(AppTheme.textPrimary)
                .premiumInputStyle()
        }
    }

    private func editorField(_ title: String, text: Binding<String>, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            TextEditor(text: text)
                .scrollContentBackground(.hidden)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(minHeight: height)
                .padding(10)
                .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        }
    }
}
