@testable import Prelez

/// Golden set of the quick log (F4). Hand-written against the SAMPLE snapshot (Resources/routes-sample.json).
/// When the setters' export arrives: rewrite to real Vertikon routes, add real phrases from the bar,
/// and freeze the snapshot date so the eval keeps its meaning after a reset.
enum GoldenSet {
    static let cases: [GoldenCase] = [
        // Rules alone should handle these.
        GoldenCase(id: "happy-rp", input: "žlutá 6c v převisu RP", expected: .route("R-01"), expectedResult: .send),
        GoldenCase(id: "no-diacritics", input: "zluta 6c previs, rp", expected: .route("R-01"), expectedResult: .send),
        GoldenCase(id: "english", input: "yellow 6c on the overhang, sent it", expected: .route("R-01"), expectedResult: .send),
        GoldenCase(id: "rope-fall", input: "červená 6b na kolmici, spadl jsem", expected: .route("R-05"), expectedResult: .fall),
        GoldenCase(id: "boulder-uppercase", input: "červená 6B", expected: .route("B-02")),
        GoldenCase(id: "grey-not-seven", input: "šedá v převisu", expected: .route("R-06")),
        GoldenCase(id: "blue-seven", input: "modrá sedmička v převisu", expected: .route("R-03")),
        GoldenCase(id: "newest-by-setter", input: "ta nová od Pepy, flash", expected: .route("R-13"), expectedResult: .send),
        GoldenCase(id: "line-number", input: "lajna 12, dal jsem to na třetí", expected: .route("R-01"), expectedResult: .send),
        GoldenCase(id: "green-five-slab", input: "zelená pětka na plotně", expected: .route("R-08")),
        GoldenCase(id: "orange-third", input: "oranžová v kolmici, na třetí jsem to dal", expected: .route("R-09"), expectedResult: .send),
        GoldenCase(id: "named-route", input: "ponorka", expected: .route("R-01")),
        GoldenCase(id: "boulder-outside", input: "žlutá 6C venku", expected: .route("B-01")),

        // Must ask the user instead of guessing.
        GoldenCase(id: "ambiguous-yellow", input: "ta žlutá", expected: .ambiguous(["R-01", "R-02", "B-01", "B-05"])),
        GoldenCase(id: "seven-band", input: "sedmička v převisu", expected: .ambiguous(["R-03", "R-06", "R-07", "R-14"])),
        GoldenCase(id: "near-match-case", input: "žlutá 6C v převisu", expected: .ambiguous(["R-01"])),

        // Must not invent anything.
        GoldenCase(id: "not-found", input: "fialová 9a", expected: .notFound),
        GoldenCase(id: "no-route-coffee", input: "byl jsem jen na kafi", expected: .notFound),

        // Czech route character: rules + trait glossary. The on-device model does not support Czech.
        GoldenCase(id: "trait-dyno-outside", input: "ta se skokem venku", expected: .route("B-01")),
        GoldenCase(id: "trait-long-slopey", input: "ta dlouhá oblá v převisu", expected: .route("R-03")),
        GoldenCase(id: "trait-none-slab", input: "ta se skokem na plotně", expected: .ambiguous(["R-04", "R-08", "R-11", "R-16"])),
        GoldenCase(id: "czech-unknown-word", input: "citronová v kolmici", expected: .ambiguous(["R-02", "R-05", "R-09", "R-15"])),

        // English notes (Erasmus climbers): the rules leave words, the on-device model may decide.
        GoldenCase(id: "ai-en-jump", input: "the one with the big jump outside", expected: .route("B-01")),
        GoldenCase(id: "ai-en-lemon", input: "the lemon colored one on the vertical wall", expected: .route("R-02")),
        GoldenCase(id: "ai-en-long-slopey", input: "that long slopey line in the overhang", expected: .route("R-03")),
        GoldenCase(id: "ai-en-hints", input: "the lemon one", expected: .ambiguous(["R-01", "R-02", "B-01", "B-05"])),
        GoldenCase(id: "ai-en-unsure-slab", input: "the one with the jump on the slab", expected: .ambiguous(["R-04", "R-08", "R-11", "R-16"])),
        GoldenCase(id: "ai-en-unsure-crimpy", input: "the crimpy black one", expected: .ambiguous(["R-07", "B-03"])),
    ]
}
