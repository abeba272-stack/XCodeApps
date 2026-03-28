import Foundation

enum TemplateAccessTier: String, CaseIterable, Codable, Identifiable {
    case free = "Free"
    case pro = "Pro"

    var id: String { rawValue }

    var isPro: Bool {
        self == .pro
    }
}

enum AppEntitlementTier: String, Equatable {
    case free
    case pro

    var displayName: String {
        switch self {
        case .free: "Free"
        case .pro: "Pro"
        }
    }
}

enum SubscriptionProductID: String, CaseIterable {
    case monthly = "com.abebait.aicontentmachine.pro.monthly"
    case yearly = "com.abebait.aicontentmachine.pro.yearly"

    var marketingTitle: String {
        switch self {
        case .monthly:
            return "AI Content Machine Pro Monthly"
        case .yearly:
            return "AI Content Machine Pro Yearly"
        }
    }

    var marketingSubtitle: String {
        switch self {
        case .monthly:
            return "EUR 7.99 per month with full Pro access and flexible billing."
        case .yearly:
            return "EUR 59.99 per year. Best value for creators using the machine every week."
        }
    }
}

enum PremiumFeature: String, Identifiable, CaseIterable {
    case proTemplates = "All Pro templates"
    case unlimitedGenerations = "Unlimited generations"
    case batchIdeas = "Batch idea mode"
    case localAIServer = "Local AI server mode"
    case premiumExport = "Premium copy and export"

    var id: String { rawValue }
}

struct FeatureAccessPolicy {
    static let freeGenerationLimitPerMonth = 8
    static let starterTemplateSeedVersion = 2
    static let freeGenerationModes: Set<GenerationMode> = [.singleIdea, .fullPackage]
    static let proGenerationModes: Set<GenerationMode> = [.batchIdeas]
    static let freeProviderModes: Set<AIProviderMode> = [.mock]
    static let proProviderModes: Set<AIProviderMode> = [.customEndpoint]

    static var proBenefits: [String] {
        [
            "Unlock every Pro starter template and deeper creator formats.",
            "Remove the monthly generation cap and keep momentum without interruptions.",
            "Use Batch Ideas mode, Local AI Server mode, and premium export actions."
        ]
    }

    static func usageWindowStart(for date: Date, calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}

enum FeatureGateResult: Equatable {
    case allowed
    case paywall(PaywallContext)
}

enum PaywallTriggerReason: Equatable {
    case dashboardUpgrade
    case settingsUpgrade
    case proTemplate(name: String)
    case batchIdeas
    case generationLimitReached
    case localAIServer
    case premiumCopy
    case workspaceExport
}

struct PaywallContext: Identifiable, Equatable {
    let reason: PaywallTriggerReason

    var id: String {
        switch reason {
        case .dashboardUpgrade:
            return "dashboard-upgrade"
        case .settingsUpgrade:
            return "settings-upgrade"
        case .proTemplate(let name):
            return "pro-template-\(name)"
        case .batchIdeas:
            return "batch-ideas"
        case .generationLimitReached:
            return "generation-limit"
        case .localAIServer:
            return "local-ai-server"
        case .premiumCopy:
            return "premium-copy"
        case .workspaceExport:
            return "workspace-export"
        }
    }

    var title: String {
        switch reason {
        case .dashboardUpgrade:
            return "Upgrade to Pro"
        case .settingsUpgrade:
            return "Unlock the full creator system"
        case .proTemplate(let name):
            return "Unlock \(name)"
        case .batchIdeas:
            return "Batch Ideas is Pro"
        case .generationLimitReached:
            return "Free plan limit reached"
        case .localAIServer:
            return "Local AI Server is Pro"
        case .premiumCopy:
            return "Premium export tools are Pro"
        case .workspaceExport:
            return "Workspace export is Pro"
        }
    }

    var subtitle: String {
        switch reason {
        case .dashboardUpgrade:
            return "Move faster with more templates, more generations, and premium workflow tools."
        case .settingsUpgrade:
            return "Pro unlocks the deeper creator workflows that make the app feel like a full operating system."
        case .proTemplate(let name):
            return "\(name) is part of the Pro template library and is built for stronger creator-specific outputs."
        case .batchIdeas:
            return "Batch Ideas mode is designed for fast ideation sessions and is available on Pro."
        case .generationLimitReached:
            return "You have used all free generations for this month. Upgrade to keep creating without the cap."
        case .localAIServer:
            return "Connecting your own local AI server is a Pro workflow feature."
        case .premiumCopy:
            return "Full-package copy is part of the premium export toolkit."
        case .workspaceExport:
            return "Full workspace export is reserved for Pro creators."
        }
    }

    var highlight: String {
        switch reason {
        case .dashboardUpgrade, .settingsUpgrade:
            return "Built for creators who want a repeatable content system."
        case .proTemplate:
            return "Use stronger starter structures instead of beginning from a blank screen."
        case .batchIdeas:
            return "Generate multiple angles fast when you want a week's worth of ideas."
        case .generationLimitReached:
            return "Stay in flow instead of waiting for next month's free quota."
        case .localAIServer:
            return "Run advanced local generation pipelines without leaving the app."
        case .premiumCopy:
            return "Export polished full packages for faster production handoff."
        case .workspaceExport:
            return "Back up and move your full local workspace when you need it."
        }
    }

    var benefits: [String] {
        FeatureAccessPolicy.proBenefits
    }
}
