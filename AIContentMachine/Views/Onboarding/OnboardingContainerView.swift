import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    let profile: UserProfile

    @StateObject private var viewModel = OnboardingViewModel()
    @State private var step = 0

    private let totalSteps = 7

    var body: some View {
        VStack(spacing: 24) {
            progressHeader

            Group {
                switch step {
                case 0: WelcomeView(viewModel: viewModel)
                case 1: NicheSelectionView(viewModel: viewModel)
                case 2: PlatformSelectionView(viewModel: viewModel)
                case 3: LanguageSelectionView(viewModel: viewModel)
                case 4: ToneSelectionView(viewModel: viewModel)
                case 5: GoalSelectionView(viewModel: viewModel)
                default: PostingFrequencyView(viewModel: viewModel)
                }
            }
            .frame(maxHeight: .infinity)

            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 28)
        .onAppear {
            viewModel.preload(from: profile)
        }
        .alert("Onboarding", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACM")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("Step \(step + 1)/\(totalSteps)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            GeometryReader { proxy in
                let width = proxy.size.width
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(AppTheme.surfaceSecondary)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .fill(AppTheme.accentGradient)
                            .frame(width: width * CGFloat(step + 1) / CGFloat(totalSteps))
                    }
            }
            .frame(height: 8)
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            if step > 0 {
                Button {
                    withAnimation(.smooth) {
                        step -= 1
                    }
                } label: {
                    Text("Back")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }

            Button {
                if step < totalSteps - 1 {
                    viewModel.appendCustomNicheIfNeeded()
                    withAnimation(.smooth) {
                        step += 1
                    }
                } else {
                    _ = viewModel.save(into: profile, context: modelContext)
                }
            } label: {
                Text(step == totalSteps - 1 ? "Finish" : "Continue")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }
}
