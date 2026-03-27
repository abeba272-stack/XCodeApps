import SwiftUI
import SwiftData

@main
struct AIContentMachineApp: App {
    @StateObject private var themeManager: ThemeManager
    @StateObject private var appContainer: AppContainer
    private let modelContainer: ModelContainer

    init() {
        let container = ModelContainerProvider.shared.container
        self.modelContainer = container
        _themeManager = StateObject(wrappedValue: ThemeManager())
        _appContainer = StateObject(wrappedValue: AppContainer(modelContainer: container))
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: appContainer)
                .environmentObject(themeManager)
                .environmentObject(appContainer.subscriptionStore)
                .environmentObject(appContainer.featureAccessController)
                .environmentObject(appContainer.paywallController)
                .preferredColorScheme(themeManager.colorScheme)
        }
        .modelContainer(modelContainer)
    }
}
