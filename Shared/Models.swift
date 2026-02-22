import Foundation

enum AthleteType: String, CaseIterable, Codable, Identifiable {
    case soccer
    case basketball
    case football
    case baseball
    case hockey
    case tennis
    case runner
    case combat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soccer: return "Soccer"
        case .basketball: return "Basketball"
        case .football: return "Football"
        case .baseball: return "Baseball"
        case .hockey: return "Hockey"
        case .tennis: return "Tennis"
        case .runner: return "Runner"
        case .combat: return "Combat"
        }
    }
}

struct Game {
    var title: String
    var kickoffTime: Date
}

struct AthleteMetrics {
    var athleteType: AthleteType
    var sleepHours: Double
    var soreness: Int
    var stress: Int
    var hydrationOz: Double
    var trainingIntensity: Int
}

struct ReadinessResult {
    var score: Int
    var label: String
    var topFactors: [String]
}

struct RecommendationResult {
    var nextAction: String
    var tips: [String]
}
