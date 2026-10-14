import Testing
@testable import Prelez

@Suite("Obtížnosti (Grade)")
struct GradeTests {
    @Test("Malé písmeno = francouzská stupnice, velké = Font (A11)")
    func caseDecidesSystem() throws {
        let rope = try #require(Grade("6b"))
        let boulder = try #require(Grade("6B"))
        #expect(rope.system == .french)
        #expect(boulder.system == .font)
        #expect(rope != boulder)
        #expect(rope.rank == boulder.rank)
    }

    @Test("Pořadí obtížností")
    func ordering() throws {
        let grades = try ["5+", "5c", "6a", "6a+", "6b", "6c+", "7a"].map { try #require(Grade($0)) }
        #expect(grades.map(\.rank) == grades.map(\.rank).sorted())
        #expect(Set(grades.map(\.rank)).count == grades.count)
    }

    @Test("Kanonický zápis", arguments: ["6c+", "6C+", "7a", "7A", "5+"])
    func canonicalText(_ text: String) throws {
        #expect(try #require(Grade(text)).text == text)
    }

    @Test("Neplatné obtížnosti", arguments: ["10a", "6d", "abc", "", "2a"])
    func invalid(_ text: String) {
        #expect(Grade(text) == nil)
    }
}

@Suite("Barvy chytů")
struct HoldColorTests {
    @Test("Pády a nespisovné tvary", arguments: [
        ("Žlutá", HoldColor?.some(.yellow)), ("žlutou", .yellow), ("zlutej", .yellow),
        ("modrý", .blue), ("červené", .red), ("šedá", .grey), ("gray", .grey), ("citronová", nil),
    ])
    func forms(_ word: String, _ expected: HoldColor?) {
        let found = HoldColor.mentioned(in: TextFolding.tokens(word))
        #expect(found == (expected.map { [$0] } ?? []))
    }

    @Test("„sedmička“ není šedá, i když po odstranění diakritiky začíná na „sed“")
    func sedmickaIsNotGrey() {
        #expect(HoldColor.mentioned(in: TextFolding.tokens("modrá sedmička")) == [.blue])
    }
}

@Suite("Parser popisu cesty")
struct QueryParserTests {
    let parser: QueryParser

    init() throws {
        parser = QueryParser(routes: try TestSupport.sampleRoutes())
    }

    @Test("Výsledek a styl", arguments: [
        ("žlutá 6c RP", AttemptResult.send, AscentStyle?.some(.redpoint)),
        ("na třetí jsem to dal", .send, .redpoint),
        ("flash", .send, .flash),
        ("dal jsem to na první", .send, .flash),
        ("onsight", .send, .onsight),
        ("spadl jsem v kruxu", .fall, nil),
        ("nedal jsem to", .fall, nil),
    ])
    func outcome(_ text: String, _ result: AttemptResult, _ style: AscentStyle?) {
        let query = parser.parse(text)
        #expect(query.result == result)
        #expect(query.style == style)
    }

    @Test("Číslo lajny")
    func routeNumber() {
        #expect(parser.parse("lajna 12").number == 12)
        #expect(parser.parse("#14").number == 14)
        #expect(parser.parse("3 pokusy").number == nil)
    }

    @Test("Stavěč ve všech pádech a „ta nová“")
    func setterAndNewest() {
        let query = parser.parse("ta nová od Pepy")
        #expect(query.setter == "Pepa")
        #expect(query.wantsNewest)
    }

    @Test("Sektor se skloňuje: převis → v převisu, plotna → na plotně")
    func sectors() {
        #expect(parser.parse("v převisu").sectorIDs == ["previs"])
        #expect(parser.parse("na plotně").sectorIDs == ["plotna"])
        #expect(parser.parse("na kolmici").sectorIDs == ["kolmice"])
        #expect(parser.parse("outside").sectorIDs == ["venku"])
    }

    @Test("Holé číslo není obtížnost (je to počet pokusů nebo lajna)")
    func bareNumberIsNotAGrade() {
        #expect(parser.parse("na 3 pokusy").grades.isEmpty)
    }

    @Test("Nevysvětlená slova pouští AI ke slovu jen u nových informací")
    func unexplainedWords() {
        #expect(parser.unexplainedWords(in: "ta žlutá").isEmpty)
        #expect(parser.unexplainedWords(in: "zluta 6c previs, rp").isEmpty)
        // "skokem" is in the trait glossary, so a Czech note needs no AI.
        #expect(parser.unexplainedWords(in: "ta se skokem venku").isEmpty)
        #expect(parser.unexplainedWords(in: "the one with the big jump outside") == ["big", "jump"])
    }

    @Test("Charakter cesty z českého slovníku", arguments: [
        ("ta se skokem", RouteTrait.dyno), ("lištovitá", .crimps), ("ta oblá", .slopers), ("dlouhá", .long),
    ])
    func traits(_ text: String, _ trait: RouteTrait) {
        #expect(parser.parse(text).traits == [trait])
    }

    @Test("„oblíbená“ není oblá")
    func favouriteIsNotSloper() {
        #expect(parser.parse("moje oblíbená").traits.isEmpty)
    }

    @Test("Česká poznámka se pozná i bez diakritiky")
    func looksCzech() {
        #expect(QueryParser.looksCzech("ta se skokem venku"))
        #expect(QueryParser.looksCzech("citronová v kolmici"))
        #expect(!QueryParser.looksCzech("the one with the big jump outside"))
    }
}

@Suite("Hledání cesty (RouteMatcher)")
struct RouteMatcherTests {
    let routes: [RouteInfo]

    init() throws {
        routes = try TestSupport.sampleRoutes()
    }

    private func resolve(_ text: String) -> RouteResolution {
        RuleBasedRouteResolver().interpretNow(text, routes: routes).resolution
    }

    @Test("A3/A4: s diakritikou i bez najde stejnou cestu")
    func diacritics() {
        #expect(resolve("žlutá 6c v převisu").candidates.map(\.id) == ["R-01"])
        #expect(resolve("zluta 6c previs").candidates.map(\.id) == ["R-01"])
    }

    @Test("A5: neexistující cesta → nenalezeno")
    func notFound() {
        #expect(resolve("fialová 9a") == .notFound)
    }

    @Test("A6: „ta žlutá“ → výběr, ne náhodná cesta")
    func ambiguous() {
        guard case .ambiguous(let routes) = resolve("ta žlutá") else {
            Issue.record("Expected ambiguous")
            return
        }
        #expect(Set(routes.map(\.id)) == ["R-01", "R-02", "B-01", "B-05"])
    }

    @Test("A11: 6b je cesta na laně, 6B boulder")
    func gradeCase() {
        #expect(resolve("červená 6b").candidates.map(\.id) == ["R-05"])
        #expect(resolve("červená 6B").candidates.map(\.id) == ["B-02"])
    }

    @Test("Špatná velikost písmen dá jen návrh, nikdy automatický výběr")
    func nearMatch() {
        #expect(resolve("žlutá 6C v převisu") == .nearMatch(routes.filter { $0.id == "R-01" }))
    }
}
