import Foundation

protocol AIRecommendationService {
    func recommendations(
        game: Game,
        metrics: AthleteMetrics,
        readiness: ReadinessResult
    ) async -> RecommendationResult
}

struct StubAIRecommendationService: AIRecommendationService {
    func recommendations(
        game: Game,
        metrics: AthleteMetrics,
        readiness: ReadinessResult
    ) async -> RecommendationResult {
        let hoursToKickoff = max(0.0, game.kickoffTime.timeIntervalSinceNow / 3600.0)
        let nextAction = nextActionText(hoursToKickoff: hoursToKickoff, readiness: readiness)
        let tips = coachTips(metrics: metrics, readiness: readiness)

        return RecommendationResult(nextAction: nextAction, tips: tips)
    }
}

private func nextActionText(hoursToKickoff: Double, readiness: ReadinessResult) -> String {
    if hoursToKickoff < 2.0 {
        return "Warm up + lock in game plan"
    }
    if hoursToKickoff < 6.0 {
        return readiness.score < 70 ? "Light mobility + hydration" : "Sharp session + fuel up"
    }
    if hoursToKickoff < 24.0 {
        return readiness.score < 70 ? "Recover + early sleep" : "Taper session + hydrate"
    }
    return readiness.score < 70 ? "Prioritize recovery today" : "Stay consistent + hydrate"
}

private func coachTips(metrics: AthleteMetrics, readiness: ReadinessResult) -> [String] {
    var tips: [String] = []

    if metrics.sleepHours < 7.5 {
        tips.append("Aim for 8+ hours tonight")
    }
    if metrics.hydrationOz < 80 {
        tips.append("Add 16-24 oz of fluids")
    }
    if metrics.soreness >= 7 {
        tips.append("Do 10 min mobility work")
    }
    if metrics.stress >= 7 {
        tips.append("Try 5 min box breathing")
    }
    if metrics.trainingIntensity >= 8 {
        tips.append("Keep today low impact")
    }

    if tips.count < 3 {
        tips.append("Eat a balanced recovery meal")
    }
    if tips.count < 3 {
        tips.append("Review 1-2 game keys")
    }

    return Array(tips.prefix(3))
}
