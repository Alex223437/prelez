import Foundation

/// Grading systems used at the gym.
/// French grades are written in lowercase (6b+), Fontainebleau boulder grades in uppercase (6B+).
nonisolated enum GradeSystem: String, Codable, Sendable {
    case french
    case font
}

/// A single climbing grade such as `6c+` (French) or `7A` (Font).
nonisolated struct Grade: Hashable, Sendable {
    let system: GradeSystem
    /// Number part, 3…9.
    let number: Int
    /// Letter part normalized to lowercase a/b/c, nil for grades like "5" or "5+".
    let letter: Character?
    let plus: Bool

    init(system: GradeSystem, number: Int, letter: Character?, plus: Bool) {
        self.system = system
        self.number = number
        self.letter = letter
        self.plus = plus
    }

    /// Parses exactly one grade, e.g. "6c+", "7A", "5+". Case decides the system:
    /// a lowercase letter means French, an uppercase letter means Font.
    /// Grades without a letter ("5+") are ambiguous, so the caller chooses the system.
    init?(_ text: String, systemWithoutLetter: GradeSystem = .french) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let match = trimmed.wholeMatch(of: /([3-9])([abcABC]?)(\+?)/) else { return nil }
        number = Int(match.1)!
        plus = !match.3.isEmpty
        if let raw = match.2.first {
            letter = Character(raw.lowercased())
            system = raw.isUppercase ? .font : .french
        } else {
            letter = nil
            system = systemWithoutLetter
        }
    }

    /// Position on the difficulty scale, used for sorting and for the pyramid.
    /// Grade is deliberately not Comparable: 6b and 6B share a rank but are different grades.
    var rank: Int {
        let letterValue: Int
        switch letter {
        case "a": letterValue = 20
        case "b": letterValue = 40
        case "c": letterValue = 60
        default: letterValue = 0
        }
        return number * 100 + letterValue + (plus ? 10 : 0)
    }

    /// Canonical text: "6c+" for French, "6C+" for Font.
    var text: String {
        var result = String(number)
        if let letter {
            result += system == .font ? letter.uppercased() : String(letter)
        }
        if plus { result += "+" }
        return result
    }
}

/// What a user may mean by a grade in free text.
nonisolated enum GradeMention: Hashable, Sendable {
    /// An exact grade, e.g. "6c" or "6C".
    case exact(Grade)
    /// The whole number band, e.g. "sedmička" = any 7a…7c+.
    case band(Int)
}
