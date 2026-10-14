import Foundation
import SwiftData

/// The only place that writes attempts. Used by the screens and by the App Intents,
/// so both follow the same rules (F2, F3, F6).
struct AttemptLogger {
    let context: ModelContext

    /// The running session, or a new one: an attempt outside a session starts a session (F3).
    func runningSession() throws -> ClimbSession {
        var descriptor = FetchDescriptor<ClimbSession>(
            predicate: #Predicate { $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        if let running = try context.fetch(descriptor).first {
            return running
        }
        let session = ClimbSession()
        context.insert(session)
        return session
    }

    /// Saves one attempt. Without an explicit style a send is flash on the first attempt, RP otherwise.
    @discardableResult
    func log(_ result: AttemptResult, style: AscentStyle? = nil, on route: Route, date: Date = .now) throws -> Attempt {
        let session = try runningSession()
        let finalStyle = result == .send
            ? (style ?? AscentStyle.inferred(previousAttemptCount: route.attempts.count))
            : nil
        let attempt = Attempt(result: result, style: finalStyle, route: route, session: session, date: date)
        context.insert(attempt)
        try context.save()
        return attempt
    }

    func startSession() throws {
        _ = try runningSession()
        try context.save()
    }

    func endSession(_ session: ClimbSession) throws {
        session.endedAt = .now
        try context.save()
    }

    /// Looks up a stored route by its snapshot ID (used by the intents and the quick log).
    func route(withID id: String) throws -> Route? {
        var descriptor = FetchDescriptor<Route>(predicate: #Predicate { $0.externalID == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
