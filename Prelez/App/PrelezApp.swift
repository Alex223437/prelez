import SwiftData
import SwiftUI

@main
struct PrelezApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        // The one shared container: the app and the App Intents read and write the same store.
        .modelContainer(AppModelContainer.shared)
    }
}
