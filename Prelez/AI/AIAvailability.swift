import FoundationModels

/// Whether the on-device model can be used right now (F4 fallback, A7).
/// `#available` only checks the OS version, not whether Apple Intelligence is switched on.
nonisolated enum AIAvailability {
    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    /// Czech explanation for the UI, nil when the model is ready.
    static var unavailableMessage: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            nil
        case .unavailable(.appleIntelligenceNotEnabled):
            "Apple Intelligence je vypnutá. Zapni ji v Nastavení, nebo vyber cestu ručně."
        case .unavailable(.modelNotReady):
            "Model Apple Intelligence se ještě stahuje. Zatím vyber cestu ručně."
        case .unavailable(.deviceNotEligible):
            "Toto zařízení Apple Intelligence nepodporuje. Vyber cestu ručně."
        case .unavailable:
            "AI teď není k dispozici. Vyber cestu ručně."
        }
    }
}
