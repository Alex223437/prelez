import Charts
import SwiftData
import SwiftUI

/// F5: grade pyramid of sends and attempts per week.
struct StatsView: View {
    @Query(sort: \Attempt.date) private var attempts: [Attempt]
    @State private var kind: RouteKind = .route

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Druh", selection: $kind) {
                        Text("Lano").tag(RouteKind.route)
                        Text("Bouldery").tag(RouteKind.boulder)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Pyramida přelezů") {
                    let pyramid = Self.pyramid(of: attempts, kind: kind)
                    if pyramid.isEmpty {
                        Text("Zatím žádné přelezy.")
                            .foregroundStyle(.secondary)
                    } else {
                        Chart(pyramid) { level in
                            BarMark(
                                x: .value("Přelezy", level.count),
                                y: .value("Obtížnost", level.grade)
                            )
                            .foregroundStyle(.tint)
                            .annotation(position: .trailing) {
                                Text("\(level.count)")
                                    .font(.caption.monospacedDigit())
                            }
                        }
                        // Hardest grade on top.
                        .chartYScale(domain: pyramid.map(\.grade))
                        .frame(height: CGFloat(pyramid.count) * 36 + 24)
                    }
                }

                Section("Týdny") {
                    let weeks = Self.weeks(of: attempts)
                    if weeks.isEmpty {
                        Text("Zatím žádné pokusy.")
                            .foregroundStyle(.secondary)
                    } else {
                        Chart(weeks) { week in
                            BarMark(
                                x: .value("Týden", week.weekStart, unit: .weekOfYear),
                                y: .value("Pokusy", week.count)
                            )
                            .foregroundStyle(by: .value("Výsledek", week.result.czechName))
                        }
                        // Sends green like the checkmarks in the lists, falls grey.
                        .chartForegroundStyleScale([
                            AttemptResult.send.czechName: Color.green,
                            AttemptResult.fall.czechName: Color.gray.opacity(0.5),
                        ])
                        .frame(height: 200)
                    }
                }
            }
            .navigationTitle("Statistiky")
        }
    }

    struct PyramidLevel: Identifiable {
        let grade: String
        let rank: Int
        let count: Int
        var id: String { grade }
    }

    /// Sends per grade, hardest first (A10). Archived routes count too: history stays after a reset (A9).
    static func pyramid(of attempts: [Attempt], kind: RouteKind) -> [PyramidLevel] {
        var counts: [String: (rank: Int, count: Int)] = [:]
        for attempt in attempts where attempt.result == .send {
            guard let route = attempt.route, route.kind == kind else { continue }
            let grade = route.grade
            counts[grade.text, default: (grade.rank, 0)].count += 1
        }
        return counts
            .map { PyramidLevel(grade: $0.key, rank: $0.value.rank, count: $0.value.count) }
            .sorted { $0.rank > $1.rank }
    }

    struct WeekBar: Identifiable {
        let weekStart: Date
        let result: AttemptResult
        let count: Int
        var id: String { "\(weekStart.timeIntervalSince1970)-\(result.rawValue)" }
    }

    static func weeks(of attempts: [Attempt]) -> [WeekBar] {
        let calendar = Calendar(identifier: .iso8601)
        var counts: [Date: [AttemptResult: Int]] = [:]
        for attempt in attempts {
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: attempt.date)?.start else { continue }
            counts[weekStart, default: [:]][attempt.result, default: 0] += 1
        }
        return counts.flatMap { weekStart, byResult in
            byResult.map { WeekBar(weekStart: weekStart, result: $0.key, count: $0.value) }
        }
        .sorted { $0.weekStart < $1.weekStart }
    }
}
