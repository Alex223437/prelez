import Foundation
import SwiftData
import Testing
@testable import Prelez

@Suite("Import snapshotu (F1, F7)")
struct SnapshotImporterTests {
    @Test("A1: import ukázkových dat")
    func importsSample() throws {
        let container = try AppModelContainer.inMemory()
        let report = try SnapshotImporter(context: container.mainContext).importBundledSample()
        #expect(report.added == 24)
        #expect(report.skipped.isEmpty)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<Sector>()) == 6)
    }

    @Test("Opakovaný import nic nezdvojí")
    func reimportUpdates() throws {
        let container = try TestSupport.sampleContainer()
        let report = try SnapshotImporter(context: container.mainContext).importBundledSample()
        #expect(report == SnapshotImporter.Report(added: 0, updated: 24, archived: 0))
        #expect(try container.mainContext.fetchCount(FetchDescriptor<Route>()) == 24)
    }

    @Test("A9: po přestavbě se cesta archivuje a pokusy na ní zůstanou")
    func resetKeepsHistory() throws {
        let container = try TestSupport.sampleContainer()
        let context = container.mainContext
        let logger = AttemptLogger(context: context)
        let route = try #require(try logger.route(withID: "R-01"))
        try logger.log(.fall, on: route)
        try logger.log(.send, on: route)

        let report = try SnapshotImporter(context: context)
            .importSnapshot(TestSupport.sampleSnapshot(removingRouteIDs: ["R-01"]))

        #expect(report.archived == 1)
        let archived = try #require(try logger.route(withID: "R-01"))
        #expect(archived.isActive == false)
        #expect(archived.attempts.count == 2)
        #expect(try context.fetchCount(FetchDescriptor<Attempt>()) == 2)
    }

    @Test("Druh cesty určuje stupnici, ne velikost písmen v souboru")
    func kindDecidesGradeSystem() throws {
        let json = """
            {"gym": "Test", "capturedAt": "2026-10-14", "sectors": [{"id": "s", "name": "S"}],
             "routes": [{"id": "B", "kind": "boulder", "grade": "6b", "color": "red", "sector": "s"},
                        {"id": "R", "kind": "route", "grade": "6B", "color": "red", "sector": "s"}]}
            """
        let container = try AppModelContainer.inMemory()
        _ = try SnapshotImporter(context: container.mainContext)
            .importSnapshot(RoutesSnapshot.decode(from: Data(json.utf8)))
        let logger = AttemptLogger(context: container.mainContext)
        #expect(try logger.route(withID: "B")?.gradeText == "6B")
        #expect(try logger.route(withID: "R")?.gradeText == "6b")
    }
}

@Suite("Zápis pokusů (F2, F3)")
struct AttemptLoggerTests {
    @Test("Pokus mimo trénink trénink založí, další pokus ho použije")
    func sessionStartsAutomatically() throws {
        let container = try TestSupport.sampleContainer()
        let logger = AttemptLogger(context: container.mainContext)
        let route = try #require(try logger.route(withID: "R-05"))
        let first = try logger.log(.fall, on: route)
        let second = try logger.log(.send, on: route)
        #expect(first.session != nil)
        #expect(first.session === second.session)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<ClimbSession>()) == 1)
    }

    @Test("Styl: první pokus = flash, po pádu = RP, pád nemá styl")
    func inferredStyle() throws {
        let container = try TestSupport.sampleContainer()
        let logger = AttemptLogger(context: container.mainContext)
        let flashRoute = try #require(try logger.route(withID: "R-08"))
        #expect(try logger.log(.send, on: flashRoute).style == .flash)

        let projectRoute = try #require(try logger.route(withID: "R-07"))
        #expect(try logger.log(.fall, style: .flash, on: projectRoute).style == nil)
        #expect(try logger.log(.send, on: projectRoute).style == .redpoint)
        #expect(try logger.log(.send, style: .topRope, on: projectRoute).style == .topRope)
    }

    @Test("A10: pyramida 3-2-1 ve správném pořadí")
    func pyramid() throws {
        let container = try TestSupport.sampleContainer()
        let logger = AttemptLogger(context: container.mainContext)
        let r6a = try #require(try logger.route(withID: "R-09"))
        let r6b = try #require(try logger.route(withID: "R-05"))
        let r6c = try #require(try logger.route(withID: "R-01"))
        for _ in 0..<3 { try logger.log(.send, on: r6a) }
        for _ in 0..<2 { try logger.log(.send, on: r6b) }
        try logger.log(.send, on: r6c)
        try logger.log(.fall, on: r6c)

        let attempts = try container.mainContext.fetch(FetchDescriptor<Attempt>())
        let pyramid = StatsView.pyramid(of: attempts, kind: .route)
        #expect(pyramid.map(\.grade) == ["6c", "6b", "6a"])
        #expect(pyramid.map(\.count) == [1, 2, 3])
    }
}
