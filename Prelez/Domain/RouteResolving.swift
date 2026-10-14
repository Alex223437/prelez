import Foundation

/// Result of the quick log (F4): which route, and what happened on it.
nonisolated struct QuickLogInterpretation: Equatable, Sendable {
    var resolution: RouteResolution
    var result: AttemptResult?
    var style: AscentStyle?
    /// True when the on-device model was consulted (shown in the UI and in the eval report).
    var usedAI = false
    /// Why the model could not help, e.g. "unsupported language". The rules' answer is used instead.
    var aiNote: String?
}

/// Turns a free-text description into a route + outcome.
/// Implementations: rules only, rules + Foundation Models, and a deliberately dumb one for the eval.
protocol RouteResolving {
    func interpret(_ text: String, routes: [RouteInfo]) async throws -> QuickLogInterpretation
}

/// Rules only (F4 without AI, and the fallback when Apple Intelligence is unavailable or fails).
struct RuleBasedRouteResolver: RouteResolving {
    func interpret(_ text: String, routes: [RouteInfo]) async throws -> QuickLogInterpretation {
        interpretNow(text, routes: routes)
    }

    /// The rules never fail, so the fallback path needs no `try`.
    func interpretNow(_ text: String, routes: [RouteInfo]) -> QuickLogInterpretation {
        let query = QueryParser(routes: routes).parse(text)
        return QuickLogInterpretation(
            resolution: RouteMatcher().match(query, in: routes),
            result: query.result,
            style: query.style
        )
    }
}

/// Always answers "the first route, send". Exists only to prove the eval can fail (A12).
struct DumbRouteResolver: RouteResolving {
    func interpret(_ text: String, routes: [RouteInfo]) async throws -> QuickLogInterpretation {
        QuickLogInterpretation(
            resolution: routes.first.map { .unique($0) } ?? .notFound,
            result: .send,
            style: nil
        )
    }
}
