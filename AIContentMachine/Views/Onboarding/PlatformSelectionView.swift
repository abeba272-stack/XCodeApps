import SwiftUI

struct PlatformSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeaderView(title: "Choose platforms", subtitle: "These defaults shape dashboard suggestions and generation presets.")

            VStack(spacing: 14) {
                ForEach(ContentPlatform.allCases) { platform in
                    Button {
                        viewModel.toggle(platform: platform)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: platform.icon)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(LinearGradient(
                                    colors: [Color(hex: platform.accentStartHex), Color(hex: platform.accentEndHex)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(platform.rawValue)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(platform.pacingDescription.capitalized)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: viewModel.selectedPlatforms.contains(platform) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(viewModel.selectedPlatforms.contains(platform) ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.textMuted))
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(viewModel.selectedPlatforms.contains(platform) ? Color.white.opacity(0.22) : AppTheme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
