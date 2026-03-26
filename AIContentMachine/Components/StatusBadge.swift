import SwiftUI

struct StatusBadge: View {
    let status: ProjectStatus

    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(status.color)
            .background(
                Capsule(style: .continuous)
                    .fill(status.color.opacity(0.12))
            )
    }
}
