import SwiftUI
import Supabase

struct SavingsView: View {
    @Environment(AppState.self) private var appState

    @State private var goals: [SavingsGoal] = []
    @State private var contributions: [SavingsContribution] = []
    @State private var showingAddGoal = false
    @State private var selectedGoal: SavingsGoal?
    @State private var goalToContribute: SavingsGoal?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }
    private var isParent: Bool { appState.member?.isParent == true }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && goals.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if goals.isEmpty {
                    ContentUnavailableView(
                        "No Savings Goals",
                        systemImage: "piggybank.fill",
                        description: Text(isParent ? "Tap + to create a savings goal" : "No goals set up yet")
                    )
                } else {
                    List {
                        ForEach(goals) { goal in
                            let saved = totalSaved(for: goal)
                            let progress = goal.targetAmount > 0
                                ? min(Double(truncating: saved as NSDecimalNumber) / Double(truncating: goal.targetAmount as NSDecimalNumber), 1.0)
                                : 0.0

                            Section {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: goal.icon)
                                            .font(.title2)
                                            .foregroundStyle(Theme.blue)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(goal.name)
                                                .font(.headline)
                                            if goal.autoPercent > 0 {
                                                Text("Auto-save \(goal.autoPercent.formatted(.number))%")
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.textMuted)
                                            }
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(saved.formatted(.currency(code: "USD")))
                                                .fontWeight(.semibold)
                                                .foregroundStyle(Theme.green)
                                            Text("of \(goal.targetAmount.formatted(.currency(code: "USD")))")
                                                .font(.caption)
                                                .foregroundStyle(Theme.textMuted)
                                        }
                                    }

                                    ProgressView(value: progress)
                                        .tint(Theme.green)
                                }
                                .padding(.vertical, 4)

                                Button {
                                    goalToContribute = goal
                                } label: {
                                    Label("Add Contribution", systemImage: "plus.circle")
                                        .font(.subheadline)
                                }

                                if isParent {
                                    Button {
                                        selectedGoal = goal
                                    } label: {
                                        Label("Edit Goal", systemImage: "pencil")
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Theme.background)
                }
            }
            .navigationTitle("Savings")
            .toolbar {
                if isParent {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showingAddGoal = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                GoalFormView { Task { await load() } }
            }
            .sheet(item: $selectedGoal) { goal in
                GoalFormView(existingGoal: goal) { Task { await load() } }
            }
            .sheet(item: $goalToContribute) { goal in
                ContributeFormView(goal: goal) { Task { await load() } }
            }
            .task { await load() }
            .task { await subscribeRealtime() }
            .refreshable { await load() }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.red)
                    .padding()
            }
        }
    }

    private func totalSaved(for goal: SavingsGoal) -> Decimal {
        contributions
            .filter { $0.goalId == goal.id }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private func load() async {
        guard let householdId = appState.household?.id,
              let userId = appState.session?.user.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let goalsTask: [SavingsGoal] = supabase
                .from("savings_goals")
                .select()
                .eq("household_id", value: householdId.uuidString)
                .eq("is_active", value: true)
                .order("created_at", ascending: true)
                .execute()
                .value

            async let contribTask: [SavingsContribution] = supabase
                .from("savings_contributions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            (goals, contributions) = try await (goalsTask, contribTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func subscribeRealtime() async {
        guard let householdId = appState.household?.id else { return }
        let channel = supabase.realtimeV2.channel("savings-\(householdId)")
        let changes = await channel.postgresChange(AnyAction.self, schema: "public")
        await channel.subscribe()
        for await _ in changes { await load() }
    }
}

#Preview {
    SavingsView()
        .environment(AppState())
}
