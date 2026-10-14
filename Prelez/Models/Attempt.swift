import Foundation
import SwiftData

/// One go on a route: a send or a fall (F2, F3).
@Model
final class Attempt {
    var date: Date
    var resultRaw: String
    var styleRaw: String?
    var note: String?

    var route: Route?
    var session: ClimbSession?

    init(result: AttemptResult, style: AscentStyle? = nil, route: Route?, session: ClimbSession?, date: Date = .now) {
        self.date = date
        self.resultRaw = result.rawValue
        self.styleRaw = result == .send ? style?.rawValue : nil
        self.route = route
        self.session = session
    }

    var result: AttemptResult { AttemptResult(rawValue: resultRaw) ?? .fall }
    var style: AscentStyle? { styleRaw.flatMap(AscentStyle.init(rawValue:)) }
}
