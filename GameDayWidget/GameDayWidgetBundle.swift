//
//  GameDayWidgetBundle.swift
//  GameDayWidget
//
//  Created by Ryan Kaya on 2/22/26.
//

import WidgetKit
import SwiftUI

@main
struct GameDayWidgetBundle: WidgetBundle {
    var body: some Widget {
        GameDayWidget()
        GameDayWidgetLiveActivity()
    }
}
