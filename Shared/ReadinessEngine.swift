import Foundation

struct ReadinessEngine {
    struct Weights {
        var sleep: Double = 30
        var soreness: Double = 20
        var stress: Double = 20
        var hydration: Double = 15
        var trainingIntensity: Double = 10
        var kickoffUrgency: Double = 5
    }

    private let weights: Weights

    init(weights: Weights = Weights()) {
        self.weights = weights
    }

    func compute(game: Game, metrics: AthleteMetrics) -> ReadinessResult {
        let sleepValue = clamp(metrics.sleepHours / 9.0, min: 0.0, max: 1.0)
        let sorenessValue = 1.0 - normalizeScale10(metrics.soreness)
        let stressValue = 1.0 - normalizeScale10(metrics.stress)
        let hydrationValue = clamp(metrics.hydrationOz / 100.0, min: 0.0, max: 1.0)
        let intensityValue = 1.0 - normalizeScale10(metrics.trainingIntensity)
        let urgencyValue = kickoffReadinessFactor(kickoffTime: game.kickoffTime)

        let contributions: [(String, Double)] = [
            ("Sleep quality", sleepValue * weights.sleep),
            ("Soreness load", sorenessValue * weights.soreness),
            ("Stress load", stressValue * weights.stress),
            ("Hydration level", hydrationValue * weights.hydration),
            ("Training intensity", intensityValue * weights.trainingIntensity),
            ("Time to kickoff", urgencyValue * weights.kickoffUrgency)
        ]

        let rawScore = contributions.map(\.1).reduce(0.0, +)
        let score = Int(round(clamp(rawScore, min: 0.0, max: 100.0)))

        return ReadinessResult(
            score: score,
            label: readinessLabel(for: score),
            topFactors: topFactors(from: contributions)
        )
    }
}

private func readinessLabel(for score: Int) -> String {
    switch score {
    case 85...:
        return "Game Ready"
    case 70..<85:
        return "On Track"
    case 50..<70:
        return "Needs Tune-Up"
    default:
        return "Recover First"
    }
}

private func topFactors(from contributions: [(String, Double)]) -> [String] {
    let sorted = contributions.sorted { abs($0.1) > abs($1.1) }
    return sorted.prefix(3).map { $0.0 }
}

private func kickoffReadinessFactor(kickoffTime: Date) -> Double {
    let hoursToKickoff = max(0.0, kickoffTime.timeIntervalSinceNow / 3600.0)

    switch hoursToKickoff {
    case ..<2:
        return 0.8
    case ..<6:
        return 1.0
    case ..<24:
        return 0.6
    default:
        return 0.3
    }
}

private func normalizeScale10(_ value: Int) -> Double {
    let clamped = Swift.min(Swift.max(value, 1), 10)
    return Double(clamped - 1) / 9.0
}

private func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
    Swift.max(minValue, Swift.min(maxValue, value))
}
