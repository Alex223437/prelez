import Foundation

/// Hold colors used to mark routes and boulders at the gym.
nonisolated enum HoldColor: String, CaseIterable, Codable, Sendable {
    case yellow, blue, green, red, black, white, orange, purple, pink, grey, brown, turquoise

    /// Czech name for the UI.
    var czechName: String {
        switch self {
        case .yellow: "žlutá"
        case .blue: "modrá"
        case .green: "zelená"
        case .red: "červená"
        case .black: "černá"
        case .white: "bílá"
        case .orange: "oranžová"
        case .purple: "fialová"
        case .pink: "růžová"
        case .grey: "šedá"
        case .brown: "hnědá"
        case .turquoise: "tyrkysová"
        }
    }

    /// Folded Czech adjective stem (without the ending).
    private var czechStem: String {
        switch self {
        case .yellow: "zlut"
        case .blue: "modr"
        case .green: "zelen"
        case .red: "cerven"
        case .black: "cern"
        case .white: "bil"
        case .orange: "oranzov"
        case .purple: "fialov"
        case .pink: "ruzov"
        case .grey: "sed"
        case .brown: "hned"
        case .turquoise: "tyrkysov"
        }
    }

    private var englishNames: [String] {
        switch self {
        case .grey: ["grey", "gray"]
        case .purple: ["purple", "violet"]
        case .turquoise: ["turquoise", "teal"]
        default: [rawValue]
        }
    }

    /// Adjective endings a Czech climber actually uses: žlutá, žlutou, žluté, žlutý, žlutej…
    private static let czechEndings = ["a", "ou", "e", "y", "ej", "eho", "emu", "ym", "ych", "ymi"]

    /// Every whole word that names this color. Whole words only, so "sedmička" (7) never
    /// counts as "šedá" (grey) even though both start with "sed" after folding.
    var wordForms: Set<String> {
        var forms = Set(englishNames)
        for ending in Self.czechEndings {
            forms.insert(czechStem + ending)
        }
        return forms
    }

    /// Finds all colors mentioned in already folded tokens.
    static func mentioned(in tokens: [String]) -> Set<HoldColor> {
        let words = Set(tokens)
        return Set(allCases.filter { !$0.wordForms.isDisjoint(with: words) })
    }
}
