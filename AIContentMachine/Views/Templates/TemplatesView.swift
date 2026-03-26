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
                SectionHeaderView(title: "Templates", subtitle: "Ready-made creator formats you can reuse fast.")
                    .padding(.horizontal, 20)

                ForEach(viewModel.filteredTemplates(from: templates), id: \.id) { template in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(template.name)
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(template.category)
                                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Button {
                                    viewModel.toggleFavorite(template: template, context: modelContext)
                                } label: {
                                    Image(systemName: template.isFavorite ? "star.fill" : "star")
                                        .foregroundStyle(template.isFavorite ? AppTheme.accentGlow : AppTheme.textMuted)
                                }
                            }

                            Text(template.templateDescription)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            Text("Example hook: \(template.exampleHook)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            FlowLayout(items: template.structureRules)

                            if let profile = profiles.first, let settings = settings.first {
                                NavigationLink {
                                    CreateContentView(profile: profile, settings: settings, templates: templates, initialTemplate: template)
                                } label: {
                                    Text("Use Template")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
        .navigationTitle("Templates")
        .searchable(text: $viewModel.searchText, prompt: "Search templates")
    }
}
