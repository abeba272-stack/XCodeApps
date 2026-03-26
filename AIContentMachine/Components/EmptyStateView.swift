import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 42))
                .foregroundStyle(AppTheme.accentGradient)
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .premiumCardStyle()
    }
}
