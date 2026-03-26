import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let subtitle: String?
    var eyebrow: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                }

                Text(title)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer(minLength: 0)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(AppQuietButtonStyle())
            }
        }
    }
}
