#if DEBUG
import Foundation
import SwiftData

/// Debug-only launch arguments for screenshots and the defense demo. Not in Release builds.
///
/// - `-demoData`: on an empty store, imports the SAMPLE routes and logs a short session.
/// - `-tab routes|stats|search|session`: opens that tab.
enum DemoData {
    static var initialTab: AppTab? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-tab"), index + 1 < arguments.count else { return nil }
        switch arguments[index + 1] {
        case "routes": return .routes
        case "stats": return .stats
        case "search": return .search
        case "session": return .session
        default: return nil
        }
    }

    static func seedIfRequested(_ context: ModelContext) throws {
        guard ProcessInfo.processInfo.arguments.contains("-demoData"),
              try context.fetchCount(FetchDescriptor<Route>()) == 0
        else { return }

        _ = try SnapshotImporter(context: context).importBundledSample()
        context.insert(ClimbSession(startedAt: .now.addingTimeInterval(-65 * 60)))
        let logger = AttemptLogger(context: context)
        let plan: [(id: String, result: AttemptResult)] = [
            ("R-09", .send), ("R-05", .send), ("R-01", .fall), ("R-01", .fall), ("R-01", .send), ("B-05", .send),
        ]
        for (offset, step) in plan.enumerated() {
            guard let route = try logger.route(withID: step.id) else { continue }
            try logger.log(step.result, on: route, date: .now.addingTimeInterval(Double(offset - plan.count) * 600))
        }
    }
}
#endif
