import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            GlassCard {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Create better content faster")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("AI Content Machine turns your niche, audience, tone, and goal into actual posting-ready content packages. Start with a few preferences and land in a working creator dashboard.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField("Your creator name", text: $viewModel.creatorName)
                        .textInputAutocapitalization(.words)
                        .padding(14)
                        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            GlassCard {
                HStack(spacing: 16) {
                    miniFeature(title: "Quick Generate", subtitle: "Go from idea to package in one flow", systemImage: "bolt.fill")
                    miniFeature(title: "Content Pipeline", subtitle: "Track idea, draft, ready, posted", systemImage: "chart.bar.fill")
                    miniFeature(title: "Planner", subtitle: "Plan daily and weekly output", systemImage: "calendar.badge.clock")
                }
            }

            Spacer()
        }
    }

    private func miniFeature(title: String, subtitle: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.accentGradient)
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
