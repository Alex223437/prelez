import Foundation
import SwiftData

/// A rope route or boulder at the gym, imported from the setters' snapshot (F1, F7).
@Model
final class Route {
    /// Stable ID from the snapshot. Re-import matches routes by this ID.
    @Attribute(.unique) var externalID: String
    /// Enums are stored as raw strings, the typed accessors are below.
    var kindRaw: String
    var gradeText: String
    var colorRaw: String
    var number: Int?
    var name: String?
    var setter: String?
    var setDate: Date?
    var tags: [String] = []
    /// False after a reset (přestavba): the route is gone from the wall,
    /// but it is kept so the attempt history stays (A9).
    var isActive: Bool = true

    var sector: Sector?

    /// Nullify, not cascade: attempts are the climber's history and must survive the route.
    @Relationship(deleteRule: .nullify, inverse: \Attempt.route)
    var attempts: [Attempt] = []

    init(
        externalID: String,
        kind: RouteKind,
        grade: Grade,
        color: HoldColor,
        sector: Sector?,
        number: Int? = nil,
        name: String? = nil,
        setter: String? = nil,
        setDate: Date? = nil,
        tags: [String] = []
    ) {
        self.externalID = externalID
        self.kindRaw = kind.rawValue
        self.gradeText = grade.text
        self.colorRaw = color.rawValue
        self.sector = sector
        self.number = number
        self.name = name
        self.setter = setter
        self.setDate = setDate
        self.tags = tags
    }

    var kind: RouteKind { RouteKind(rawValue: kindRaw) ?? .route }
    var color: HoldColor { HoldColor(rawValue: colorRaw) ?? .grey }
    /// Stored text is always canonical ("6c+" or "6C+"), so parsing it cannot fail
    /// for data written by the importer. The fallback only protects against a corrupted store.
    var grade: Grade { Grade(gradeText, systemWithoutLetter: kind.gradeSystem) ?? Grade("3")! }

    /// Value snapshot for the matcher and the AI.
    var info: RouteInfo {
        RouteInfo(
            id: externalID,
            kind: kind,
            grade: grade,
            color: color,
            sectorID: sector?.externalID ?? "",
            sectorName: sector?.name ?? "",
            sectorAliases: sector?.aliases ?? [],
            number: number,
            name: name,
            setter: setter,
            setDate: setDate,
            tags: tags
        )
    }
}
