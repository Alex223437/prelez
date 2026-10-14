import Foundation
import Observation

/// State of the quick log (F4): the typed note and what it resolved to.
@Observable
final class QuickLogModel {
    var text = ""
    private(set) var isResolving = false
    /// Set after resolving; the confirmation sheet is shown while it is non-nil.
    var interpretation: QuickLogInterpretation?
    /// Shown when the AI failed and the rules were used instead.
    private(set) var notice: String?

    /// Uses the on-device model when it is available, otherwise rules only.
    func resolve(routes: [RouteInfo]) async {
        let note = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return }
        isResolving = true
        defer { isResolving = false }

        guard AIAvailability.isAvailable else {
            notice = AIAvailability.unavailableMessage
            interpretation = RuleBasedRouteResolver().interpretNow(note, routes: routes)
            return
        }
        do {
            notice = nil
            interpretation = try await HybridRouteResolver().interpret(note, routes: routes)
        } catch {
            // The model can refuse or fail (guardrails, timeout). The rules always work.
            notice = "AI selhala (\(error.localizedDescription)), použil jsem jen pravidla."
            interpretation = RuleBasedRouteResolver().interpretNow(note, routes: routes)
        }
    }

    func reset() {
        text = ""
        interpretation = nil
    }
}
