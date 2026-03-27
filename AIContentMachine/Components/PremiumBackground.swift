import SwiftUI

struct PremiumBackground: View {
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 220, style: .continuous)
                .fill(Color(hex: "#66D7FF").opacity(0.18))
                .frame(width: 340, height: 340)
                .blur(radius: 120)
                .offset(x: -150, y: -280)

            RoundedRectangle(cornerRadius: 260, style: .continuous)
                .fill(Color(hex: "#7A7CFF").opacity(0.16))
                .frame(width: 360, height: 360)
                .blur(radius: 140)
                .offset(x: 180, y: -80)

            RoundedRectangle(cornerRadius: 200, style: .continuous)
                .fill(Color(hex: "#61F0BF").opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 120)
                .offset(x: 140, y: 300)

            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}
