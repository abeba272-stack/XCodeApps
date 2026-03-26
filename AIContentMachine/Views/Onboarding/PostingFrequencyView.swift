import SwiftUI

struct PostingFrequencyView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeaderView(title: "Set your weekly posting goal", subtitle: "This drives progress and planner targets. You can edit it later in Settings.")

            GlassCard {
                VStack(alignment: .leading, spacing: 18) {
                    Text("\(Int(viewModel.postingFrequency)) posts / week")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Slider(value: $viewModel.postingFrequency, in: 1...14, step: 1)
                        .tint(AppTheme.accentGlow)

                    Text("A realistic cadence keeps the dashboard meaningful and the planner streak useful.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()
        }
    }
}
