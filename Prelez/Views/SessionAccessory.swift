import SwiftData
import SwiftUI

/// iOS tab bar accessory: the running session (time, attempts, sends), or a button to start one.
struct SessionAccessory: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<ClimbSession> { $0.endedAt == nil }, sort: \ClimbSession.startedAt, order: .reverse)
    private var running: [ClimbSession]
    @State private var errorMessage: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.climbing")
                .foregroundStyle(.tint)
            if let session = running.first {
                Text(session.startedAt, style: .timer)
                    .font(.headline.monospacedDigit())
                Spacer()
                Label("\(session.attempts.count)", systemImage: "arrow.up.and.down")
                    .labelStyle(.titleAndIcon)
                    .accessibilityLabel("\(session.attempts.count) pokusů")
                Label("\(session.sendCount)", systemImage: "checkmark")
                    .accessibilityLabel("\(session.sendCount) přelezů")
            } else {
                Text("Žádný trénink")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Začít") { start() }
                    .font(.headline)
            }
        }
        .padding(.horizontal)
        .alert("Chyba", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func start() {
        do {
            try AttemptLogger(context: context).startSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
