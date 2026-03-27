import Foundation
import SwiftData

@MainActor
final class FeatureAccessController: ObservableObject {
    private let modelContainer: ModelContainer
    private let subscriptionStore: SubscriptionStore
    private let logger: any AppLogger

    init(modelContainer: ModelContainer, subscriptionStore: SubscriptionStore, logger: any AppLogger) {
        self.modelContainer = modelContainer
        self.subscriptionStore = subscriptionStore
        self.logger = logger
    }

    var entitlementTier: AppEntitlementTier {
        subscriptionStore.entitlementTier
    }

    var isPro: Bool {
        subscriptionStore.isPro
    }

    func canUseTemplate(_ template: TemplateModel) -> Bool {
        subscriptionStore.isPro || template.tier == .free
    }

    func canUseGenerationMode(_ mode: GenerationMode) -> Bool {
        subscriptionStore.isPro || FeatureAccessPolicy.freeGenerationModes.contains(mode)
    }

    func canUseProviderMode(_ mode: AIProviderMode) -> Bool {
        subscriptionStore.isPro || FeatureAccessPolicy.freeProviderModes.contains(mode)
    }

    func canCopyFullPackage() -> Bool {
        subscriptionStore.isPro
    }

    func canExportWorkspace() -> Bool {
        subscriptionStore.isPro
    }

    func generationGate(settings: AppSettings, mode: GenerationMode, template: TemplateModel?) -> FeatureGateResult {
        if let template, template.isPro, !canUseTemplate(template) {
            return .paywall(PaywallContext(reason: .proTemplate(name: template.name)))
        }

        if !canUseGenerationMode(mode) {
            return .paywall(PaywallContext(reason: .batchIdeas))
        }

        if !canUseProviderMode(settings.providerMode) {
            return .paywall(PaywallContext(reason: .localAIServer))
        }

        if remainingFreeGenerations(settings: settings) <= 0 && !subscriptionStore.isPro {
            return .paywall(PaywallContext(reason: .generationLimitReached))
        }

        return .allowed
    }

    func remainingFreeGenerations(settings: AppSettings, now: Date = .now) -> Int {
        normalizeUsageWindowIfNeeded(settings: settings, now: now, persistIfChanged: false)
        return max(0, FeatureAccessPolicy.freeGenerationLimitPerMonth - settings.freeGenerationCountInWindow)
    }

    func recordSuccessfulGeneration(settings: AppSettings, now: Date = .now) {
        guard !subscriptionStore.isPro else { return }

        normalizeUsageWindowIfNeeded(settings: settings, now: now, persistIfChanged: false)
        settings.freeGenerationCountInWindow += 1
        saveContext(reason: "Persisting generation usage failed")
    }

    func usageStatusText(settings: AppSettings) -> String {
        if subscriptionStore.isPro {
            return "Pro active • unlimited generations"
        }

        let remaining = remainingFreeGenerations(settings: settings)
        if remaining == 1 {
            return "1 free generation left this month"
        }
        return "\(remaining) free generations left this month"
    }

    private func normalizeUsageWindowIfNeeded(settings: AppSettings, now: Date, persistIfChanged: Bool) {
        let expectedStart = FeatureAccessPolicy.usageWindowStart(for: now)
        let currentStart = settings.generationWindowStartedAt.map { FeatureAccessPolicy.usageWindowStart(for: $0) }

        guard currentStart != expectedStart else { return }

        settings.generationWindowStartedAt = expectedStart
        settings.freeGenerationCountInWindow = 0

        if persistIfChanged {
            saveContext(reason: "Persisting generation usage window failed")
        }
    }

    private func saveContext(reason: String) {
        do {
            try modelContainer.mainContext.save()
        } catch {
            logger.error("\(reason): \(error.localizedDescription)", category: "FeatureAccessController")
        }
    }
}
