import Foundation

/// Normalizes free text the way climbers type it: with or without diacritics, any case.
nonisolated enum TextFolding {
    private static let czech = Locale(identifier: "cs_CZ")

    /// "Žlutá 6c+ v Převisu" → "zluta 6c+ v previsu"
    static func fold(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: czech)
    }

    /// Removes diacritics but keeps letter case. Grades need the case: 6b ≠ 6B.
    static func foldKeepingCase(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive], locale: czech)
    }

    /// Folded words. Grade-like tokens keep their "+" ("6c+"), everything else is split
    /// on whitespace and punctuation.
    static func tokens(_ text: String) -> [String] {
        fold(text)
            .split { !($0.isLetter || $0.isNumber || $0 == "+") }
            .map(String.init)
    }

    /// Same split as `tokens`, but letter case is kept. Used to find grades.
    static func tokensKeepingCase(_ text: String) -> [String] {
        foldKeepingCase(text)
            .split { !($0.isLetter || $0.isNumber || $0 == "+") }
            .map(String.init)
    }

    /// Stem used for matching declined Czech nouns: "převis" matches "převisu",
    /// "kolmice" matches "kolmici", "plotna" matches "plotně".
    /// Only the last vowel is dropped and the stem is never shorter than `minimumLength`,
    /// so short words do not turn into loose prefixes.
    static func stem(_ word: String, minimumLength: Int = 4) -> String {
        let folded = fold(word)
        guard folded.count > minimumLength, let last = folded.last, "aeiouy".contains(last) else {
            return folded
        }
        return String(folded.dropLast())
    }
}
