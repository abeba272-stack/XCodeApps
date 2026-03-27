import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?
    var icon: String = "sparkles.rectangle.stack.fill"
    var eyebrow: String? = nil

    var body: some View {
        VStack(spacing: 18) {
            Circle()
                .fill(AppTheme.surfaceSecondary)
                .frame(width: 70, height: 70)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AppTheme.accentGradient)
                }

            VStack(spacing: 8) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                }

                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(message)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let buttonTitle, let action {
                Button(buttonTitle, action: action)
                    .buttonStyle(AppPrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .premiumCardStyle()
    }
}
