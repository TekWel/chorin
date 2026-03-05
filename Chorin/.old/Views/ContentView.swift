import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            TabView {
                ChoreListView()
                    .tabItem {
                        Label("Chores", systemImage: "checklist")
                    }

                EarningsView()
                    .tabItem {
                        Label("Earnings", systemImage: "dollarsign.circle.fill")
                    }

                SavingsView()
                    .tabItem {
                        Label("Savings", systemImage: "piggybank.fill")
                    }

                NavigationStack {
                    HouseholdView()
                }
                .tabItem {
                    Label("Household", systemImage: "house.fill")
                }
            }
            .tint(Theme.activeBlue)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
