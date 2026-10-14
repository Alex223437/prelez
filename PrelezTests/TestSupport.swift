import Foundation
import SwiftData
import Testing
@testable import Prelez

/// Shared helpers: an in-memory store filled with the bundled SAMPLE snapshot.
enum TestSupport {
    static func sampleContainer() throws -> ModelContainer {
        let container = try AppModelContainer.inMemory()
        _ = try SnapshotImporter(context: container.mainContext).importBundledSample()
        return container
    }

    static func sampleRoutes() throws -> [RouteInfo] {
        let container = try sampleContainer()
        // Sorted, so results that depend on order (DumbRouteResolver takes the first route) are reproducible.
        return try container.mainContext.fetch(FetchDescriptor<Route>(sortBy: [SortDescriptor(\.externalID)])).map(\.info)
    }

    /// The bundled sample snapshot with some routes removed, as if the setters reset them.
    static func sampleSnapshot(removingRouteIDs removed: Set<String>) throws -> RoutesSnapshot {
        let url = try #require(Bundle.main.url(forResource: "routes-sample", withExtension: "json"))
        var json = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let routes = try #require(json["routes"] as? [[String: Any]])
        json["routes"] = routes.filter { !removed.contains($0["id"] as? String ?? "") }
        return try RoutesSnapshot.decode(from: JSONSerialization.data(withJSONObject: json))
    }
}
