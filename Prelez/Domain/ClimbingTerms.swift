import Foundation

/// Rope route or boulder.
nonisolated enum RouteKind: String, Codable, CaseIterable, Sendable {
    case route
    case boulder

    var czechName: String {
        switch self {
        case .route: "cesta"
        case .boulder: "boulder"
        }
    }

    /// Ropes use French grades (lowercase), boulders use Font grades (uppercase).
    var gradeSystem: GradeSystem {
        switch self {
        case .route: .french
        case .boulder: .font
        }
    }
}

/// Outcome of one attempt.
nonisolated enum AttemptResult: String, Codable, CaseIterable, Sendable {
    case send
    case fall

    var czechName: String {
        switch self {
        case .send: "přelez"
        case .fall: "pád"
        }
    }
}

/// How a send happened.
nonisolated enum AscentStyle: String, Codable, CaseIterable, Sendable {
    /// First try, no beta.
    case onsight
    /// First try with beta.
    case flash
    /// Sent after earlier attempts.
    case redpoint
    /// Top rope, not lead.
    case topRope

    var shortName: String {
        switch self {
        case .onsight: "OS"
        case .flash: "flash"
        case .redpoint: "RP"
        case .topRope: "TR"
        }
    }

    /// Default style for a send: flash when it is the first attempt on the route, otherwise redpoint.
    /// Onsight and top rope can't be inferred, the climber has to say so.
    static func inferred(previousAttemptCount: Int) -> AscentStyle {
        previousAttemptCount == 0 ? .flash : .redpoint
    }
}
