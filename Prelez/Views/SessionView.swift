import SwiftData
import SwiftUI

/// F3: the running session, its attempts and past sessions. The quick log (F4) floats at the bottom.
struct SessionView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<ClimbSession> { $0.endedAt == nil }, sort: \ClimbSession.startedAt, order: .reverse)
    private var running: [ClimbSession]
    @Query(filter: #Predicate<ClimbSession> { $0.endedAt != nil }, sort: \ClimbSession.startedAt, order: .reverse)
    private var finished: [ClimbSession]
    @Query(filter: #Predicate<Route> { $0.isActive == true })
    private var activeRoutes: [Route]

    @State private var quickLog = QuickLogModel()
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if let session = running.first {
                    Section {
                        SessionSummary(session: session)
                    }
                    Section("Pokusy") {
                        if session.attempts.isEmpty {
                            Text("Zatím nic. Ťukni na ✨ a napiš třeba „žlutá 6c v převisu, RP“.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(session.attempts.sorted { $0.date > $1.date }) { attempt in
                            AttemptRow(attempt: attempt, showsRoute: true)
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Žádný trénink", systemImage: "figure.climbing")
                    } description: {
                        Text("Začni trénink, nebo rovnou zapiš pokus – trénink se založí sám.")
                    } actions: {
                        Button("Začít trénink", action: startSession)
                            .buttonStyle(.glassProminent)
                    }
                }

                if !finished.isEmpty {
                    Section("Historie") {
                        ForEach(finished) { session in
                            HStack {
                                Text(session.startedAt, format: .dateTime.day().month().hour().minute())
                                Spacer()
                                Text("\(session.sendCount)/\(session.attempts.count)")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Trénink")
            .toolbar {
                if let session = running.first {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Ukončit", systemImage: "stop.fill") { end(session) }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                QuickLogBar(model: quickLog) {
                    Task { await quickLog.resolve(routes: activeRoutes.map(\.info)) }
                }
            }
            .sheet(isPresented: Binding(get: { quickLog.interpretation != nil }, set: { if !$0 { quickLog.interpretation = nil } })) {
                if let interpretation = quickLog.interpretation {
                    QuickLogResultView(interpretation: interpretation, note: quickLog.text) {
                        quickLog.reset()
                    }
                }
            }
            .alert("Chyba", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func startSession() {
        do { try AttemptLogger(context: context).startSession() } catch { errorMessage = error.localizedDescription }
    }

    private func end(_ session: ClimbSession) {
        do { try AttemptLogger(context: context).endSession(session) } catch { errorMessage = error.localizedDescription }
    }
}

/// Time, attempts and sends of the running session.
private struct SessionSummary: View {
    let session: ClimbSession

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Probíhá trénink")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(session.startedAt, style: .timer)
                    .font(.largeTitle.monospacedDigit().weight(.semibold))
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(session.sendCount) přelezů")
                Text("\(session.attempts.count) pokusů")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// One attempt: result, style, route, time.
struct AttemptRow: View {
    let attempt: Attempt
    var showsRoute = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: attempt.result == .send ? "checkmark.circle.fill" : "arrow.down.circle")
                .foregroundStyle(attempt.result == .send ? Color.green : Color.secondary)
            if showsRoute, let route = attempt.route {
                HoldSwatch(color: route.color, size: 16)
                Text("\(route.color.czechName) \(route.grade.text)")
            } else {
                Text(attempt.result.czechName.capitalized)
            }
            if let style = attempt.style {
                Text(style.shortName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(attempt.date, format: .dateTime.hour().minute())
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
