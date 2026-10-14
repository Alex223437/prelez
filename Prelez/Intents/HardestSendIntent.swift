import AppIntents
import SwiftData

/// F6: "What is my hardest send?" answered with a dialog.
struct HardestSendIntent: AppIntent {
    static let title: LocalizedStringResource = "Můj nejtěžší přelez"
    static let description = IntentDescription("Řekne nejtěžší přelezenou cestu a boulder.")
    static let supportedModes: IntentModes = .background

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = AppModelContainer.shared.mainContext
        let sends = try context.fetch(FetchDescriptor<Attempt>(predicate: #Predicate { $0.resultRaw == "send" }))
        let routes = sends.compactMap(\.route)
        guard !routes.isEmpty else {
            return .result(dialog: "Zatím nemáš žádný přelez.")
        }
        var parts: [String] = []
        for kind in RouteKind.allCases {
            if let hardest = routes.filter({ $0.kind == kind }).max(by: { $0.grade.rank < $1.grade.rank }) {
                parts.append("\(kind == .route ? "na laně" : "boulder") \(hardest.grade.text) (\(hardest.color.czechName))")
            }
        }
        return .result(dialog: "Tvůj nejtěžší přelez: \(parts.joined(separator: ", ")).")
    }
}
