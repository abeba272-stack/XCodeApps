import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var featureAccessController: FeatureAccessController
    @EnvironmentObject private var paywallController: PaywallController

    @Query private var profiles: [UserProfile]
    @Query private var settings: [AppSettings]

    let templates: [TemplateModel]
    let container: AppContainer

    @StateObject private var viewModel = TemplatesViewModel()
    @State private var selectedTemplate: TemplateModel?

    private var freeCount: Int {
        templates.filter { $0.tier == .free }.count
    }

    private var proCount: Int {
        templates.filter(\.isPro).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard

                ForEach(viewModel.filteredTemplates(from: templates), id: \.id) { template in
                    templateCard(template)
                }
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .navigationTitle("Templates")
        .searchable(text: $viewModel.searchText, prompt: "Search templates")
        .navigationDestination(item: $selectedTemplate) { template in
            if let profile = profiles.first, let settings = settings.first {
                CreateContentView(profile: profile, settings: settings, templates: templates, container: container, initialTemplate: template)
            }
        }
        .alert("Templates", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var heroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderView(
                    title: "Templates",
                    subtitle: "High-signal creator formats you can use immediately instead of starting from a blank brief.",
                    eyebrow: "Frameworks",
                    actionTitle: subscriptionStore.isPro ? nil : "Upgrade",
                    action: subscriptionStore.isPro ? nil : { paywallController.present(PaywallContext(reason: .dashboardUpgrade)) }
                )

                HStack(spacing: 10) {
                    summaryPill(title: "Total", value: "\(templates.count)", accent: AppTheme.accentGlow)
                    summaryPill(title: "Free", value: "\(freeCount)", accent: AppTheme.success)
                    summaryPill(title: "Pro", value: "\(proCount)", accent: AppTheme.warning)
                    summaryPill(title: "Pinned", value: "\(templates.filter(\.isFavorite).count)", accent: AppTheme.accentSecondary)
                }

                if !subscriptionStore.isPro {
                    Text("Free templates stay fully usable. Pro unlocks the deeper creator archetypes, conversion structures, and faster ideation flows.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
    }

    private func summaryPill(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
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

    private func templateCard(_ template: TemplateModel) -> some View {
        let isLocked = template.isPro && !featureAccessController.canUseTemplate(template)

        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(template.name)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            accessBadge(for: template)
                        }

                        HStack(spacing: 8) {
                            TagChip(title: template.category, icon: "bookmark.fill")
                            if let firstPlatform = template.idealPlatforms.first {
                                TagChip(title: firstPlatform.rawValue, icon: firstPlatform.icon)
                            }
                        }
                    }

                    Spacer()

                    Button {
                        viewModel.toggleFavorite(template: template, context: modelContext)
                    } label: {
                        Image(systemName: template.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(template.isFavorite ? AppTheme.warning : AppTheme.textMuted)
                    }
                }

                Text(template.templateDescription)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                insightBlock(
                    title: "Blueprint",
                    body: template.blueprint,
                    fallback: template.exampleHook
                )

                HStack(spacing: 10) {
                    metaPill(title: "Tone", value: template.recommendedTone.rawValue)
                    metaPill(title: "Goal", value: template.recommendedGoal.rawValue)
                    metaPill(title: "Style", value: template.recommendedStyle.rawValue)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Structure rules")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                    FlowLayout(items: template.structureRules)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Example hook")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                    Text(template.exampleHook)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(14)
                .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )

                if !template.exampleScriptDirection.isEmpty {
                    insightBlock(
                        title: "Script direction",
                        body: template.exampleScriptDirection,
                        fallback: nil
                    )
                }

                if !template.exampleCaptionDirection.isEmpty {
                    insightBlock(
                        title: "Caption direction",
                        body: template.exampleCaptionDirection,
                        fallback: nil
                    )
                }

                if isLocked {
                    Button {
                        useTemplate(template)
                    } label: {
                        Label("Unlock Template", systemImage: "lock.fill")
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                } else {
                    Button("Use Template") {
                        useTemplate(template)
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                }
            }
        }
    }

    private func accessBadge(for template: TemplateModel) -> some View {
        Text(template.accessLabel.uppercased())
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(template.isPro ? AppTheme.warning : AppTheme.success)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill((template.isPro ? AppTheme.warning : AppTheme.success).opacity(0.12))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke((template.isPro ? AppTheme.warning : AppTheme.success).opacity(0.18), lineWidth: 1)
            )
    }

    private func metaPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func insightBlock(title: String, body: String, fallback: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
            Text(body.isEmpty ? (fallback ?? "") : body)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func useTemplate(_ template: TemplateModel) {
        guard featureAccessController.canUseTemplate(template) else {
            paywallController.present(PaywallContext(reason: .proTemplate(name: template.name)))
            return
        }

        selectedTemplate = template
    }
}
