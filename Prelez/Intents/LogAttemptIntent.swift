import AppIntents
import SwiftData

/// Send or fall, as a value Shortcuts can offer.
nonisolated enum AttemptResultValue: String, AppEnum {
    case send
    case fall

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Výsledek"
    static let caseDisplayRepresentations: [AttemptResultValue: DisplayRepresentation] = [
        .send: "Přelez",
        .fall: "Pád",
    ]

    var domainValue: AttemptResult {
        switch self {
        case .send: .send
        case .fall: .fall
        }
    }
}

/// F6, A8: logs an attempt from Shortcuts, Siri or the Action button without opening the app.
struct LogAttemptIntent: AppIntent {
    static let title: LocalizedStringResource = "Zapiš pokus"
    static let description = IntentDescription("Zapíše přelez nebo pád na cestě do běžícího tréninku.")
    /// Runs in the background, the app does not open (replaces the deprecated openAppWhenRun = false).
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Cesta", requestValueDialog: "Na které cestě?")
    var route: RouteEntity

    @Parameter(title: "Výsledek", default: .send)
    var result: AttemptResultValue

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // The same container as the app, otherwise the app would never see this write.
        let logger = AttemptLogger(context: AppModelContainer.shared.mainContext)
        guard let stored = try logger.route(withID: route.id) else {
            return .result(dialog: "Tuhle cestu jsem nenašel. Je naimportovaná?")
        }
        // `try`, not `try?`: a failed save must reach the user, not disappear.
        let attempt = try logger.log(result.domainValue, on: stored)
        let style = attempt.style.map { " (\($0.shortName))" } ?? ""
        return .result(dialog: "Zapsáno: \(attempt.result.czechName)\(style) – \(route.title).")
    }
}
