import SwiftUI

struct ToneSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeaderView(title: "Choose your default tone", subtitle: "You can still change tone per generation request.")

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ContentTone.allCases) { tone in
                    Button {
                        viewModel.selectedTone = tone
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(tone.rawValue)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Text(viewModel.selectedLanguage == .german ? tone.descriptorDe : tone.descriptorEn)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundStyle(viewModel.selectedTone == tone ? Color.black : AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(viewModel.selectedTone == tone ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.surfaceSecondary))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
    }
}
