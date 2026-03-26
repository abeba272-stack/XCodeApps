import SwiftUI

struct NicheSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeaderView(title: "Pick your niches", subtitle: "Select the spaces you create in most often.")

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AppBootstrapper.nichePresets, id: \.self) { niche in
                        Button {
                            viewModel.toggle(niche: niche)
                        } label: {
                            TagChip(title: niche, isSelected: viewModel.selectedNiches.contains(niche))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Custom category")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        TextField("Add your own niche", text: $viewModel.customNiche)
                            .padding(14)
                            .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .foregroundStyle(AppTheme.textPrimary)
                        if !viewModel.selectedNiches.isEmpty {
                            Text("Selected: \(viewModel.selectedNiches.joined(separator: ", "))")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(.top, 18)
            }
        }
    }
}
