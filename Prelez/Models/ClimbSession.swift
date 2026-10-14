import Foundation
import SwiftData

/// One training session at the gym (F3).
@Model
final class ClimbSession {
    var startedAt: Date
    var endedAt: Date?

    /// Deleting a session deletes its attempts.
    @Relationship(deleteRule: .cascade, inverse: \Attempt.session)
    var attempts: [Attempt] = []

    init(startedAt: Date = .now) {
        self.startedAt = startedAt
    }

    var isRunning: Bool { endedAt == nil }
    var sendCount: Int { attempts.filter { $0.result == .send }.count }
}
