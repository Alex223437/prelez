import Foundation

/// Rule-based understanding of how climbers describe routes.
/// It is deterministic and fast. The AI only steps in when these rules find nothing or too much.
nonisolated struct QueryParser {
    /// Routes of the gym. Sector aliases, setter names and route names are read from them.
    let routes: [RouteInfo]

    func parse(_ text: String) -> RouteQuery {
        let tokens = TextFolding.tokens(text)
        var query = RouteQuery()
        query.colors = HoldColor.mentioned(in: tokens)
        query.grades = Self.grades(in: text, foldedTokens: tokens)
        query.kind = Self.kind(in: tokens)
        query.sectorIDs = sectorIDs(in: tokens)
        query.setter = setter(in: tokens)
        query.number = Self.routeNumber(in: text, tokens: tokens)
        query.namedRouteIDs = namedRouteIDs(in: tokens)
        query.wantsNewest = !Self.newestWords.isDisjoint(with: tokens)
        query.traits = RouteTrait.mentioned(in: tokens)
        query.attemptNumber = Self.attemptNumber(in: tokens)
        let outcome = Self.resultAndStyle(in: tokens, attemptNumber: query.attemptNumber)
        query.result = outcome.result
        query.style = outcome.style
        return query
    }

    // MARK: - Unexplained words

    private static let stopWords: Set<String> = [
        "ta", "ten", "to", "tu", "ty", "ti", "tim", "tou", "tom", "toho", "na", "v", "ve", "s", "se",
        "z", "ze", "do", "od", "a", "i", "je", "jsem", "jsi", "jsme", "byl", "byla", "bylo", "jen",
        "uz", "jeste", "asi", "tam", "tady", "ale", "nebo", "pak", "pro", "po", "pri", "u", "k", "ke",
        "o", "co", "jak", "kde", "ktera", "kterou", "ktery", "ho", "ji", "mi", "me", "mne", "moje",
        "muj", "dneska", "dnes", "zase", "konecne", "hned", "tak",
        "the", "an", "on", "in", "at", "it", "one", "that", "this", "with", "and", "or",
        "my", "just", "finally", "today", "got",
    ]

    /// Words the rules did not use. The AI is consulted only when something meaningful is left
    /// ("ta se skokem venku" leaves "skokem"); "ta žlutá" leaves nothing, so the user simply picks.
    func unexplainedWords(in text: String) -> [String] {
        let colorWords = HoldColor.allCases.reduce(into: Set<String>()) { $0.formUnion($1.wordForms) }
        let known = colorWords
            .union(Self.boulderWords).union(Self.routeWords).union(Self.numberKeywords)
            .union(Self.newestWords).union(Self.attemptWords).union(Self.ordinals.keys)
            .union(Self.sendWords).union(Self.fallWords).union(Self.styleWords.keys)
            .union(Self.stopWords).union(["pohled", "rope"])

        var stems: [String] = []
        for route in routes {
            stems += (route.sectorAliases + [route.sectorName]).map { TextFolding.stem($0) }
            if let setter = route.setter { stems.append(TextFolding.stem(setter, minimumLength: 3)) }
            if let name = route.name {
                stems += TextFolding.tokens(name).filter { $0.count >= 4 }.map { TextFolding.stem($0) }
            }
        }

        return TextFolding.tokens(text).filter { token in
            guard token.count >= 3, !known.contains(token), Int(token) == nil, Grade(token) == nil else {
                return false
            }
            if Self.gradeWordStems.contains(where: { token.hasPrefix($0.stem) }) { return false }
            if RouteTrait.allCases.contains(where: { $0.isNamed(by: token) }) { return false }
            return !stems.contains { token.hasPrefix($0) }
        }
    }

    private static let czechMarkers: Set<String> = [
        "ta", "ten", "to", "tu", "se", "na", "v", "ve", "jsem", "je", "byl", "byla", "jen", "od", "do",
        "pak", "tak", "ktera", "kterou", "dal", "dala", "spadl", "spadla", "uz", "jeste",
    ]

    /// True for Czech notes: diacritics or typical Czech words. The on-device model does not support Czech,
    /// so these notes stay with the rules. Language detectors are unreliable on four-word notes
    /// (NLLanguageRecognizer calls "zluta 6c previs" Indonesian), this simple check is not.
    static func looksCzech(_ text: String) -> Bool {
        if text.contains(where: { "áčďéěíňóřšťúůýžÁČĎÉĚÍŇÓŘŠŤÚŮÝŽ".contains($0) }) { return true }
        return !czechMarkers.isDisjoint(with: TextFolding.tokens(text))
    }

    // MARK: - Grades

    /// Colloquial Czech grade words: "pětka" = any 5, "sedmička" = any 7.
    private static let gradeWordStems: [(stem: String, number: Int)] = [
        ("trojk", 3), ("trojc", 3), ("ctyrk", 4), ("ctyrc", 4),
        ("petk", 5), ("petc", 5), ("sestk", 6), ("sestc", 6),
        ("sedmick", 7), ("sedmicc", 7), ("osmick", 8), ("osmicc", 8),
        ("devitk", 9), ("devitc", 9),
    ]

    static func grades(in text: String, foldedTokens: [String]) -> [GradeMention] {
        var mentions: [GradeMention] = []
        // Case-sensitive on purpose: "6b" is a French rope grade, "6B" a Font boulder grade.
        for token in TextFolding.tokensKeepingCase(text) {
            guard let grade = Grade(token) else { continue }
            // A bare number ("3") is too often an attempt count or a route number.
            // Accept it only with a letter or a plus sign ("5+").
            guard grade.letter != nil || grade.plus else { continue }
            mentions.append(.exact(grade))
        }
        for token in foldedTokens {
            if let word = gradeWordStems.first(where: { token.hasPrefix($0.stem) }) {
                mentions.append(.band(word.number))
            }
        }
        return mentions
    }

    // MARK: - Kind

    private static let boulderWords: Set<String> = [
        "boulder", "bouldr", "bouldru", "bouldry", "bouldrik", "bouldering", "problem",
    ]
    private static let routeWords: Set<String> = [
        "cesta", "cestu", "ceste", "cesty", "lano", "lane", "lanem", "route", "lead",
    ]

    static func kind(in tokens: [String]) -> RouteKind? {
        let words = Set(tokens)
        let saysBoulder = !boulderWords.isDisjoint(with: words)
        let saysRoute = !routeWords.isDisjoint(with: words)
        switch (saysBoulder, saysRoute) {
        case (true, false): return .boulder
        case (false, true): return .route
        default: return nil
        }
    }

    // MARK: - Sectors, setters, names

    func sectorIDs(in tokens: [String]) -> Set<String> {
        var aliasesBySector: [String: Set<String>] = [:]
        for route in routes {
            var aliases = route.sectorAliases
            if !route.sectorName.contains(" ") { aliases.append(route.sectorName) }
            aliasesBySector[route.sectorID, default: []].formUnion(aliases.map { TextFolding.stem($0) })
        }
        var found: Set<String> = []
        for (sectorID, stems) in aliasesBySector {
            if tokens.contains(where: { token in stems.contains { token.hasPrefix($0) } }) {
                found.insert(sectorID)
            }
        }
        return found
    }

    func setter(in tokens: [String]) -> String? {
        let setters = Set(routes.compactMap(\.setter))
        // "Pepa" → stem "pep" matches "Pepy", "Pepou", "Pepova".
        return setters.sorted().first { name in
            let stem = TextFolding.stem(name, minimumLength: 3)
            return tokens.contains { $0.count >= 3 && $0.hasPrefix(stem) }
        }
    }

    func namedRouteIDs(in tokens: [String]) -> Set<String> {
        let colorWords = HoldColor.allCases.reduce(into: Set<String>()) { $0.formUnion($1.wordForms) }
        var found: Set<String> = []
        for route in routes {
            guard let name = route.name else { continue }
            let nameStems = TextFolding.tokens(name)
                .filter { $0.count >= 4 && !colorWords.contains($0) }
                .map { TextFolding.stem($0) }
            let mentioned = nameStems.contains { stem in tokens.contains { $0.hasPrefix(stem) } }
            if mentioned { found.insert(route.id) }
        }
        return found
    }

    // MARK: - Route number ("lajna 12", "č. 12", "#12")

    private static let numberKeywords: Set<String> = [
        "lajna", "lajne", "lajnu", "linka", "lince", "linku", "cislo", "c", "line", "number", "no",
    ]

    static func routeNumber(in text: String, tokens: [String]) -> Int? {
        if let match = text.firstMatch(of: /#(\d+)/) { return Int(match.1) }
        for (index, token) in tokens.enumerated().dropLast() where numberKeywords.contains(token) {
            if let number = Int(tokens[index + 1]) { return number }
        }
        return nil
    }

    // MARK: - Newest, attempt number, result, style

    static let newestWords: Set<String> = [
        "nova", "novou", "nove", "novy", "novej", "nejnovejsi", "novinka", "novinku",
        "new", "newest", "cerstva", "cerstvou",
    ]

    private static let ordinals: [String: Int] = [
        "prvni": 1, "prvnim": 1, "first": 1,
        "druhy": 2, "druhou": 2, "second": 2,
        "treti": 3, "tretim": 3, "third": 3,
        "ctvrty": 4, "ctvrtou": 4, "fourth": 4,
        "paty": 5, "patou": 5, "fifth": 5,
    ]
    private static let attemptWords: Set<String> = ["pokus", "pokusu", "go", "try", "attempt"]

    /// "na třetí" / "třetí pokus" / "3. pokus" / "third go" → 3.
    static func attemptNumber(in tokens: [String]) -> Int? {
        for (index, token) in tokens.enumerated() {
            let previous = index > 0 ? tokens[index - 1] : ""
            let next = index + 1 < tokens.count ? tokens[index + 1] : ""
            let nearAttempt = previous == "na" || previous == "the" || attemptWords.contains(next)
            if let value = ordinals[token], nearAttempt { return value }
            if let value = Int(token), attemptWords.contains(next), (1...50).contains(value) { return value }
        }
        return nil
    }

    private static let sendWords: Set<String> = [
        "prelez", "prelezl", "prelezla", "prelezeno", "dal", "dala", "dalo", "top", "topnul",
        "topnula", "topla", "dolezl", "dolezla", "vylezl", "vylezla", "hotovo",
        "sent", "send", "topped",
    ]
    private static let fallWords: Set<String> = [
        "pad", "pady", "padam", "padal", "padala", "padl", "padla", "spadl", "spadla", "spadnul",
        "odpadl", "odpadla", "nedal", "nedala", "nedolezl", "nedolezla", "nevylezl",
        "fall", "fell",
    ]
    private static let styleWords: [String: AscentStyle] = [
        "os": .onsight, "onsight": .onsight,
        "flash": .flash, "flesh": .flash, "flashnul": .flash, "flashla": .flash,
        "rp": .redpoint, "redpoint": .redpoint,
        "tr": .topRope, "toprope": .topRope, "topropem": .topRope,
    ]

    static func resultAndStyle(in tokens: [String], attemptNumber: Int?) -> (result: AttemptResult?, style: AscentStyle?) {
        let words = Set(tokens)
        var style = tokens.lazy.compactMap { styleWords[$0] }.first
        if style == nil, containsPair(tokens, "na", "pohled") { style = .onsight }
        if style == nil, containsPair(tokens, "top", "rope") || containsPair(tokens, "na", "druhem") {
            style = .topRope
        }

        let saysSend = !sendWords.isDisjoint(with: words)
        let saysFall = !fallWords.isDisjoint(with: words)
        let result: AttemptResult?
        if saysSend {
            // "dal jsem to na třetí, předtím dva pády": the send wins, falls describe earlier tries.
            result = .send
        } else if saysFall {
            result = .fall
        } else if style != nil {
            // "RP", "flash" alone mean a send.
            result = .send
        } else {
            result = nil
        }

        if result == .send, style == nil, let attemptNumber {
            style = attemptNumber == 1 ? .flash : .redpoint
        }
        if result == .fall { style = nil }
        return (result, style)
    }

    private static func containsPair(_ tokens: [String], _ first: String, _ second: String) -> Bool {
        zip(tokens, tokens.dropFirst()).contains { $0 == first && $1 == second }
    }
}
