import Foundation
import SwiftData

/// Writes a routes snapshot into SwiftData (F1, F7).
/// New routes are added, existing ones updated by ID, and routes missing from the snapshot
/// are archived (`isActive = false`). Nothing is ever deleted, so attempt history survives a reset (A9).
struct SnapshotImporter {
    struct Report: Equatable {
        var added = 0
        var updated = 0
        var archived = 0
        /// IDs of entries that could not be read (unknown color, kind or grade).
        var skipped: [String] = []
    }

    let context: ModelContext

    func importSnapshot(_ snapshot: RoutesSnapshot) throws -> Report {
        var report = Report()

        let existingSectors = try context.fetch(FetchDescriptor<Sector>())
        var sectorsByID = Dictionary(existingSectors.map { ($0.externalID, $0) }, uniquingKeysWith: { first, _ in first })
        for (index, entry) in snapshot.sectors.enumerated() {
            if let sector = sectorsByID[entry.id] {
                sector.name = entry.name
                sector.aliases = entry.aliases
                sector.sortOrder = index
            } else {
                let sector = Sector(externalID: entry.id, name: entry.name, aliases: entry.aliases, sortOrder: index)
                context.insert(sector)
                sectorsByID[entry.id] = sector
            }
        }

        let existingRoutes = try context.fetch(FetchDescriptor<Route>())
        let routesByID = Dictionary(existingRoutes.map { ($0.externalID, $0) }, uniquingKeysWith: { first, _ in first })
        var seenIDs: Set<String> = []

        for entry in snapshot.routes {
            guard let kind = RouteKind(rawValue: entry.kind),
                  let color = HoldColor(rawValue: entry.color),
                  let parsed = Grade(entry.grade, systemWithoutLetter: kind.gradeSystem)
            else {
                report.skipped.append(entry.id)
                continue
            }
            // The kind decides the grading system, not the letter case in the file:
            // a boulder is always Font (6B), a rope route always French (6b).
            let grade = Grade(system: kind.gradeSystem, number: parsed.number, letter: parsed.letter, plus: parsed.plus)
            let sector = sectorsByID[entry.sector]
            seenIDs.insert(entry.id)

            if let route = routesByID[entry.id] {
                route.kindRaw = kind.rawValue
                route.gradeText = grade.text
                route.colorRaw = color.rawValue
                route.sector = sector
                route.number = entry.number
                route.name = entry.name
                route.setter = entry.setter
                route.setDate = RoutesSnapshot.parseDay(entry.setDate)
                route.tags = entry.tags ?? []
                route.isActive = true
                report.updated += 1
            } else {
                let route = Route(
                    externalID: entry.id,
                    kind: kind,
                    grade: grade,
                    color: color,
                    sector: sector,
                    number: entry.number,
                    name: entry.name,
                    setter: entry.setter,
                    setDate: RoutesSnapshot.parseDay(entry.setDate),
                    tags: entry.tags ?? []
                )
                context.insert(route)
                report.added += 1
            }
        }

        for route in existingRoutes where route.isActive && !seenIDs.contains(route.externalID) {
            route.isActive = false
            report.archived += 1
        }

        try context.save()
        return report
    }

    /// Imports the SAMPLE snapshot bundled with the app (until the setters' export arrives).
    func importBundledSample() throws -> Report {
        guard let url = Bundle.main.url(forResource: "routes-sample", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try importSnapshot(RoutesSnapshot.decode(from: Data(contentsOf: url)))
    }
}
