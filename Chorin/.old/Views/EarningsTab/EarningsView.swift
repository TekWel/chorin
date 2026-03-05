import SwiftUI
import Supabase

struct EarningsView: View {
    @Environment(AppState.self) private var appState

    @State private var completions: [ChoreCompletionWithChore] = []
    @State private var isLoading = false

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private var currentWeekRange: ClosedRange<Date> { WeekHelper.weekRange() }

    private var currentWeekTotal: Decimal {
        WeekHelper.totalEarnings(from: completions, in: currentWeekRange)
    }

    private var currentWeekByDay: [(date: Date, total: Decimal)] {
        WeekHelper.earningsByDay(from: completions, in: currentWeekRange)
    }

    private var currentWeekByChore: [(name: String, total: Decimal, count: Int)] {
        WeekHelper.earningsByChore(from: completions, in: currentWeekRange)
    }

    var body: some View {
        NavigationStack {
            List {
                // This week summary
                Section {
                    VStack(spacing: 8) {
                        Text("This Week")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(currentWeekTotal.formatted(.currency(code: "USD")))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(Theme.green)
                        Text(WeekHelper.weekLabel())
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                // Daily breakdown for current week
                if !currentWeekByDay.isEmpty {
                    Section("Daily Breakdown") {
                        ForEach(currentWeekByDay, id: \.date) { day in
                            HStack {
                                Text(day.date, format: .dateTime.weekday(.abbreviated).month().day())
                                Spacer()
                                Text(day.total.formatted(.currency(code: "USD")))
                                    .foregroundStyle(Theme.green)
                            }
                        }
                    }
                }

                // Per-chore breakdown for current week
                if !currentWeekByChore.isEmpty {
                    Section("By Chore") {
                        ForEach(currentWeekByChore, id: \.name) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text(item.total.formatted(.currency(code: "USD")))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Past weeks
                Section("Past Weeks") {
                    let pastWeeks = WeekHelper.pastWeekStarts(count: 8).dropFirst()
                    if pastWeeks.isEmpty {
                        Text("No history yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(pastWeeks), id: \.self) { weekStart in
                            let range = WeekHelper.weekRange(for: weekStart)
                            let total = WeekHelper.totalEarnings(from: completions, in: range)
                            NavigationLink {
                                WeekHistoryView(weekStart: weekStart, completions: completions)
                            } label: {
                                HStack {
                                    Text(WeekHelper.weekLabel(for: weekStart))
                                    Spacer()
                                    Text(total.formatted(.currency(code: "USD")))
                                        .foregroundStyle(total > 0 ? Theme.green : Theme.textMuted)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Earnings")
            .task { await loadCompletions() }
            .refreshable { await loadCompletions() }
        }
    }

    private func loadCompletions() async {
        guard let userId = appState.session?.user.id,
              let householdId = appState.household?.id else { return }
        isLoading = true
        defer { isLoading = false }

        // Fetch completions for this user in this household going back 8 weeks
        let eightWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -8, to: WeekHelper.startOfCurrentWeek())!
        let dateString = ISO8601DateFormatter.choreDateFormatter.string(from: eightWeeksAgo)

        do {
            completions = try await supabase
                .from("chore_completions")
                .select("*, chores(name, icon)")
                .eq("user_id", value: userId.uuidString)
                .gte("date", value: dateString)
                .order("date", ascending: false)
                .execute()
                .value
        } catch {
            print("Error loading completions: \(error)")
        }
    }
}

#Preview {
    EarningsView()
        .environment(AppState())
}
