//
//  GameDayWidgetLiveActivity.swift
//  GameDayWidget
//
//  Created by Ryan Kaya on 2/22/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GameDayWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var homeScore: Int
        var awayScore: Int
        var quarter: String
        var clock: String
        var possession: Possession
    }

    enum Possession: String, Codable, Hashable {
        case home
        case away
        case none
    }

    var homeTeam: String
    var awayTeam: String
    var venue: String
}

struct GameDayWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GameDayWidgetAttributes.self) { context in
            VStack(spacing: 8) {
                HStack {
                    Text(context.attributes.awayTeam)
                        .font(.headline)
                    Spacer()
                    Text(context.attributes.homeTeam)
                        .font(.headline)
                }
                HStack {
                    Text("\(context.state.awayScore)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("-")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("\(context.state.homeScore)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                HStack {
                    Text(context.state.quarter)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(context.state.clock)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(context.attributes.venue)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(possessionText(for: context.state.possession))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .activityBackgroundTint(Color(red: 0.12, green: 0.14, blue: 0.2))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(context.attributes.awayTeam)
                            .font(.caption)
                        Text("\(context.state.awayScore)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(context.attributes.homeTeam)
                            .font(.caption)
                        Text("\(context.state.homeScore)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.quarter)
                        Text(context.state.clock)
                        Spacer()
                        Text(possessionText(for: context.state.possession))
                    }
                    .font(.caption)
                }
            } compactLeading: {
                Text(context.attributes.awayTeam.prefix(3))
            } compactTrailing: {
                Text("\(context.state.awayScore)-\(context.state.homeScore)")
            } minimal: {
                Text(context.state.quarter)
            }
            .keylineTint(Color(red: 0.85, green: 0.25, blue: 0.2))
        }
    }
}

extension GameDayWidgetAttributes {
    fileprivate static var preview: GameDayWidgetAttributes {
        GameDayWidgetAttributes(
            homeTeam: "SF",
            awayTeam: "LA",
            venue: "GameDay Stadium"
        )
    }
}

extension GameDayWidgetAttributes.ContentState {
    fileprivate static var smiley: GameDayWidgetAttributes.ContentState {
        GameDayWidgetAttributes.ContentState(
            homeScore: 21,
            awayScore: 17,
            quarter: "Q3",
            clock: "05:42",
            possession: .home
        )
     }
     
     fileprivate static var starEyes: GameDayWidgetAttributes.ContentState {
         GameDayWidgetAttributes.ContentState(
            homeScore: 24,
            awayScore: 20,
            quarter: "Q4",
            clock: "01:08",
            possession: .away
         )
     }
}

private func possessionText(for possession: GameDayWidgetAttributes.Possession) -> String {
    switch possession {
    case .home:
        return "Home ball"
    case .away:
        return "Away ball"
    case .none:
        return "No possession"
    }
}

#Preview("Notification", as: .content, using: GameDayWidgetAttributes.preview) {
   GameDayWidgetLiveActivity()
} contentStates: {
    GameDayWidgetAttributes.ContentState.smiley
    GameDayWidgetAttributes.ContentState.starEyes
}
