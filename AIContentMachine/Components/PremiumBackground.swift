import SwiftUI

struct PremiumBackground: View {
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#65D6FF").opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 80)
                .offset(x: -120, y: -260)

            Circle()
                .fill(Color(hex: "#A36BFF").opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 100)
                .offset(x: 150, y: -120)

            Circle()
                .fill(Color(hex: "#57F0C1").opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 90)
                .offset(x: 100, y: 280)
        }
    }
}
