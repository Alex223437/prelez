import Testing
@testable import Prelez

/// A12: the eval of the quick log. Every case runs 3×; we watch the mean and the worst run.
/// The printed tables go into LAB notes and REVIEW.md.
@Suite("Eval rychlého zápisu (F4, A12)", .serialized)
struct RouteResolverEvalTests {
    let routes: [RouteInfo]

    init() throws {
        routes = try TestSupport.sampleRoutes()
    }

    @Test("Baseline: jen pravidla")
    func rulesBaseline() async {
        let report = await EvalRunner(resolver: RuleBasedRouteResolver(), resolverName: "pravidla", routes: routes)
            .run(GoldenSet.cases, runs: 1)
        print(report.table)
        #expect(report.mean >= 0.6)
    }

    @Test(
        "Hybrid: pravidla + Foundation Models na zařízení",
        .enabled(if: AIAvailability.isAvailable, "Apple Intelligence není zapnutá nebo model není stažený")
    )
    func hybrid() async {
        let report = await EvalRunner(resolver: HybridRouteResolver(), resolverName: "hybrid", routes: routes)
            .run(GoldenSet.cases, runs: 3)
        print(report.table)
        #expect(report.passes, "Průměr \(report.mean) je pod prahem \(EvalScoring.threshold)")
    }

    @Test("Eval umí selhat: hloupý resolver musí propadnout")
    func dumbResolverFails() async {
        let report = await EvalRunner(resolver: DumbRouteResolver(), resolverName: "hloupý", routes: routes)
            .run(GoldenSet.cases, runs: 1)
        print(report.table)
        #expect(!report.passes)
        #expect(report.mean < 0.3)
    }

    @Test("Golden set má aspoň 12 případů a unikátní ID")
    func goldenSetShape() {
        #expect(GoldenSet.cases.count >= 12)
        #expect(Set(GoldenSet.cases.map(\.id)).count == GoldenSet.cases.count)
    }
}
