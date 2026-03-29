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
                configurations: [Self.makePersistentConfiguration(schema: schema)]
            )
        } catch {
            Self.logPersistentContainerFallback(error)

            do {
                container = try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration("AIContentMachine-InMemory", schema: schema, isStoredInMemoryOnly: true)]
                )
            } catch {
                fatalError("Unable to create any ModelContainer, including in-memory fallback: \(error)")
            }
        }
    }

    private static func makePersistentConfiguration(schema: Schema) throws -> ModelConfiguration {
        let fileManager = FileManager.default
        let appSupportDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let storeDirectory = appSupportDirectory.appendingPathComponent("AIContentMachine", isDirectory: true)

        if !fileManager.fileExists(atPath: storeDirectory.path) {
            try fileManager.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        }

        let storeURL = storeDirectory.appendingPathComponent("AIContentMachine.store")
        return ModelConfiguration("AIContentMachine", schema: schema, url: storeURL)
    }

    private static func logPersistentContainerFallback(_ error: Error) {
#if DEBUG
        NSLog("Persistent ModelContainer creation failed. Falling back to in-memory store. Error type: %@", String(describing: type(of: error)))
#else
        NSLog("Persistent ModelContainer creation failed. Falling back to in-memory store.")
#endif
    }
}
