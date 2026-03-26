import SwiftUI

struct GenerationLoadingView: View {
    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .tint(AppTheme.accentGlow)
                .scaleEffect(1.2)
            Text("Building your content package")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Generating platform-specific hooks, script beats, caption angles, and posting cues.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.surfaceSecondary)
                    .frame(height: 64)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.surfaceSecondary)
                    .frame(height: 110)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.surfaceSecondary)
                    .frame(height: 72)
            }
            .redacted(reason: .placeholder)
        }
        .frame(maxWidth: .infinity)
        .premiumCardStyle()
    }
}
