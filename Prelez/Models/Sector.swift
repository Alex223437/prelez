import Foundation
import SwiftData

/// A wall area of the gym, e.g. "Převis" (overhang).
@Model
final class Sector {
    /// Stable ID from the setters' snapshot, e.g. "previs".
    @Attribute(.unique) var externalID: String
    var name: String
    /// Other words climbers use for the sector, e.g. ["převis", "overhang"].
    var aliases: [String] = []
    var sortOrder: Int = 0

    @Relationship(deleteRule: .nullify, inverse: \Route.sector)
    var routes: [Route] = []

    init(externalID: String, name: String, aliases: [String] = [], sortOrder: Int = 0) {
        self.externalID = externalID
        self.name = name
        self.aliases = aliases
        self.sortOrder = sortOrder
    }
}
