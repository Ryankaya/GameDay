import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

protocol CoachChatService {
    func reply(
        userMessage: String,
        game: Game,
        metrics: AthleteMetrics,
        readiness: ReadinessResult,
        recommendation: RecommendationResult,
        recentMessages: [CoachChatMessage]
    ) async -> String
}

@MainActor
final class FoundationModelsCoachService: AIRecommendationService, CoachChatService {
    private let fallbackRecommendationService: any AIRecommendationService
    private let fallbackChatService: any CoachChatService

    init(
        fallbackRecommendationService: (any AIRecommendationService)? = nil,
        fallbackChatService: (any CoachChatService)? = nil
    ) {
        self.fallbackRecommendationService = fallbackRecommendationService ?? StubAIRecommendationService()
        self.fallbackChatService = fallbackChatService ?? RuleBasedCoachChatService()
    }

    var modeDescription: String {
        Self.supportsOnDeviceModel
            ? "On-device Foundation Model active"
            : "Rule-based coach mode (Apple Intelligence unavailable)"
    }

    static var supportsOnDeviceModel: Bool {
#if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { return false }
        let model = SystemLanguageModel.default
        return model.isAvailable && model.supportsLocale(.current)
#else
        return false
#endif
    }

    func recommendations(
        game: Game,
        metrics: AthleteMetrics,
        readiness: ReadinessResult
    ) async -> RecommendationResult {
        let fallback = await fallbackRecommendationService.recommendations(
            game: game,
            metrics: metrics,
            readiness: readiness
        )

#if canImport(FoundationModels)
        guard #available(iOS 26.0, *), Self.supportsOnDeviceModel else {
            return fallback
        }

        do {
            return try await generateRecommendations(
                game: game,
                metrics: metrics,
                readiness: readiness,
                fallback: fallback
            )
        } catch {
            return fallback
        }
#else
        return fallback
#endif
    }

    func reply(
        userMessage: String,
        game: Game,
        metrics: AthleteMetrics,
        readiness: ReadinessResult,
        recommendation: RecommendationResult,
        recentMessages: [CoachChatMessage]
    ) async -> String {
        let fallback = await fallbackChatService.reply(
            userMessage: userMessage,
            game: game,
            metrics: metrics,
            readiness: readiness,
            recommendation: recommendation,
            recentMessages: recentMessages
        )

#if canImport(FoundationModels)
        guard #available(iOS 26.0, *), Self.supportsOnDeviceModel else {
            return fallback
        }

        do {
            return try await generateChatReply(
                userMessage: userMessage,
                game: game,
                metrics: metrics,
                readiness: readiness,
                recommendation: recommendation,
                recentMessages: recentMessages,
                fallback: fallback
            )
        } catch {
            return fallback
        }
#else
        return fallback
#endif
    }
}

@MainActor
struct RuleBasedCoachChatService: CoachChatService {
    func reply(
        userMessage: String,
        game: Game,
        metrics: AthleteMetrics,
        readiness: ReadinessResult,
        recommendation: RecommendationResult,
        recentMessages: [CoachChatMessage]
    ) async -> String {
        let minutesToKickoff = max(0, Int(game.kickoffTime.timeIntervalSinceNow / 60))
        let message = userMessage.lowercased()

        if message.contains("sleep") {
            return "Protect sleep debt first. If kickoff is in \(timeWindow(minutesToKickoff)), prioritize a short nap and reduce cognitive load."
        }
        if message.contains("hydrate") || message.contains("water") {
            return "Hydration is your priority now. Add 16-24 oz with electrolytes before the next prep block."
        }
        if message.contains("stress") || message.contains("anxious") {
            return "Run a 4-minute breathing reset, then 5 minutes of mobility. This lowers arousal without draining energy."
        }

        return "\(recommendation.nextAction). With kickoff in \(timeWindow(minutesToKickoff)), keep your focus on \(priorityFocus(metrics: metrics, readiness: readiness))."
    }
}

private func timeWindow(_ minutesToKickoff: Int) -> String {
    if minutesToKickoff <= 0 {
        return "live-game time"
    }
    if minutesToKickoff < 60 {
        return "\(minutesToKickoff) minutes"
    }
    let hours = minutesToKickoff / 60
    return "\(hours) hour\(hours == 1 ? "" : "s")"
}

