//
//  AppIntent.swift
//  GameDayWidget
//
//  Created by Ryan Kaya on 2/22/26.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "GameDay Widget" }
    static var description: IntentDescription { "Shows athlete readiness and coach priority for the next game." }
}
