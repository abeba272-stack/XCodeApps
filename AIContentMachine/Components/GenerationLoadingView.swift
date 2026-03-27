import SwiftUI

struct GenerationLoadingView: View {
    @State private var activeStep = 0

    private let steps = [
        "Reading the topic brief",
        "Mapping platform heuristics",
        "Structuring hooks and script beats",
        "Packaging caption, CTA, and posting cues"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(AppTheme.accentGlow)
                    .scaleEffect(1.15)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Building your content package")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Offline mock mode is generating structured copy with platform-specific logic.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            VStack(spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(index <= activeStep ? AppTheme.accentGlow : AppTheme.surfaceTertiary)
                            .frame(width: 9, height: 9)
                            .shadow(color: index <= activeStep ? AppTheme.accentGlow.opacity(0.4) : .clear, radius: 10, x: 0, y: 0)

                        Text(step)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(index <= activeStep ? AppTheme.textPrimary : AppTheme.textMuted)

                        Spacer()
                    }
                }
            }

            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                    .fill(AppTheme.surfaceSecondary)
                    .frame(height: 70)
                RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                    .fill(AppTheme.surfaceSecondary)
                    .frame(height: 132)
                RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                    .fill(AppTheme.surfaceSecondary)
                    .frame(height: 84)
            }
            .redacted(reason: .placeholder)
        }
        .task {
            while true {
                try? await Task.sleep(for: .milliseconds(550))
                activeStep = (activeStep + 1) % steps.count
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
    }
}
