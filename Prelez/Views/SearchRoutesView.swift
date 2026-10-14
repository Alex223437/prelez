import SwiftData
import SwiftUI

/// Search tab: understands the same notes as the quick log ("žlutá 6c převis"), using rules only.
struct SearchRoutesView: View {
    @Query(filter: #Predicate<Route> { $0.isActive == true }) private var routes: [Route]
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List(results) { route in
                NavigationLink(value: route) {
                    RouteRow(route: route)
                }
            }
            .overlay {
                if !searchText.isEmpty, results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle("Hledat")
            .navigationDestination(for: Route.self) { route in
                RouteDetailView(route: route)
            }
            .searchable(text: $searchText, prompt: "žlutá 6c převis, Pepa, lajna 12…")
        }
    }

    private var results: [Route] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let infos = routes.map(\.info)
        let ids = Set(RuleBasedRouteResolver().interpretNow(trimmed, routes: infos).resolution.candidates.map(\.id))
        return routes
            .filter { ids.contains($0.externalID) }
            .sorted { $0.grade.rank < $1.grade.rank }
    }
}
