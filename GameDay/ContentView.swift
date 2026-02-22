import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameDayViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: "gauge")
            }

            NavigationStack {
                InputsView()
            }
            .tabItem {
                Label("Metrics", systemImage: "slider.horizontal.3")
            }

            NavigationStack {
                CoachPlanView()
            }
            .tabItem {
                Label("Plan", systemImage: "sparkles")
            }

            NavigationStack {
                CoachChatView()
            }
            .tabItem {
                Label("Chat", systemImage: "message.badge.waveform")
            }
        }
        .tint(GameDayPalette.accent)
        .toolbarBackground(.thinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environmentObject(viewModel)
        .task {
            await viewModel.evaluate()
        }
    }
}
