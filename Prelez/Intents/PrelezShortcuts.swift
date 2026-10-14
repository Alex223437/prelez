import AppIntents

/// Ready-made shortcuts and Siri phrases, available right after install.
/// Every phrase must contain the app name. Siri does not speak Czech, so the English phrases are for Siri
/// and the Czech ones show up in Shortcuts and Spotlight.
nonisolated struct PrelezShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogAttemptIntent(),
            phrases: [
                "Log a climb in \(.applicationName)",
                "Log \(\.$route) in \(.applicationName)",
                "Zapiš pokus v \(.applicationName)",
            ],
            shortTitle: "Zapiš pokus",
            systemImageName: "figure.climbing"
        )
        AppShortcut(
            intent: HardestSendIntent(),
            phrases: [
                "What's my hardest send in \(.applicationName)",
                "Můj nejtěžší přelez v \(.applicationName)",
            ],
            shortTitle: "Nejtěžší přelez",
            systemImageName: "trophy"
        )
    }
}
