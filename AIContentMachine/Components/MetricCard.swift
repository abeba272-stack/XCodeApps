import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    var accent: Color = AppTheme.accentGlow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                    .shadow(color: accent.opacity(0.55), radius: 10, x: 0, y: 0)
            }

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
    }
}
