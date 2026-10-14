import Foundation

/// One hand-written test case for the quick log (F4).
nonisolated struct GoldenCase: Identifiable, Sendable {
    enum Expectation: Sendable {
        /// Exactly this route must be chosen.
        case route(String)
        /// The resolver must let the user pick (ambiguous or near match) and offer at least these routes.
        case ambiguous(Set<String>)
        /// Nothing may be chosen. Choosing anything is a hallucination.
        case notFound
    }

    let id: String
    let input: String
    let expected: Expectation
    /// Expected outcome, or nil when the case does not test it.
    var expectedResult: AttemptResult?
}

nonisolated enum EvalScoring {
    /// Passing threshold for the mean score (A12).
    static let threshold = 0.8

    /// 0.7 × correct route + 0.3 × correct result. Without an expected result, the route alone counts.
    static func score(_ interpretation: QuickLogInterpretation, for golden: GoldenCase) -> Double {
        let routeScore: Double
        switch (golden.expected, interpretation.resolution) {
        case (.route(let id), .unique(let route)):
            routeScore = route.id == id ? 1 : 0
        case (.ambiguous(let ids), .ambiguous(let routes)), (.ambiguous(let ids), .nearMatch(let routes)):
            routeScore = ids.isSubset(of: Set(routes.map(\.id))) ? 1 : 0
        case (.notFound, .notFound):
            routeScore = 1
        default:
            // Includes the dangerous case: an ambiguous text silently resolved to one route.
            routeScore = 0
        }
        guard let expectedResult = golden.expectedResult else { return routeScore }
        let resultScore: Double = interpretation.result == expectedResult ? 1 : 0
        return 0.7 * routeScore + 0.3 * resultScore
    }
}

nonisolated struct EvalReport: Sendable {
    struct CaseResult: Sendable {
        let id: String
        let input: String
        /// One score per run.
        let scores: [Double]
        let usedAI: Bool
        /// What the resolver answered in each run, e.g. "unique R-05", "ambiguous ×4", "error: …".
        let answers: [String]

        var mean: Double { scores.reduce(0, +) / Double(max(scores.count, 1)) }
        var worst: Double { scores.min() ?? 0 }
    }

    let resolverName: String
    let cases: [CaseResult]

    var mean: Double { cases.map(\.mean).reduce(0, +) / Double(max(cases.count, 1)) }
    var worstCase: CaseResult? { cases.min { $0.mean < $1.mean } }
    var passes: Bool { mean >= EvalScoring.threshold }

    /// Text table for the test log and LAB notes.
    var table: String {
        var lines = ["Eval \(resolverName): mean \(Self.format(mean)) (threshold \(Self.format(EvalScoring.threshold)))"]
        for result in cases {
            let ai = result.usedAI ? " [AI]" : ""
            let runs = result.scores.map(Self.format).joined(separator: " ")
            lines.append("  \(result.id)\(ai): mean \(Self.format(result.mean)) worst \(Self.format(result.worst)) runs [\(runs)] — \(result.input)")
            if result.mean < 1 {
                lines.append("      answers: \(result.answers.joined(separator: " | "))")
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

/// Runs every golden case several times. The model is stochastic, one run proves nothing.
struct EvalRunner {
    let resolver: any RouteResolving
    let resolverName: String
    let routes: [RouteInfo]

    func run(_ cases: [GoldenCase], runs: Int = 3) async -> EvalReport {
        var results: [EvalReport.CaseResult] = []
        for golden in cases {
            var scores: [Double] = []
            var answers: [String] = []
            var usedAI = false
            for _ in 0..<runs {
                do {
                    let interpretation = try await resolver.interpret(golden.input, routes: routes)
                    usedAI = usedAI || interpretation.usedAI
                    scores.append(EvalScoring.score(interpretation, for: golden))
                    answers.append(Self.describe(interpretation))
                } catch {
                    // An error scores 0. Skipping it would make the eval improve itself.
                    scores.append(0)
                    answers.append("error: \(error)")
                }
            }
            results.append(.init(id: golden.id, input: golden.input, scores: scores, usedAI: usedAI, answers: answers))
        }
        return EvalReport(resolverName: resolverName, cases: results)
    }

    private static func describe(_ interpretation: QuickLogInterpretation) -> String {
        let route: String
        switch interpretation.resolution {
        case .unique(let match): route = "unique \(match.id)"
        case .ambiguous(let routes): route = "ambiguous ×\(routes.count)"
        case .nearMatch(let routes): route = "near ×\(routes.count)"
        case .notFound: route = "notFound"
        }
        return [route, interpretation.result?.rawValue, interpretation.aiNote].compactMap { $0 }.joined(separator: " ")
    }
}
