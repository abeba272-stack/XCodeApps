import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var settings: [AppSettings]

    let templates: [TemplateModel]

    @StateObject private var viewModel = TemplatesViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard

                ForEach(viewModel.filteredTemplates(from: templates), id: \.id) { template in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(template.name)
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    TagChip(title: template.category, icon: "bookmark.fill")
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

                            FlowLayout(items: template.structureRules)

                            if let profile = profiles.first, let settings = settings.first {
                                NavigationLink {
                                    CreateContentView(profile: profile, settings: settings, templates: templates, initialTemplate: template)
                                } label: {
                                    Text("Use Template")
                                }
                                .buttonStyle(AppPrimaryButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .navigationTitle("Templates")
        .searchable(text: $viewModel.searchText, prompt: "Search templates")
    }

    private var heroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderView(
                    title: "Templates",
                    subtitle: "Ready-made creator formats that compress the time between idea and publishable package.",
                    eyebrow: "Frameworks"
                )

                HStack(spacing: 10) {
                    summaryPill(title: "Total", value: "\(templates.count)")
                    summaryPill(title: "Pinned", value: "\(templates.filter(\.isFavorite).count)")
                }
            }
        }
    }

    private func summaryPill(title: String, value: String) -> some View {
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
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}
