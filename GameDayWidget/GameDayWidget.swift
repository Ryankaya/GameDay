//
//  GameDayWidget.swift
//  GameDayWidget
//
//  Created by Ryan Kaya on 2/22/26.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    private let readinessEngine = ReadinessEngine()
    private let recommendationService: any AIRecommendationService = StubAIRecommendationService()

    func placeholder(in context: Context) -> SimpleEntry {
        let date = Date()
        let game = DemoData.game(referenceDate: date)
        let metrics = DemoData.metrics(referenceDate: date)
        let readiness = readinessEngine.compute(game: game, metrics: metrics)

        return SimpleEntry(
            date: date,
            configuration: ConfigurationAppIntent(),
            game: game,
            readiness: readiness,
            recommendation: RecommendationResult(
                nextAction: "Reset breathing and hydrate before the next prep block",
                tips: ["Keep mobility light and protect freshness"]
            )
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let date = Date()
        let game = DemoData.game(referenceDate: date)
        let metrics = DemoData.metrics(referenceDate: date)
        let readiness = readinessEngine.compute(game: game, metrics: metrics)
        let recommendation = await recommendationService.recommendations(game: game, metrics: metrics, readiness: readiness)

        return SimpleEntry(
            date: date,
            configuration: configuration,
            game: game,
            readiness: readiness,
            recommendation: recommendation
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let currentDate = Date()

        for hourOffset in 0 ..< 5 {
            guard let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate) else {
                continue
            }

            let game = DemoData.game(referenceDate: entryDate)
            let metrics = DemoData.metrics(referenceDate: entryDate)
            let readiness = readinessEngine.compute(game: game, metrics: metrics)
            let recommendation = await recommendationService.recommendations(game: game, metrics: metrics, readiness: readiness)

            entries.append(
                SimpleEntry(
                    date: entryDate,
                    configuration: configuration,
                    game: game,
                    readiness: readiness,
                    recommendation: recommendation
                )
            )
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let game: Game
    let readiness: ReadinessResult
    let recommendation: RecommendationResult
}

struct GameDayWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.game.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(timeBadge(for: entry.game.kickoffTime))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(entry.readiness.score)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text(entry.readiness.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            readinessBar(score: entry.readiness.score)

            Text(entry.recommendation.nextAction)
                .font(.caption)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func readinessBar(score: Int) -> some View {
        GeometryReader { geometry in
            let progress = CGFloat(max(0, min(100, score))) / 100
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.08))
                Capsule(style: .continuous)
                    .fill(readinessGradient(score: score))
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 8)
    }
}

struct GameDayWidget: Widget {
    let kind: String = "GameDayWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            GameDayWidgetEntryView(entry: entry)
                .containerBackground(.thinMaterial, for: .widget)
        }
    }
}

private func readinessGradient(score: Int) -> LinearGradient {
    switch score {
    case 85...:
        return LinearGradient(colors: [Color.green.opacity(0.85), Color.mint.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
    case 70..<85:
        return LinearGradient(colors: [Color.blue.opacity(0.85), Color.cyan.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
    case 50..<70:
        return LinearGradient(colors: [Color.orange.opacity(0.85), Color.yellow.opacity(0.75)], startPoint: .leading, endPoint: .trailing)
    default:
        return LinearGradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.75)], startPoint: .leading, endPoint: .trailing)
    }
}

private func timeBadge(for kickoffTime: Date) -> String {
    let minutes = Int(kickoffTime.timeIntervalSinceNow / 60)
    if minutes <= 0 {
        return "LIVE"
    }
    if minutes < 60 {
        return "\(minutes)m"
    }
    return "\(minutes / 60)h"
}
