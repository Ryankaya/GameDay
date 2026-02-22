//
//  GameDayWidgetLiveActivity.swift
//  GameDayWidget
//
//  Created by Ryan Kaya on 2/22/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GameDayWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GameDayWidgetAttributes.self) { context in
            GameDayLiveActivityLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(context.state.readinessScore)")
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                        Text(context.state.readinessLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timeBadge(for: context.attributes.kickoffTime))
                            .font(.caption)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.state.nextAction)
                            .font(.caption)
                            .lineLimit(1)
                        Text(context.state.tip)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Text("R\(context.state.readinessScore)")
                    .monospacedDigit()
                    .font(.caption2.weight(.semibold))
            } compactTrailing: {
                Text(timeBadge(for: context.attributes.kickoffTime))
                    .font(.caption2.weight(.semibold))
            } minimal: {
                Text("\(context.state.readinessScore)")
                    .monospacedDigit()
                    .font(.caption2.weight(.semibold))
            }
            .keylineTint(Color.blue.opacity(0.75))
        }
    }
}

private struct GameDayLiveActivityLockScreenView: View {
    let context: ActivityViewContext<GameDayWidgetAttributes>
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(context.attributes.gameTitle)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                Text(context.attributes.kickoffTime, style: .timer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(context.state.readinessScore)")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(context.state.readinessLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(context.state.nextAction)
                .font(.footnote)
                .lineLimit(1)

            Text(context.state.tip)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 1)
        .activityBackgroundTint(colorScheme == .dark ? Color.black.opacity(0.86) : Color.white.opacity(0.92))
        .activitySystemActionForegroundColor(colorScheme == .dark ? .white : .black)
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
