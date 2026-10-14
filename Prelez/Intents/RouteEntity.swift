import AppIntents
import SwiftData

/// A route as Shortcuts and Siri know it (F6). A lightweight copy of the @Model:
/// the system keeps only the ID and asks the query for the rest.
nonisolated struct RouteEntity: AppEntity {
    let id: String
    let title: String
    let subtitle: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Cesta"
    static let defaultQuery = RouteEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }

    init(_ info: RouteInfo) {
        id = info.id
        title = "\(info.color.czechName) \(info.grade.text)"
        subtitle = [info.sectorName, info.kind.czechName].joined(separator: " · ")
    }
}

/// Where the system finds routes. String matching uses the same rules as the quick log,
/// so "žlutá 6c převis" works in Shortcuts too.
nonisolated struct RouteEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [RouteEntity] {
        try activeRoutes().filter { identifiers.contains($0.id) }.map(RouteEntity.init)
    }

    @MainActor
    func entities(matching string: String) async throws -> [RouteEntity] {
        let routes = try activeRoutes()
        return RuleBasedRouteResolver().interpretNow(string, routes: routes).resolution.candidates.map(RouteEntity.init)
    }

    /// The list Shortcuts shows when the user taps the "Cesta" parameter. Empty store → empty list.
    @MainActor
    func suggestedEntities() async throws -> [RouteEntity] {
        try activeRoutes()
            .sorted { ($0.sectorName, $0.grade.rank) < ($1.sectorName, $1.grade.rank) }
            .map(RouteEntity.init)
    }

    @MainActor
    private func activeRoutes() throws -> [RouteInfo] {
        let context = AppModelContainer.shared.mainContext
        return try context.fetch(FetchDescriptor<Route>(predicate: #Predicate { $0.isActive == true })).map(\.info)
    }
}
