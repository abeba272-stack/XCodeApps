import SwiftUI

struct GoalSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeaderView(title: "Define your goals", subtitle: "These power CTA suggestions, posting heuristics, and dashboard progress.")

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ContentGoal.allCases) { goal in
                    Button {
                        viewModel.toggle(goal: goal)
                    } label: {
                        TagChip(title: goal.rawValue, isSelected: viewModel.selectedGoals.contains(goal))
                            .frame(maxWidth: .infinity, minHeight: 46)
                    }
                    .buttonStyle(.plain)
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Selected goals")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(viewModel.selectedGoals.isEmpty ? "Choose at least one goal." : viewModel.selectedGoals.map(\.rawValue).sorted().joined(separator: ", "))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()
        }
    }
}
