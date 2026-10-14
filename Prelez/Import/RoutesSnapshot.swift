import Foundation

/// JSON file with the gym's current routes, provided by the setters (F1, F7).
///
/// ```json
/// {
///   "gym": "Vertikon Zlín",
///   "capturedAt": "2026-10-14",
///   "source": "export od stavěčů",
///   "sectors": [ { "id": "previs", "name": "Převis", "aliases": ["převis", "overhang"] } ],
///   "routes": [ { "id": "R-01", "kind": "route", "grade": "6c", "color": "yellow", "sector": "previs",
///                 "number": 12, "name": "Žlutá ponorka", "setter": "Pepa", "setDate": "2026-09-20",
///                 "tags": ["lišty"] } ]
/// }
/// ```
nonisolated struct RoutesSnapshot: Decodable, Sendable {
    struct SectorEntry: Decodable, Sendable {
        let id: String
        let name: String
        var aliases: [String] = []

        private enum CodingKeys: String, CodingKey { case id, name, aliases }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        }
    }

    struct RouteEntry: Decodable, Sendable {
        let id: String
        /// "route" or "boulder"
        let kind: String
        let grade: String
        /// HoldColor raw value, e.g. "yellow"
        let color: String
        /// Sector id
        let sector: String
        let number: Int?
        let name: String?
        let setter: String?
        /// "yyyy-MM-dd"
        let setDate: String?
        let tags: [String]?
    }

    let gym: String
    let capturedAt: String
    let source: String?
    let sectors: [SectorEntry]
    let routes: [RouteEntry]

    static func decode(from data: Data) throws -> RoutesSnapshot {
        try JSONDecoder().decode(RoutesSnapshot.self, from: data)
    }

    /// Parses the snapshot's "yyyy-MM-dd" dates in Prague time.
    static func parseDay(_ text: String?) -> Date? {
        guard let text else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Prague")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: text)
    }
}
