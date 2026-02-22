import Foundation

struct ReadinessEngine {
    func compute(game: Game, metrics: AthleteMetrics) -> ReadinessResult {
        let sleepScore = clamp(metrics.sleepHours / 9.0, min: 0.0, max: 1.0) * 25.0
        let sorenessScore = (1.0 - normalizeInt(metrics.soreness, max: 10)) * 20.0
        let stressScore = (1.0 - normalizeInt(metrics.stress, max: 10)) * 20.0
        let hydrationScore = clamp(metrics.hydrationOz / 100.0, min: 0.0, max: 1.0) * 15.0
        let intensityPenalty = normalizeInt(metrics.trainingIntensity, max: 10) * 20.0

        let rawScore = sleepScore + sorenessScore + stressScore + hydrationScore - intensityPenalty
        let score = Int(round(clamp(rawScore, min: 0.0, max: 100.0)))
        let label = readinessLabel(for: score)
        let topFactors = computeTopFactors(
            sleepHours: metrics.sleepHours,
            soreness: metrics.soreness,
            stress: metrics.stress,
            hydrationOz: metrics.hydrationOz,
            trainingIntensity: metrics.trainingIntensity,
            kickoffTime: game.kickoffTime
        )

        return ReadinessResult(score: score, label: label, topFactors: topFactors)
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

private func computeTopFactors(
    sleepHours: Double,
    soreness: Int,
    stress: Int,
    hydrationOz: Double,
    trainingIntensity: Int,
    kickoffTime: Date
) -> [String] {
    var factors: [(String, Double)] = []

    let sleepDeficit = max(0.0, 8.0 - sleepHours)
    factors.append(("Sleep below 8h", sleepDeficit))

    factors.append(("Soreness level", Double(soreness)))
    factors.append(("Stress level", Double(stress)))

    let hydrationDeficit = max(0.0, 80.0 - hydrationOz)
    factors.append(("Hydration below 80oz", hydrationDeficit / 10.0))

    factors.append(("Training intensity", Double(trainingIntensity)))

    let hoursToKickoff = max(0.0, kickoffTime.timeIntervalSinceNow / 3600.0)
    if hoursToKickoff < 6.0 {
        factors.append(("Game is soon", 6.0 - hoursToKickoff))
    }

    let sorted = factors.sorted { $0.1 > $1.1 }
    return sorted.prefix(3).map { $0.0 }
}

private func normalizeInt(_ value: Int, max: Int) -> Double {
    let clamped = min(max(value, 0), max)
    return Double(clamped) / Double(max)
}

private func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
    Swift.max(minValue, Swift.min(maxValue, value))
}
