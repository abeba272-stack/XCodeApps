import SwiftUI

struct TagChip: View {
    let title: String
    var isSelected: Bool = false
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
            }
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(isSelected ? Color.black : AppTheme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.surfaceSecondary))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AppTheme.border, lineWidth: isSelected ? 0 : 1)
        )
    }
}
