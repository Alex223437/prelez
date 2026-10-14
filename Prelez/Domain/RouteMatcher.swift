import Foundation

/// What a description resolved to.
nonisolated enum RouteResolution: Equatable, Sendable {
    /// Exactly one route fits. The UI may offer it for one-tap confirmation.
    case unique(RouteInfo)
    /// Several routes fit. The user has to pick, never auto-save.
    case ambiguous([RouteInfo])
    /// Nothing fits exactly, but these are close (e.g. "6c" typed for the 6C boulder).
    /// Offered for picking, never auto-selected, and the AI never narrows them down.
    case nearMatch([RouteInfo])
    /// Nothing fits. Never invent a route.
    case notFound

    var candidates: [RouteInfo] {
        switch self {
        case .unique(let route): [route]
        case .ambiguous(let routes), .nearMatch(let routes): routes
        case .notFound: []
        }
    }
}

/// Filters routes by a structured query. Pure and deterministic.
nonisolated struct RouteMatcher {
    func match(_ query: RouteQuery, in routes: [RouteInfo]) -> RouteResolution {
        guard query.hasRouteSignal else { return .notFound }

        var candidates = filter(routes, by: query, strictGrades: true)

        // Someone typed "6c" for the 6C boulder (or the other way round).
        // Grades stay case-sensitive, but a near match is offered for picking, never auto-selected.
        if candidates.isEmpty, query.grades.contains(where: \.isExact) {
            let relaxed = filter(routes, by: query, strictGrades: false)
            return relaxed.isEmpty ? .notFound : .nearMatch(sorted(relaxed))
        }

        // Traits narrow the candidates only when some candidate has them.
        // "ta se skokem na plotně" with no dyno on the slab stays a choice, it does not become "not found".
        if !query.traits.isEmpty {
            let withTraits = candidates.filter { query.traits.isSubset(of: RouteTrait.of(tags: $0.tags)) }
            if !withTraits.isEmpty {
                candidates = withTraits
            } else if query.traitsAreTheOnlySignal {
                // "ta silová" and no route is tagged so: nothing fits, do not offer the whole gym.
                return .notFound
            }
        }

        if query.wantsNewest, let newestDate = candidates.compactMap(\.setDate).max() {
            candidates = candidates.filter { $0.setDate == newestDate }
        }

        switch candidates.count {
        case 0: return .notFound
        case 1: return .unique(candidates[0])
        default: return .ambiguous(sorted(candidates))
        }
    }

    private func filter(_ routes: [RouteInfo], by query: RouteQuery, strictGrades: Bool) -> [RouteInfo] {
        routes.filter { route in
            if let kind = query.kind, route.kind != kind { return false }
            if !query.colors.isEmpty, !query.colors.contains(route.color) { return false }
            if !query.grades.isEmpty,
               !query.grades.contains(where: { matches($0, route.grade, strict: strictGrades) }) {
                return false
            }
            if !query.sectorIDs.isEmpty, !query.sectorIDs.contains(route.sectorID) { return false }
            if let setter = query.setter,
               TextFolding.fold(route.setter ?? "") != TextFolding.fold(setter) {
                return false
            }
            if let number = query.number, route.number != number { return false }
            if !query.namedRouteIDs.isEmpty, !query.namedRouteIDs.contains(route.id) { return false }
            return true
        }
    }

    private func matches(_ mention: GradeMention, _ grade: Grade, strict: Bool) -> Bool {
        switch mention {
        case .exact(let wanted):
            // strict: 6b ≠ 6B. Relaxed: same position on the scale, either system.
            strict ? wanted == grade : wanted.rank == grade.rank
        case .band(let number):
            grade.number == number
        }
    }

    private func sorted(_ routes: [RouteInfo]) -> [RouteInfo] {
        routes.sorted { ($0.sectorName, $0.grade.rank, $0.id) < ($1.sectorName, $1.grade.rank, $1.id) }
    }
}

nonisolated extension GradeMention {
    var isExact: Bool {
        if case .exact = self { true } else { false }
    }
}
