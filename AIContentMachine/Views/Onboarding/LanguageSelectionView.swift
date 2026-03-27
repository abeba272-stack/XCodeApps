import SwiftUI

struct LanguageSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeaderView(title: "Set content language", subtitle: "The UI stays English for v1. Generated content will follow your selection.")

            HStack(spacing: 14) {
                ForEach(ContentLanguage.allCases) { language in
                    Button {
                        viewModel.selectedLanguage = language
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(language.shortCode)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.textMuted)
                            Text(language.rawValue)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(language == .german ? "German output, hooks, captions, and CTAs." : "English output, hooks, captions, and CTAs.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(viewModel.selectedLanguage == language ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.surface))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.white.opacity(viewModel.selectedLanguage == language ? 0 : 0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
    }
}
