import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.accentGlow)
            }
        }
    }
}
