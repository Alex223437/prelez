import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// F1: active routes grouped by sector, with a rope/boulder filter and snapshot import (F7).
struct RoutesView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Route> { $0.isActive == true }) private var routes: [Route]
    @Query(sort: \Sector.sortOrder) private var sectors: [Sector]

    @State private var kindFilter: RouteKind?
    @State private var isImporting = false
    @State private var importMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if routes.isEmpty {
                    ContentUnavailableView {
                        Label("Zatím žádné cesty", systemImage: "mountain.2")
                    } description: {
                        Text("Importuj snapshot cest od stavěčů (JSON).")
                    } actions: {
                        Button("Importovat cesty") { isImporting = true }
                            .buttonStyle(.glassProminent)
                        #if DEBUG
                        Button("Načíst ukázková data", action: importSample)
                        #endif
                    }
                } else {
                    List {
                        ForEach(sectors) { sector in
                            let sectorRoutes = routesIn(sector)
                            if !sectorRoutes.isEmpty {
                                Section(sector.name) {
                                    ForEach(sectorRoutes) { route in
                                        NavigationLink(value: route) {
                                            RouteRow(route: route)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cesty")
            .navigationDestination(for: Route.self) { route in
                RouteDetailView(route: route)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Druh", selection: $kindFilter) {
                        Text("Vše").tag(RouteKind?.none)
                        Text("Lano").tag(Optional(RouteKind.route))
                        Text("Bouldery").tag(Optional(RouteKind.boulder))
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Importovat", systemImage: "square.and.arrow.down") { isImporting = true }
                }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
                importFile(result)
            }
            .alert("Import", isPresented: Binding(get: { importMessage != nil }, set: { if !$0 { importMessage = nil } })) {
            } message: {
                Text(importMessage ?? "")
            }
        }
    }

    private func routesIn(_ sector: Sector) -> [Route] {
        routes
            .filter { $0.sector?.externalID == sector.externalID }
            .filter { kindFilter == nil || $0.kind == kindFilter }
            // Rope routes before boulders, then from easy to hard.
            .sorted { ($0.kind == .boulder ? 1 : 0, $0.grade.rank, $0.externalID) < ($1.kind == .boulder ? 1 : 0, $1.grade.rank, $1.externalID) }
    }

    private func importFile(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            // The picked file lives outside the sandbox: ask for access first.
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
            let snapshot = try RoutesSnapshot.decode(from: Data(contentsOf: url))
            show(try SnapshotImporter(context: context).importSnapshot(snapshot))
        } catch {
            importMessage = "Soubor se nepodařilo načíst: \(error.localizedDescription)"
        }
    }

    #if DEBUG
    private func importSample() {
        do {
            show(try SnapshotImporter(context: context).importBundledSample())
        } catch {
            importMessage = "Ukázková data se nepodařilo načíst: \(error.localizedDescription)"
        }
    }
    #endif

    private func show(_ report: SnapshotImporter.Report) {
        var lines = ["Nové: \(report.added)", "Aktualizované: \(report.updated)", "Archivované: \(report.archived)"]
        if !report.skipped.isEmpty {
            lines.append("Přeskočené (neznámá data): \(report.skipped.joined(separator: ", "))")
        }
        importMessage = lines.joined(separator: "\n")
    }
}
