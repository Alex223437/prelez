import Foundation

/// Value snapshot of a route, used by the matcher and the AI.
/// Domain and AI code never touch SwiftData objects directly. That keeps them testable and Sendable.
nonisolated struct RouteInfo: Identifiable, Hashable, Sendable {
    let id: String
    let kind: RouteKind
    let grade: Grade
    let color: HoldColor
    let sectorID: String
    let sectorName: String
    /// Words that name the sector, e.g. ["převis", "overhang"]. Matched by stem.
    let sectorAliases: [String]
    let number: Int?
    let name: String?
    let setter: String?
    let setDate: Date?
    /// Setter notes such as "lišty", "dyno". Used by the AI to tell similar routes apart.
    let tags: [String]

    /// Short Czech description, e.g. "žlutá 6c · Převis".
    var label: String {
        "\(color.czechName) \(grade.text) · \(sectorName)"
    }
}
