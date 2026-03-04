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
        ZStack {
            ChorinTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Header
                Text("My Savings")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ChorinTheme.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                // MARK: - Content
                if isLoading && goals.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(ChorinTheme.textMuted)
                        Spacer()
                    }
                    Spacer()
                } else if goals.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "piggybank.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(ChorinTheme.textMuted)
                        Text("No Savings Goals")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(ChorinTheme.textPrimary)
                        Text(isParent
                             ? "Tap + to create a savings goal"
                             : "No goals set up yet")
                            .font(.system(size: 14))
                            .foregroundStyle(ChorinTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(goals) { goal in
                                SavingsGoalRow(
                                    goal: goal,
                                    saved: totalSaved(for: goal),
                                    isParent: isParent,
                                    onTap: { goalToContribute = goal },
                                    onEdit: { selectedGoal = goal },
                                    onArchive: { Task { await archiveGoal(goal) } }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(ChorinTheme.danger)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }

            // MARK: - Floating add button (parents only)
            if isParent {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingAddGoal = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(ChorinTheme.primary, in: Circle())
                                .shadow(color: ChorinTheme.primary.opacity(0.4), radius: 12, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 80)
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
            ContributeFormView(goal: goal, totalSaved: totalSaved(for: goal)) { Task { await load() } }
        }
        .task { await load() }
        .task { await subscribeRealtime() }
    }

    // MARK: - Helpers

    private func totalSaved(for goal: SavingsGoal) -> Decimal {
        contributions
            .filter { $0.goalId == goal.id }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    // MARK: - Data

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

    private func archiveGoal(_ goal: SavingsGoal) async {
        do {
            try await supabase
                .from("savings_goals")
                .update(["is_active": false])
                .eq("id", value: goal.id.uuidString)
                .execute()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Realtime

    private func subscribeRealtime() async {
        guard let householdId = appState.household?.id else { return }
        let channel = supabase.realtimeV2.channel("savings-\(householdId)")
        let changes = await channel.postgresChange(AnyAction.self, schema: "public")
        await channel.subscribe()
        for await _ in changes { await load() }
    }
}

// MARK: - Goal Row

private struct SavingsGoalRow: View {
    let goal: SavingsGoal
    let saved: Decimal
    let isParent: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void

    private var progress: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(
            Double(truncating: saved as NSDecimalNumber)
                / Double(truncating: goal.targetAmount as NSDecimalNumber),
            1.0
        )
    }

    private var isComplete: Bool { saved >= goal.targetAmount && goal.targetAmount > 0 }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // MARK: Icon
                    Image(systemName: goal.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(ChorinTheme.primary)
                        .frame(width: 42, height: 42)
                        .background(ChorinTheme.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    // MARK: Name + amounts
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(goal.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(ChorinTheme.textPrimary)

                            if isComplete {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(ChorinTheme.success)
                            }
                        }

                        HStack(spacing: 4) {
                            Text(saved.formatted(.currency(code: "USD")))
                                .foregroundStyle(ChorinTheme.success)
                            Text("of \(goal.targetAmount.formatted(.currency(code: "USD")))")
                                .foregroundStyle(ChorinTheme.textMuted)
                        }
                        .font(.system(size: 13))
                    }

                    Spacer()

                    // MARK: Percentage
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ChorinTheme.textSecondary)
                }

                // MARK: Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ChorinTheme.surfaceBorder)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(ChorinTheme.progressGradient)
                            .frame(width: max(geo.size.width * progress, 0), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(14)
            .background(ChorinTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if isParent {
                Button(role: .destructive, action: onArchive) {
                    Label("Archive", systemImage: "archivebox")
                }
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.orange)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SavingsView()
        .environment(AppState())
}
