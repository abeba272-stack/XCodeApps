import SwiftUI

struct BatchIdeasView: View {
    @ObservedObject var viewModel: ContentGeneratorViewModel
    @Bindable var session: GenerationSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                ideasCard
                actionBar
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .navigationTitle("Batch Ideas")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { !viewModel.shareItems.isEmpty },
            set: { if !$0 { viewModel.shareItems = [] } }
        )) {
            ShareSheet(items: viewModel.shareItems)
        }
    }

    private var heroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.title)
                            .font(.system(size: 29, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(session.overview)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    StatusBadge(status: session.status)
                }

                HStack(spacing: 10) {
                    TagChip(title: session.platform.rawValue, icon: session.platform.icon)
                    TagChip(title: "Score \(session.contentScore)", isSelected: session.contentScore >= 80, icon: "sparkles")
                    TagChip(title: session.goal.rawValue, icon: "target")
                }
            }
        }
    }

    private var ideasCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(
                    title: "10 strong ideas",
                    subtitle: "Built for \(session.platform.rawValue) with reusable creator angles.",
                    eyebrow: "Batch"
                )

                ForEach(Array(session.batchIdeas.enumerated()), id: \.offset) { index, idea in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.accentGlow)
                            .frame(width: 28, alignment: .leading)

                        Text(idea)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
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
        }
    }

    private var actionBar: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderView(
                    title: "Actions",
                    subtitle: "Save the batch, copy it, or share it as a formatted text block.",
                    eyebrow: "Export"
                )

                Button("Save Draft") {
                    viewModel.saveDraft()
                }
                .buttonStyle(AppPrimaryButtonStyle())

                HStack(spacing: 10) {
                    CopyButton(title: "Copy All") { viewModel.copyFullPackage() }

                    Button {
                        viewModel.prepareSharePackage()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(AppQuietButtonStyle())
                }
            }
        }
    }
}
