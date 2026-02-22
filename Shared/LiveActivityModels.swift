import ActivityKit
import Foundation

struct GameDayWidgetAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var readinessScore: Int
        var readinessLabel: String
        var nextAction: String
        var tip: String
    }

    var gameTitle: String
    var kickoffTime: Date
}
