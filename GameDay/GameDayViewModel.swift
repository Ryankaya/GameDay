import ActivityKit
import Combine
import Foundation

@MainActor
final class GameDayViewModel: ObservableObject {
    @Published var gameTitle: String
    @Published var kickoffTime: Date

    @Published var athleteType: AthleteType
    @Published var sleepHours: Double
    @Published var soreness: Int
    @Published var stress: Int
    @Published var hydrationOz: Double
    @Published var trainingIntensity: Int

    @Published var readiness: ReadinessResult
    @Published var recommendation: RecommendationResult
    @Published var liveActivityMessage: String
    @Published var aiModeStatus: String
    @Published var healthSyncStatus: String
    @Published var chatMessages: [CoachChatMessage]
    @Published var isChatResponding: Bool

    private(set) var liveActivity: Activity<GameDayWidgetAttributes>?

    private let readinessEngine: ReadinessEngine
    private let coachService: FoundationModelsCoachService
    private let healthKitService: HealthKitMetricsService

    init(
        readinessEngine: ReadinessEngine? = nil,
        coachService: FoundationModelsCoachService? = nil,
        healthKitService: HealthKitMetricsService? = nil
    ) {
        let resolvedReadinessEngine = readinessEngine ?? ReadinessEngine()
        let resolvedCoachService = coachService ?? FoundationModelsCoachService()
        let resolvedHealthKitService = healthKitService ?? HealthKitMetricsService()

        let initialGame = DemoData.game()
        let initialMetrics = DemoData.metrics()

        gameTitle = initialGame.title
        kickoffTime = initialGame.kickoffTime

        athleteType = initialMetrics.athleteType
        sleepHours = initialMetrics.sleepHours
        soreness = initialMetrics.soreness
        stress = initialMetrics.stress
        hydrationOz = initialMetrics.hydrationOz
        trainingIntensity = initialMetrics.trainingIntensity

        readiness = ReadinessResult(score: 0, label: "Not Evaluated", topFactors: [])
        recommendation = RecommendationResult(nextAction: "Generate coach tips to see your plan.", tips: [])
        liveActivityMessage = "Live Activity inactive"
        aiModeStatus = resolvedCoachService.modeDescription
        healthSyncStatus = "HealthKit not synced yet"
        chatMessages = [
            CoachChatMessage(
                role: .coach,
                text: "Ask me anything about readiness, recovery, or pre-game priorities. I will keep guidance time-aware."
            )
        ]
        isChatResponding = false

        self.readinessEngine = resolvedReadinessEngine
        self.coachService = resolvedCoachService
        self.healthKitService = resolvedHealthKitService
    }

    var game: Game {
        Game(title: gameTitle.isEmpty ? "Upcoming Game" : gameTitle, kickoffTime: kickoffTime)
    }

    var metrics: AthleteMetrics {
        AthleteMetrics(
            athleteType: athleteType,
            sleepHours: sleepHours,
            soreness: soreness,
            stress: stress,
            hydrationOz: hydrationOz,
            trainingIntensity: trainingIntensity
        )
    }

    var minutesToKickoff: Int {
        Int(game.kickoffTime.timeIntervalSinceNow / 60)
    }

    var kickoffBadge: String {
        let minutes = minutesToKickoff
        if minutes <= 0 {
            return "LIVE"
        }
        if minutes < 60 {
            return "\(minutes)m"
        }
        return "\(minutes / 60)h"
    }

    func evaluate() async {
        let nextReadiness = readinessEngine.compute(game: game, metrics: metrics)
        let nextRecommendation = await coachService.recommendations(
            game: game,
            metrics: metrics,
            readiness: nextReadiness
        )

        readiness = nextReadiness
        recommendation = nextRecommendation
        aiModeStatus = coachService.modeDescription
    }

    func importMetricsFromHealthKit() async {
        do {
            let snapshot = try await healthKitService.fetchSnapshot()
            applyHealthSnapshot(snapshot)
            healthSyncStatus = "HealthKit synced at \(Self.timeFormatter.string(from: .now))"
            await evaluate()
        } catch {
            healthSyncStatus = "HealthKit import failed: \(error.localizedDescription)"
        }
    }

    func sendChatMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        chatMessages.append(CoachChatMessage(role: .athlete, text: trimmed))
        isChatResponding = true

        if readiness.score == 0 {
            await evaluate()
        } else {
            aiModeStatus = coachService.modeDescription
        }

        let reply = await coachService.reply(
            userMessage: trimmed,
            game: game,
            metrics: metrics,
            readiness: readiness,
            recommendation: recommendation,
            recentMessages: chatMessages
        )

        chatMessages.append(CoachChatMessage(role: .coach, text: reply))
        isChatResponding = false
    }

    func startLiveActivity() async {
        await evaluate()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            liveActivityMessage = "Live Activities are disabled on this device"
            return
        }

        do {
            let activity = try Activity.request(
                attributes: GameDayWidgetAttributes(gameTitle: game.title, kickoffTime: game.kickoffTime),
                content: .init(state: makeActivityContentState(), staleDate: nil),
                pushType: nil
            )
            liveActivity = activity
            liveActivityMessage = "Started Live Activity"
        } catch {
            liveActivityMessage = "Could not start Live Activity: \(error.localizedDescription)"
        }
    }

    func updateLiveActivity() async {
        await evaluate()

        let activity = liveActivity ?? Activity<GameDayWidgetAttributes>.activities.first
        guard let activity else {
            liveActivityMessage = "No active Live Activity to update"
            return
        }

        liveActivity = activity
        await activity.update(.init(state: makeActivityContentState(), staleDate: nil))
        liveActivityMessage = "Updated Live Activity"
    }

    func endLiveActivity() async {
        let activity = liveActivity ?? Activity<GameDayWidgetAttributes>.activities.first
        guard let activity else {
            liveActivityMessage = "No active Live Activity"
            return
        }

        await activity.end(.init(state: makeActivityContentState(), staleDate: nil), dismissalPolicy: .immediate)
        liveActivity = nil
        liveActivityMessage = "Ended Live Activity"
    }

    private func makeActivityContentState() -> GameDayWidgetAttributes.ContentState {
        let tip = recommendation.tips.first ?? "Hydrate and keep your recovery routine tight"
        return GameDayWidgetAttributes.ContentState(
            readinessScore: readiness.score,
            readinessLabel: readiness.label,
            nextAction: recommendation.nextAction,
            tip: tip
        )
    }

    private func applyHealthSnapshot(_ snapshot: HealthMetricsSnapshot) {
        if let sleep = snapshot.sleepHours {
            sleepHours = bounded(sleep, min: 3.0, max: 10.0)
        }
        if let hydration = snapshot.hydrationOz {
            hydrationOz = bounded(hydration, min: 20.0, max: 180.0)
        }
        if let stressScore = snapshot.stress {
            stress = bounded(stressScore, min: 1, max: 10)
        }
        if let sorenessScore = snapshot.soreness {
            soreness = bounded(sorenessScore, min: 1, max: 10)
        }
        if let intensity = snapshot.trainingIntensity {
            trainingIntensity = bounded(intensity, min: 1, max: 10)
        }
    }

    private func bounded(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }

    private func bounded(_ value: Int, min minValue: Int, max maxValue: Int) -> Int {
        Swift.max(minValue, Swift.min(maxValue, value))
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
