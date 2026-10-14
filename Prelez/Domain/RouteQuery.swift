import Foundation

/// Structured meaning of a free-text description such as "žlutá 6c v převisu, RP na třetí".
/// Every field is optional: nil means "the text did not say".
nonisolated struct RouteQuery: Equatable, Sendable {
    var colors: Set<HoldColor> = []
    var grades: [GradeMention] = []
    var kind: RouteKind?
    var sectorIDs: Set<String> = []
    var setter: String?
    var number: Int?
    /// Route IDs whose name was mentioned, e.g. "ponorka" → "Žlutá ponorka".
    var namedRouteIDs: Set<String> = []
    /// "ta nová", "nejnovější": prefer the most recently set route.
    var wantsNewest = false
    /// "se skokem", "lištovitá": route character, matched against the setters' tags.
    var traits: Set<RouteTrait> = []

    var result: AttemptResult?
    var style: AscentStyle?
    /// "na třetí" = 3.
    var attemptNumber: Int?

    /// True when the text says anything that can narrow down a route.
    var hasRouteSignal: Bool {
        !colors.isEmpty || !grades.isEmpty || kind != nil || !sectorIDs.isEmpty
            || setter != nil || number != nil || !namedRouteIDs.isEmpty || wantsNewest || !traits.isEmpty
    }

    /// True when only route character was said ("ta se skokem"), nothing that filters strictly.
    var traitsAreTheOnlySignal: Bool {
        var withoutTraits = self
        withoutTraits.traits = []
        return !traits.isEmpty && !withoutTraits.hasRouteSignal
    }

    /// Fills the fields this query left empty with values from `other`.
    /// Rules run first, so a value they found always wins over an AI hint.
    func filling(from other: RouteQuery) -> RouteQuery {
        var merged = self
        if merged.colors.isEmpty { merged.colors = other.colors }
        if merged.grades.isEmpty { merged.grades = other.grades }
        if merged.kind == nil { merged.kind = other.kind }
        if merged.sectorIDs.isEmpty { merged.sectorIDs = other.sectorIDs }
        if merged.setter == nil { merged.setter = other.setter }
        if merged.number == nil { merged.number = other.number }
        if merged.namedRouteIDs.isEmpty { merged.namedRouteIDs = other.namedRouteIDs }
        merged.wantsNewest = merged.wantsNewest || other.wantsNewest
        if merged.traits.isEmpty { merged.traits = other.traits }
        if merged.result == nil { merged.result = other.result }
        if merged.style == nil { merged.style = other.style }
        if merged.attemptNumber == nil { merged.attemptNumber = other.attemptNumber }
        return merged
    }
}
