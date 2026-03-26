import SwiftUI
import SwiftData

struct BatchIdeasView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: ContentGeneratorViewModel
    @Bindable var project: ContentProject

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(project.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(project.overview)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)

                        HStack {
                            StatusBadge(status: project.status)
                            Spacer()
                            Text("Score \(project.contentScore)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.accentGlow)
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeaderView(title: "10 strong ideas", subtitle: "Built for \(project.platform.rawValue)")
                        ForEach(Array(project.batchIdeas.enumerated()), id: \.offset) { index, idea in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.accentGlow)
                                    .frame(width: 28, alignment: .leading)
                                Text(idea)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                        }
                    }
                }

                actionBar
            }
            .padding(20)
        }
        .navigationTitle("Batch Ideas")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var actionBar: some View {
        GlassCard {
            VStack(spacing: 12) {
                Button("Save Draft") {
                    viewModel.saveDraft(context: modelContext)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accentGlow)

                HStack(spacing: 12) {
                    CopyButton(title: "Copy All") { viewModel.copyFullPackage() }
                    Button {
                        viewModel.prepareSharePackage()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppTheme.surfaceSecondary, in: Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
