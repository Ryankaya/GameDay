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
        let minutesToKickoff = max(0, Int(game.kickoffTime.timeIntervalSinceNow / 60.0))
        let nextAction = prioritizedAction(
            athleteType: metrics.athleteType,
            readinessScore: readiness.score,
            minutesToKickoff: minutesToKickoff
        )

        return RecommendationResult(
            nextAction: nextAction,
            tips: topThreeTips(
                athleteType: metrics.athleteType,
                metrics: metrics,
                readiness: readiness,
                minutesToKickoff: minutesToKickoff
            )
        )
    }
}

private func prioritizedAction(
    athleteType: AthleteType,
    readinessScore: Int,
    minutesToKickoff: Int
) -> String {
    if minutesToKickoff <= 15 {
        return "Pre-game activation now: breathing, mobility, and tactical focus"
    }
    if minutesToKickoff <= 60 {
        return readinessScore >= 70
            ? "Prime for kickoff: dynamic warm-up + rapid fuel"
            : "Stabilize readiness: hydrate and short reset routine"
    }
    if minutesToKickoff <= 180 {
        return readinessScore >= 70
            ? "Controlled prep block: technique tune-up, then recovery"
            : "Recovery-first block: sleep/nap, fluids, and low load"
    }

    switch athleteType {
    case .soccer, .basketball, .football, .hockey:
        return "Prioritize mobility + hydration and protect lower-body freshness"
    case .baseball, .tennis:
        return "Prioritize shoulder/hip prep and maintain reaction sharpness"
    case .runner:
        return "Prioritize aerobic freshness and neuromuscular readiness"
    case .combat:
        return "Prioritize weight-cut safety, recovery, and reaction speed"
    }
}

private func topThreeTips(
    athleteType: AthleteType,
    metrics: AthleteMetrics,
    readiness: ReadinessResult,
    minutesToKickoff: Int
) -> [String] {
    var tips: [String] = []

    if metrics.sleepHours < 7.5 {
        tips.append("Sleep debt detected: prioritize a nap or earlier lights-out")
    }
    if metrics.hydrationOz < 80 {
        tips.append("Hydration priority: add 20-28 oz fluids with electrolytes")
    }
    if metrics.stress >= 7 {
        tips.append("Stress high: do 4 minutes of box breathing before training")
    }
    if metrics.soreness >= 7 {
        tips.append("Soreness high: 10-minute mobility + tissue prep before load")
    }

    if minutesToKickoff <= 90 {
        tips.append("Game window close: avoid new heavy work and protect freshness")
    }

    tips.append(contentsOf: athleteSpecificTips(for: athleteType))

    if readiness.score < 60 {
        tips.append("Low readiness: shift priority to recovery and hydration first")
    }

    if tips.count < 3 {
        tips.append("Fuel now: balanced carbs + lean protein in the next meal")
    }

    return Array(tips.prefix(3))
}

private func athleteSpecificTips(for athleteType: AthleteType) -> [String] {
    switch athleteType {
    case .soccer:
        return ["Soccer focus: ankle/hip prep + repeat-sprint readiness"]
    case .basketball:
        return ["Basketball focus: landing mechanics and calf/achilles prep"]
    case .football:
        return ["Football focus: neck/hip activation and short burst primer"]
    case .baseball:
        return ["Baseball focus: shoulder-elbow band work and trunk rotation"]
    case .hockey:
        return ["Hockey focus: adductor mobility and stride-power activation"]
    case .tennis:
        return ["Tennis focus: shoulder external rotation and first-step drills"]
    case .runner:
        return ["Running focus: glute activation and cadence rhythm primer"]
    case .combat:
        return ["Combat focus: reaction speed drill and safe rehydration plan"]
    }
}
