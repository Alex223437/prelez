import Foundation
import FoundationModels

/// F4: rules first. The on-device model only translates free text into our fixed vocabulary
/// (color, sector, route character, outcome). It never picks a route: the rules do, so the model
/// cannot invent one.
///
/// What the eval taught us (docs/AGENT-BUGS.md #1, #2):
/// - the on-device model does not support Czech, so Czech notes stay with the rules and the trait glossary;
/// - asked to choose a route among candidates, the model picked routes the note did not describe
///   ("lemon colored" → the orange route). Extracting attributes is reliable, choosing was not.
///
/// Other guard rails:
/// - the model never sees or produces grades (only rules read grades, so 6b ≠ 6B stays intact);
/// - every answer is constrained to a fixed list (constrained decoding), rules win over hints;
/// - near matches ("6c" typed for a 6C boulder) are never narrowed down;
/// - when the model fails, the rules' answer is used and the reason is shown.
struct HybridRouteResolver: RouteResolving {
    var model = SystemLanguageModel.default

    private static let instructions = """
        You help a climbing gym app understand short notes that climbers write after an attempt. \
        Translate the note into the given fixed choices. \
        Be conservative: when the note does not clearly say something, answer none or unknown.
        """

    func interpret(_ text: String, routes: [RouteInfo]) async throws -> QuickLogInterpretation {
        let parser = QueryParser(routes: routes)
        let query = parser.parse(text)
        let rules = QuickLogInterpretation(
            resolution: RouteMatcher().match(query, in: routes),
            result: query.result,
            style: query.style
        )

        // The model is only worth asking when the rules are unsure and left words they could not use.
        let rulesAreUnsure: Bool
        switch rules.resolution {
        case .notFound: rulesAreUnsure = !query.hasRouteSignal
        case .ambiguous: rulesAreUnsure = true
        case .unique, .nearMatch: rulesAreUnsure = false
        }
        guard rulesAreUnsure, !parser.unexplainedWords(in: text).isEmpty, model.isAvailable else {
            return rules
        }

        guard !QueryParser.looksCzech(text) else {
            var answer = rules
            answer.aiNote = "AI na zařízení češtinu nepodporuje, rozhodla pravidla."
            return answer
        }

        do {
            let hints = try await routeHints(for: text, routes: routes)
            let merged = query.filling(from: hints)
            return QuickLogInterpretation(
                resolution: RouteMatcher().match(merged, in: routes),
                result: merged.result,
                style: merged.style,
                usedAI: true
            )
        } catch {
            var answer = rules
            answer.aiNote = "AI selhala (\(Self.reason(for: error))), rozhodla pravidla."
            return answer
        }
    }

    /// Asks for color, sector, route character and outcome, each constrained to a fixed list.
    /// No grades and no route IDs on purpose.
    private func routeHints(for text: String, routes: [RouteInfo]) async throws -> RouteQuery {
        var sectorIDsByName: [String: String] = [:]
        for route in routes { sectorIDsByName[route.sectorName] = route.sectorID }
        let traitsByName = Dictionary(uniqueKeysWithValues: RouteTrait.allCases.map { ($0.english, $0) })

        let root = DynamicGenerationSchema(name: "RouteHints", properties: [
            .init(
                name: "color",
                description: "Hold color the note mentions or clearly implies, otherwise none.",
                schema: DynamicGenerationSchema(name: "Color", anyOf: HoldColor.allCases.map(\.rawValue) + ["none"])
            ),
            .init(
                name: "sector",
                description: "Wall sector the note mentions, otherwise none.",
                schema: DynamicGenerationSchema(name: "Sector", anyOf: sectorIDsByName.keys.sorted() + ["none"])
            ),
            .init(
                name: "character",
                description: "Route character the note describes. Empty when the note says nothing about it.",
                schema: DynamicGenerationSchema(
                    arrayOf: DynamicGenerationSchema(name: "Character", anyOf: traitsByName.keys.sorted()),
                    minimumElements: 0,
                    maximumElements: 3
                )
            ),
            .init(
                name: "outcome",
                description: "send if the climber reached the top, fall if they fell, unknown otherwise.",
                schema: DynamicGenerationSchema(name: "Outcome", anyOf: ["send", "fall", "unknown"])
            ),
        ])
        let response = try await LanguageModelSession(model: model, instructions: Self.instructions).respond(
            to: "Climber's note: \"\(text)\"",
            schema: try GenerationSchema(root: root, dependencies: []),
            includeSchemaInPrompt: true,
            options: GenerationOptions(samplingMode: .greedy)
        )

        var hints = RouteQuery()
        if let color = HoldColor(rawValue: try response.content.value(String.self, forProperty: "color")) {
            hints.colors = [color]
        }
        if let sectorID = sectorIDsByName[try response.content.value(String.self, forProperty: "sector")] {
            hints.sectorIDs = [sectorID]
        }
        let character = try response.content.value([String].self, forProperty: "character")
        hints.traits = Set(character.compactMap { traitsByName[$0] })
        switch try response.content.value(String.self, forProperty: "outcome") {
        case "send": hints.result = .send
        case "fall": hints.result = .fall
        default: break
        }
        return hints
    }

    private static func reason(for error: any Error) -> String {
        if let generationError = error as? LanguageModelSession.GenerationError,
           case .unsupportedLanguageOrLocale = generationError {
            return "nepodporovaný jazyk"
        }
        return error.localizedDescription
    }
}
