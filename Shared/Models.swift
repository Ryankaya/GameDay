import Foundation

struct Game {
    let title: String
    let kickoffTime: Date
}

struct AthleteMetrics {
    let sleepHours: Double
    let soreness: Int
    let stress: Int
    let hydrationOz: Double
    let trainingIntensity: Int
}

struct ReadinessResult {
    let score: Int
    let label: String
    let topFactors: [String]
}

struct RecommendationResult {
    let nextAction: String
    let tips: [String]
}
