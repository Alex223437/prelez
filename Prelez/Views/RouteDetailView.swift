import SwiftData
import SwiftUI

/// F2: one route, my attempts on it, and floating glass buttons to log a fall or a send.
struct RouteDetailView: View {
    let route: Route

    @Environment(\.modelContext) private var context
    @State private var lastLoggedAt: Date?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    HoldSwatch(color: route.color, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.grade.text)
                            .font(.largeTitle.weight(.bold).monospacedDigit())
                        Text("\(route.color.czechName) \(route.kind.czechName)")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                if let name = route.name { LabeledContent("Název", value: name) }
                if let sector = route.sector { LabeledContent("Sektor", value: sector.name) }
                if let number = route.number { LabeledContent("Lajna", value: "\(number)") }
                if let setter = route.setter { LabeledContent("Stavěl", value: setter) }
                if let setDate = route.setDate {
                    LabeledContent("Postaveno", value: setDate.formatted(date: .abbreviated, time: .omitted))
                }
                if !route.tags.isEmpty { LabeledContent("Charakter", value: route.tags.joined(separator: ", ")) }
                if !route.isActive {
                    Label("Archiv – cesta už na stěně není", systemImage: "archivebox")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Moje pokusy") {
                if route.attempts.isEmpty {
                    Text("Zatím žádné.")
                        .foregroundStyle(.secondary)
                }
                ForEach(route.attempts.sorted { $0.date > $1.date }) { attempt in
                    AttemptRow(attempt: attempt)
                }
            }
        }
        .navigationTitle("\(route.color.czechName.capitalized) \(route.grade.text)")
        .safeAreaInset(edge: .bottom) {
            if route.isActive {
                logButtons
            }
        }
        .sensoryFeedback(.success, trigger: lastLoggedAt)
        .alert("Nepodařilo se uložit", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
        } message: {
            Text(errorMessage ?? "")
        }
    }

    /// Glass controls floating over the list. Tap "Přelez" for the inferred style, long-press to choose one.
    private var logButtons: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    log(.fall)
                } label: {
                    Label("Pád", systemImage: "arrow.down")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glass)

                Menu {
                    ForEach(AscentStyle.allCases, id: \.self) { style in
                        Button(style.shortName) { log(.send, style: style) }
                    }
                } label: {
                    Label("Přelez", systemImage: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: 44)
                } primaryAction: {
                    log(.send)
                }
                .buttonStyle(.glassProminent)
            }
            .font(.headline)
        }
        .padding()
    }

    private func log(_ result: AttemptResult, style: AscentStyle? = nil) {
        do {
            try AttemptLogger(context: context).log(result, style: style, on: route)
            lastLoggedAt = .now
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
