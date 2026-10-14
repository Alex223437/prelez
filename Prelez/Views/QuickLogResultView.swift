import SwiftData
import SwiftUI

/// Confirmation of the quick log (F4). Nothing is saved without the user's tap:
/// a unique match is pre-selected, ambiguous texts and near matches need a pick,
/// and "not found" never invents a route (A3–A6).
struct QuickLogResultView: View {
    let interpretation: QuickLogInterpretation
    let note: String
    let onSaved: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRouteID: String?
    @State private var result: AttemptResult = .send
    @State private var style: AscentStyle?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("„\(note)“")
                        .italic()
                    if interpretation.usedAI {
                        Label("Pomohla AI na zařízení", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let aiNote = interpretation.aiNote {
                        Label(aiNote, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                routeSection

                if selectedRouteID != nil {
                    Section("Výsledek") {
                        Picker("Výsledek", selection: $result) {
                            ForEach(AttemptResult.allCases, id: \.self) { Text($0.czechName.capitalized).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        if result == .send {
                            Picker("Styl", selection: $style) {
                                Text("Automaticky").tag(AscentStyle?.none)
                                ForEach(AscentStyle.allCases, id: \.self) { Text($0.shortName).tag(Optional($0)) }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Rychlý zápis")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušit", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uložit", action: save)
                        .disabled(selectedRouteID == nil)
                }
            }
            .alert("Nepodařilo se uložit", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear(perform: prefill)
    }

    @ViewBuilder
    private var routeSection: some View {
        switch interpretation.resolution {
        case .unique(let route):
            Section("Cesta") {
                candidateRow(route)
            }
        case .ambiguous(let routes):
            Section {
                ForEach(routes) { candidateRow($0) }
            } header: {
                Text("Kterou myslíš?")
            } footer: {
                Text("Popisu odpovídá víc cest, vyber jednu.")
            }
        case .nearMatch(let routes):
            Section {
                ForEach(routes) { candidateRow($0) }
            } header: {
                Text("Myslel jsi tuhle?")
            } footer: {
                Text("Přesná shoda není. Pozor na velikost písmen: 6b je cesta na laně, 6B boulder.")
            }
        case .notFound:
            Section {
                ContentUnavailableView(
                    "Nenalezeno",
                    systemImage: "questionmark.circle",
                    description: Text("Žádná aktivní cesta neodpovídá popisu. Nic se neuloží.")
                )
            }
        }
    }

    private func candidateRow(_ route: RouteInfo) -> some View {
        Button {
            selectedRouteID = route.id
        } label: {
            HStack(spacing: 12) {
                HoldSwatch(color: route.color)
                VStack(alignment: .leading) {
                    Text("\(route.color.czechName) \(route.grade.text)")
                        .font(.headline)
                    Text([route.sectorName, route.kind.czechName, route.setter].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if selectedRouteID == route.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func prefill() {
        if case .unique(let route) = interpretation.resolution {
            selectedRouteID = route.id
        }
        result = interpretation.result ?? .send
        style = interpretation.style
    }

    private func save() {
        guard let selectedRouteID else { return }
        do {
            let logger = AttemptLogger(context: context)
            guard let route = try logger.route(withID: selectedRouteID) else {
                errorMessage = "Cesta už v databázi není."
                return
            }
            try logger.log(result, style: style, on: route)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
