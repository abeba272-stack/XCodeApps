import Foundation
import SwiftData

struct ModelContainerProvider {
    static let shared = ModelContainerProvider()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            ContentProject.self,
            UserProfile.self,
            TemplateModel.self,
            PlannerAssignment.self,
            AppSettings.self
        ])

        do {
            container = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration("AIContentMachine", schema: schema, isStoredInMemoryOnly: false)]
            )
        } catch {
            fatalError("Unable to create ModelContainer: \(error)")
        }
    }
}
