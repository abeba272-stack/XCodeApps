import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
    }
}
