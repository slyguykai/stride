import SwiftUI

final class AppCoordinator {
    @ViewBuilder
    func rootView() -> some View {
        TabView {
            NavigationStack {
                NowView()
            }
            .tabItem {
                Label("Now", systemImage: "bolt.fill")
            }

            NavigationStack {
                WaitingView()
            }
            .tabItem {
                Label("Waiting", systemImage: "hourglass")
            }

            NavigationStack {
                AspirationalView()
            }
            .tabItem {
                Label("Aspirational", systemImage: "sparkles")
            }

            NavigationStack {
                WeeklyRetrospectiveView()
            }
            .tabItem {
                Label("Review", systemImage: "chart.bar")
            }
        }
    }
}
