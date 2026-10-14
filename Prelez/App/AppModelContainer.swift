import Foundation
import SwiftData

/// The one ModelContainer of the app.
/// The app scene and the App Intents both use `shared`. A second container would write
/// to a store the UI never sees (a silent bug from the App Intents lecture).
enum AppModelContainer {
    static let schema = Schema([Sector.self, Route.self, ClimbSession.self, Attempt.self])

    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema))
        } catch {
            // No silent fallback to an in-memory store: losing the climber's data quietly is worse than a crash.
            fatalError("Could not open the Přelez store: \(error)")
        }
    }()

    /// In-memory store for previews and tests.
    static func inMemory() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    }
}
