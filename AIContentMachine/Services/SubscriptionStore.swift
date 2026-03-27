import Foundation
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var entitlementTier: AppEntitlementTier = .free
    @Published private(set) var activeProductIDs: Set<String> = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var lastErrorMessage: String?

    private let logger: any AppLogger
    private var updatesTask: Task<Void, Never>?

    init(logger: any AppLogger) {
        self.logger = logger
        updatesTask = observeTransactionUpdates()

        Task {
            await prepare()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var isPro: Bool {
        entitlementTier == .pro
    }

    var monthlyProduct: Product? {
        products.first(where: { $0.id == SubscriptionProductID.monthly.rawValue })
    }

    var yearlyProduct: Product? {
        products.first(where: { $0.id == SubscriptionProductID.yearly.rawValue })
    }

    func prepare() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let fetched = try await Product.products(for: SubscriptionProductID.allCases.map(\.rawValue))
            let sortOrder = Dictionary(uniqueKeysWithValues: SubscriptionProductID.allCases.enumerated().map { ($1.rawValue, $0) })
            products = fetched.sorted { sortOrder[$0.id, default: 999] < sortOrder[$1.id, default: 999] }
            lastErrorMessage = nil
        } catch {
            logger.error("Loading StoreKit products failed: \(error.localizedDescription)", category: "SubscriptionStore")
            lastErrorMessage = "Subscription products are not available yet. Add the products in App Store Connect or assign the StoreKit configuration file in the scheme."
        }
    }

    func refreshEntitlements() async {
        var activeIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            activeIDs.insert(transaction.productID)
        }

        activeProductIDs = activeIDs
        entitlementTier = activeIDs.isEmpty ? .free : .pro
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                lastErrorMessage = nil
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            logger.error("StoreKit purchase failed: \(error.localizedDescription)", category: "SubscriptionStore")
            lastErrorMessage = "The purchase could not be completed right now."
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            lastErrorMessage = nil
        } catch {
            logger.error("Restore purchases failed: \(error.localizedDescription)", category: "SubscriptionStore")
            lastErrorMessage = "Purchases could not be restored right now."
        }
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            guard let self else { return }

            for await result in Transaction.updates {
                do {
                    let transaction = try self.handleTransactionUpdate(result)
                    await transaction.finish()
                    await self.refreshEntitlements()
                } catch {
                    self.logger.error("Transaction update handling failed: \(error.localizedDescription)", category: "SubscriptionStore")
                }
            }
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) throws -> Transaction {
        try checkVerified(result)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw AppError.ai("A subscription transaction could not be verified.")
        }
    }
}

@MainActor
final class PaywallController: ObservableObject {
    @Published var context: PaywallContext?

    func present(_ context: PaywallContext) {
        self.context = context
    }

    func dismiss() {
        context = nil
    }
}

extension Product {
    var subscriptionPeriodLabel: String {
        guard let period = subscription?.subscriptionPeriod else { return "Subscription" }

        switch period.unit {
        case .day:
            return period.value == 7 ? "Weekly" : "\(period.value)-day"
        case .week:
            return period.value == 1 ? "Weekly" : "\(period.value)-week"
        case .month:
            return period.value == 1 ? "Monthly" : "\(period.value)-month"
        case .year:
            return period.value == 1 ? "Yearly" : "\(period.value)-year"
        @unknown default:
            return "Subscription"
        }
    }
}
