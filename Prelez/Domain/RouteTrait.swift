import Foundation

/// Character of a route as setters tag it and climbers describe it: "ta se skokem", "lištovitá", "dlouhá".
///
/// Why a fixed glossary and not the AI: the on-device model does not support Czech
/// (`SystemLanguageModel.default.supportsLocale(cs_CZ) == false`). The eval caught it:
/// Czech notes ended with `unsupportedLanguageOrLocale` or a wrong guess. See docs/AGENT-BUGS.md #1.
nonisolated enum RouteTrait: String, CaseIterable, Sendable {
    case dyno, crimps, slopers, long, overhanging, technical, powerful, coordination

    /// English name used when route tags are described to the model (it understands English, not Czech).
    var english: String {
        switch self {
        case .dyno: "dyno (big jump)"
        case .crimps: "crimps (small edges)"
        case .slopers: "slopers (round holds)"
        case .long: "long"
        case .overhanging: "overhanging"
        case .technical: "technical"
        case .powerful: "powerful"
        case .coordination: "coordination"
        }
    }

    /// Folded word beginnings that name the trait in Czech. Explicit forms where a short stem
    /// would catch other words ("obl" would also match "oblíbená" = favourite).
    private var czechPrefixes: [String] {
        switch self {
        case .dyno: ["dyno", "dynam", "skok", "skak"]
        case .crimps: ["list"]
        case .slopers: ["oble", "obla", "oblou", "obly", "oblym", "oblin"]
        case .long: ["dlouh"]
        case .overhanging: ["previsl"]
        case .technical: ["technick"]
        case .powerful: ["silov"]
        case .coordination: ["koordin"]
        }
    }

    func isNamed(by foldedWord: String) -> Bool {
        czechPrefixes.contains { foldedWord.hasPrefix($0) }
    }

    /// Traits mentioned in folded tokens of a note.
    static func mentioned(in tokens: [String]) -> Set<RouteTrait> {
        Set(allCases.filter { trait in tokens.contains { trait.isNamed(by: $0) } })
    }

    /// Traits of a route, read from the setters' tags.
    static func of(tags: [String]) -> Set<RouteTrait> {
        mentioned(in: tags.flatMap(TextFolding.tokens))
    }
}
