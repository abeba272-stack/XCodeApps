import SwiftUI

struct CopyButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "doc.on.doc")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppTheme.surfaceSecondary)
                )
        }
        .buttonStyle(.plain)
    }
}
