import SwiftUI

struct ContentView: View {
    @State private var selectedTab: ChorinTab = .chores

    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                NavigationStack {
                    ChoreListView()
                        .toolbar(.hidden, for: .navigationBar)
                }
                .tag(ChorinTab.chores)

                NavigationStack {
                    EarningsView()
                        .toolbar(.hidden, for: .navigationBar)
                }
                .tag(ChorinTab.earnings)

                NavigationStack {
                    SavingsView()
                        .toolbar(.hidden, for: .navigationBar)
                }
                .tag(ChorinTab.savings)

                NavigationStack {
                    HouseholdView()
                        .toolbar(.hidden, for: .navigationBar)
                }
                .tag(ChorinTab.household)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ChorinTabBar(selected: $selectedTab)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(
                        ChorinTheme.background
                            .ignoresSafeArea(edges: .bottom)
                    )
            }
        }
    }
}
