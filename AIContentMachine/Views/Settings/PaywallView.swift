import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var paywallController: PaywallController

    let context: PaywallContext

    @State private var selectedProductID: SubscriptionProductID = .yearly

    var body: some View {
        ZStack {
            PremiumBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroCard
                    benefitsCard
                    plansCard
                    footerCard
                }
                .padding(AppTheme.screenPadding)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("ACM Pro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    close()
                }
                .buttonStyle(AppQuietButtonStyle())
            }
        }
    }

    private var heroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    Circle()
                        .fill(AppTheme.accentGradient)
                        .frame(width: 52, height: 52)
                        .overlay {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.black.opacity(0.86))
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(context.subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Text(context.highlight)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )

                HStack(spacing: 10) {
                    statusPill(
                        title: subscriptionStore.isPro ? "Status" : "Plan",
                        value: subscriptionStore.entitlementTier.displayName,
                        icon: subscriptionStore.isPro ? "checkmark.seal.fill" : "sparkles"
                    )
                    statusPill(
                        title: "Templates",
                        value: "22 starter formats",
                        icon: "rectangle.stack.fill"
                    )
                    statusPill(
                        title: "Access",
                        value: "Unlimited flow",
                        icon: "bolt.fill"
                    )
                }
            }
        }
    }

    private func statusPill(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.accentGlow)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.surfaceSecondary, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var benefitsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(
                    title: "What Pro unlocks",
                    subtitle: "Built for creators who want a repeatable system, not just occasional prompts.",
                    eyebrow: "Upgrade"
                )

                ForEach(Array(FeatureAccessPolicy.proBenefits.enumerated()), id: \.offset) { _, benefit in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.success)
                        Text(benefit)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var plansCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderView(
                    title: "Choose your plan",
                    subtitle: "Yearly is highlighted as the default best-value option for consistent creators.",
                    eyebrow: "Plans"
                )

                VStack(spacing: 12) {
                    planCard(for: .yearly)
                    planCard(for: .monthly)
                }

                if let lastErrorMessage = subscriptionStore.lastErrorMessage {
                    Text(lastErrorMessage)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.warning)
                }

                if subscriptionStore.isPro {
                    if let manageSubscriptionsURL = AppExternalLinks.manageSubscriptionsURL {
                        Link("Manage Subscription", destination: manageSubscriptionsURL)
                            .buttonStyle(AppSecondaryButtonStyle())
                    } else {
                        Button("Manage Subscription unavailable") {}
                            .buttonStyle(AppSecondaryButtonStyle())
                            .disabled(true)
                            .opacity(0.7)
                    }
                } else if let product = selectedProduct {
                    Button {
                        Task { await purchase(product) }
                    } label: {
                        if subscriptionStore.isPurchasing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Start \(selectedProductID == .yearly ? "Yearly" : "Monthly") Pro")
                        }
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .disabled(subscriptionStore.isPurchasing)
                } else {
                    Button("Store products not loaded yet") {}
                        .buttonStyle(AppPrimaryButtonStyle())
                        .disabled(true)
                        .opacity(0.7)
                }

                Button("Restore Purchases") {
                    Task { await subscriptionStore.restorePurchases() }
                }
                .buttonStyle(AppQuietButtonStyle())
            }
        }
    }

    private func planCard(for productID: SubscriptionProductID) -> some View {
        let product = product(for: productID)
        let isSelected = selectedProductID == productID
        let isHighlighted = productID == .yearly

        return Button {
            selectedProductID = productID
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(productID.marketingTitle.replacingOccurrences(of: "ACM Pro ", with: ""))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(isSelected ? Color.black : AppTheme.textPrimary)
                            if isHighlighted {
                                planBadge(title: "Best Value", selected: isSelected)
                            }
                        }

                        Text(product?.subscriptionPeriodLabel ?? productID.marketingSubtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelected ? Color.black.opacity(0.72) : AppTheme.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product?.displayPrice ?? fallbackPrice(for: productID))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? Color.black : AppTheme.textPrimary)
                        Text(product == nil ? "Connect StoreKit config or App Store Connect" : productID.marketingSubtitle)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelected ? Color.black.opacity(0.72) : AppTheme.textMuted)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Text(productID.marketingSubtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? Color.black.opacity(0.8) : AppTheme.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.surfaceSecondary))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                    .stroke(isSelected ? Color.clear : AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func planBadge(title: String, selected: Bool) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(selected ? Color.black.opacity(0.75) : AppTheme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? Color.white.opacity(0.36) : AppTheme.surfaceTertiary)
            )
    }

    private var footerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderView(
                    title: "Subscription details",
                    subtitle: "Use Restore Purchases if you already subscribed. Manage subscriptions anytime from your Apple account.",
                    eyebrow: "Legal"
                )

                HStack(spacing: 10) {
                    footerLink(title: "Terms", url: AppExternalLinks.termsURL)
                    footerLink(title: "Privacy", url: AppExternalLinks.privacyURL)
                    footerLink(title: "Support", url: AppExternalLinks.supportURL)
                    footerLink(title: "Manage", url: AppExternalLinks.manageSubscriptionsURL)
                }
            }
        }
    }

    private var selectedProduct: Product? {
        product(for: selectedProductID)
    }

    private func product(for productID: SubscriptionProductID) -> Product? {
        subscriptionStore.products.first(where: { $0.id == productID.rawValue })
    }

    private func fallbackPrice(for productID: SubscriptionProductID) -> String {
        switch productID {
        case .monthly:
            return "€7.99"
        case .yearly:
            return "€59.99"
        }
    }

    private func purchase(_ product: Product) async {
        await subscriptionStore.purchase(product)
        if subscriptionStore.isPro {
            close()
        }
    }

    private func close() {
        paywallController.dismiss()
        dismiss()
    }

    @ViewBuilder
    private func footerLink(title: String, url: URL?) -> some View {
        if let url {
            Link(title, destination: url)
                .buttonStyle(AppQuietButtonStyle())
        } else {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.warning)
        }
    }
}
