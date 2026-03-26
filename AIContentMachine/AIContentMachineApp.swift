import SwiftUI
import SwiftData

@main
struct AIContentMachineApp: App {
    @StateObject private var themeManager = ThemeManager()
    private let modelContainer = ModelContainerProvider.shared.container

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
        .modelContainer(modelContainer)
    }
}