private func priorityFocus(metrics: AthleteMetrics, readiness: ReadinessResult) -> String {
    if readiness.score < 60 {
        return "recovery and hydration"
    }
    if metrics.stress >= 7 {
        return "nervous-system reset and tactical clarity"
    }
    if metrics.soreness >= 7 {
        return "mobility and tissue prep"
    }
    return "execution quality and freshness"
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
private extension FoundationModelsCoachService {
    struct CoachPlanPayload: Decodable {
        let nextAction: String
        let tips: [String]
    }

    func generateRecommendations(
        game: Game,
        metrics: AthleteMetrics,
        readiness: ReadinessResult,
        fallback: RecommendationResult
    ) async throws -> RecommendationResult {
        let minutesToKickoff = max(0, Int(game.kickoffTime.timeIntervalSinceNow / 60))
        let prompt = recommendationPrompt(
            game: game,
            metrics: metrics,
            readiness: readiness,
            minutesToKickoff: minutesToKickoff
        )

        let session = LanguageModelSession(model: .default)
        let response = try await session.respond(to: prompt)
        return parseRecommendationPayload(response.content, fallback: fallback, minutesToKickoff: minutesToKickoff)
    }

    func generateChatReply(
        userMessage: String,
        game: Game,
        metrics: AthleteMetrics,
        readiness: ReadinessResult,
        recommendation: RecommendationResult,
        recentMessages: [CoachChatMessage],
        fallback: String
    ) async throws -> String {
        let history = recentMessages.suffix(6).map { message in
            "\(message.role.title): \(message.text)"
        }.joined(separator: "\n")

        let prompt = """
        You are GameDay Live, an elite athlete readiness coach.
        Give practical, direct guidance. Never discuss scores, teams, or fan content.
        Keep response to 2-4 concise sentences.

        Context:
        - Game: \(game.title)
        - Kickoff in minutes: \(max(0, Int(game.kickoffTime.timeIntervalSinceNow / 60)))
        - Athlete type: \(metrics.athleteType.title)
        - Readiness score: \(readiness.score) (\(readiness.label))
        - Sleep hours: \(String(format: "%.1f", metrics.sleepHours))
        - Soreness: \(metrics.soreness)/10
        - Stress: \(metrics.stress)/10
        - Hydration: \(Int(metrics.hydrationOz)) oz
        - Training intensity: \(metrics.trainingIntensity)/10
        - Current nextAction: \(recommendation.nextAction)

        Recent chat:
        \(history)

        Athlete message:
        \(userMessage)
        """

        let session = LanguageModelSession(model: .default)
        let response = try await session.respond(to: prompt)
        let cleaned = cleanLine(response.content)
        return cleaned.isEmpty ? fallback : cleaned
    }

    func recommendationPrompt(
        game: Game,
        metrics: AthleteMetrics,
        readiness: ReadinessResult,
        minutesToKickoff: Int
    ) -> String {
        """
        You are GameDay Live, an elite athlete readiness coach.
        Build a short pre-game coaching plan using readiness and metric context.
        Return STRICT JSON only (no markdown, no code fences):
        {"nextAction":"...", "tips":["...", "...", "..."]}

        Rules:
        - nextAction: one sentence, imperative, <= 100 chars.
        - tips: exactly 3 strings, each <= 100 chars.
        - Prioritize by time to kickoff first, then highest-risk metrics.
        - Athlete type must shape guidance.
        - No team names, scoreboards, or fan commentary.

        Context:
        - Game: \(game.title)
        - Kickoff in minutes: \(minutesToKickoff)
        - Athlete type: \(metrics.athleteType.title)
        - Readiness score: \(readiness.score) (\(readiness.label))
        - Top factors: \(readiness.topFactors.joined(separator: ", "))
        - Sleep hours: \(String(format: "%.1f", metrics.sleepHours))
        - Soreness: \(metrics.soreness)/10
        - Stress: \(metrics.stress)/10
        - Hydration: \(Int(metrics.hydrationOz)) oz
        - Training intensity: \(metrics.trainingIntensity)/10
        """
    }

    func parseRecommendationPayload(
        _ raw: String,
        fallback: RecommendationResult,
        minutesToKickoff: Int
    ) -> RecommendationResult {
        guard let payload = decodePayload(from: raw) else {
            return fallback
        }

        let nextAction = boundedLine(payload.nextAction, fallback: fallback.nextAction, maxLength: 100)

        var tips = payload.tips
            .map { boundedLine($0, fallback: "", maxLength: 100) }
            .filter { !$0.isEmpty }

        if tips.count < 3 {
            tips.append(contentsOf: fallback.tips)
        }

        if tips.count < 3 {
            tips.append("Kickoff in \(timeWindow(minutesToKickoff)): protect freshness and execution quality")
        }

        return RecommendationResult(
            nextAction: nextAction,
            tips: Array(tips.prefix(3))
        )
    }

    func decodePayload(from raw: String) -> CoachPlanPayload? {
        let cleaned = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = cleaned.data(using: .utf8),
           let payload = try? JSONDecoder().decode(CoachPlanPayload.self, from: data) {
            return payload
        }

        guard let start = cleaned.firstIndex(of: "{"),
              let end = cleaned.lastIndex(of: "}") else {
            return nil
        }

        let jsonString = String(cleaned[start...end])
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(CoachPlanPayload.self, from: data)
    }

    func boundedLine(_ text: String, fallback: String, maxLength: Int) -> String {
        let cleaned = cleanLine(text)
        guard !cleaned.isEmpty else { return fallback }
        guard cleaned.count > maxLength else { return cleaned }
        let end = cleaned.index(cleaned.startIndex, offsetBy: maxLength)
        return String(cleaned[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func cleanLine(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
#endif
