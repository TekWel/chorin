import SwiftUI
import Supabase

struct EarningsView: View {
    @Environment(AppState.self) private var appState

    @State private var completions: [ChoreCompletionWithChore] = []
    @State private var savingsGoals: [SavingsGoal] = []
    @State private var isLoading = false

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - Derived data

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

    private var savingsPercent: Decimal {
        savingsGoals
            .filter { $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.autoPercent }
    }

    private var savingsAmount: Decimal {
        currentWeekTotal * savingsPercent / 100
    }

    private var toBePaid: Decimal {
        currentWeekTotal - savingsAmount
    }

    private var maxDayEarning: Decimal {
        currentWeekByDay.map(\.total).max() ?? 1
    }

    // MARK: - Dark text for coral gradient

    private let heroText = Color(hex: "161110")

    // MARK: - Body

    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()

            if isLoading && completions.isEmpty {
                ProgressView()
                    .tint(ChorinTheme.textMuted)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Custom header
                        Text("Earnings")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(ChorinTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        heroCard
                        dailyBreakdownSection
                        perChoreSection
                        pastWeeksSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
        }
        .task { await loadData() }
        .refreshable { await loadData() }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(spacing: 12) {
            Text("This week's earnings")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(heroText.opacity(0.7))

            Text(currentWeekTotal.formatted(.currency(code: "USD")))
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(heroText)

            Text(WeekHelper.weekLabel())
                .font(.system(size: 12))
                .foregroundStyle(heroText.opacity(0.5))

            Rectangle()
                .fill(heroText.opacity(0.12))
                .frame(height: 1)
                .padding(.vertical, 4)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("To savings")
                        .font(.system(size: 12))
                        .foregroundStyle(heroText.opacity(0.6))
                    Text(savingsAmount.formatted(.currency(code: "USD")))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(heroText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("To be paid")
                        .font(.system(size: 12))
                        .foregroundStyle(heroText.opacity(0.6))
                    Text(toBePaid.formatted(.currency(code: "USD")))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(heroText)
                }
            }
        }
        .padding(20)
        .background(ChorinTheme.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Daily Breakdown

    private var dailyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DAILY BREAKDOWN")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ChorinTheme.textMuted)
                .tracking(0.8)

            // Show all 7 days Mon-Sun
            let allDays = weekDays
            ForEach(allDays, id: \.date) { day in
                dailyRow(day: day)
            }
        }
    }

    private var weekDays: [(date: Date, total: Decimal)] {
        let calendar = Calendar.current
        let start = WeekHelper.startOfCurrentWeek()
        var days: [(date: Date, total: Decimal)] = []

        // Build a lookup from the earningsByDay data
        var lookup: [Date: Decimal] = [:]
        for item in currentWeekByDay {
            let dayStart = calendar.startOfDay(for: item.date)
            lookup[dayStart] = item.total
        }

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: start)!
            let dayStart = calendar.startOfDay(for: date)
            days.append((date: dayStart, total: lookup[dayStart] ?? 0))
        }
        return days
    }

    private func dailyRow(day: (date: Date, total: Decimal)) -> some View {
        HStack(spacing: 12) {
            Text(day.date, format: .dateTime.weekday(.abbreviated))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ChorinTheme.textSecondary)
                .frame(width: 36, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ChorinTheme.surfaceBorder)
                        .frame(height: 8)

                    if day.total > 0, maxDayEarning > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ChorinTheme.primary)
                            .frame(
                                width: max(8, geo.size.width * CGFloat(truncating: (day.total / maxDayEarning) as NSDecimalNumber)),
                                height: 8
                            )
                    }
                }
            }
            .frame(height: 8)

            Text(day.total.formatted(.currency(code: "USD")))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(day.total > 0 ? ChorinTheme.textPrimary : ChorinTheme.textMuted)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ChorinTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
        )
    }

    // MARK: - Per Chore

    private var perChoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !currentWeekByChore.isEmpty {
                Text("PER CHORE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ChorinTheme.textMuted)
                    .tracking(0.8)

                ForEach(currentWeekByChore, id: \.name) { item in
                    choreRow(item: item)
                }
            }
        }
    }

    private func choreRow(item: (name: String, total: Decimal, count: Int)) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ChorinTheme.textPrimary)
                Text("\(item.count) time\(item.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(ChorinTheme.textMuted)
            }

            Spacer()

            Text(item.total.formatted(.currency(code: "USD")))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ChorinTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ChorinTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
        )
    }

    // MARK: - Past Weeks

    private var pastWeeksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let pastWeeks = Array(WeekHelper.pastWeekStarts(count: 8).dropFirst())

            if !pastWeeks.isEmpty {
                Text("PAST WEEKS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ChorinTheme.textMuted)
                    .tracking(0.8)

                ForEach(pastWeeks, id: \.self) { weekStart in
                    let range = WeekHelper.weekRange(for: weekStart)
                    let total = WeekHelper.totalEarnings(from: completions, in: range)

                    NavigationLink {
                        WeekHistoryView(weekStart: weekStart, completions: completions)
                    } label: {
                        HStack {
                            Text(WeekHelper.weekLabel(for: weekStart))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(ChorinTheme.textPrimary)

                            Spacer()

                            Text(total.formatted(.currency(code: "USD")))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(total > 0 ? ChorinTheme.primary : ChorinTheme.textMuted)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(ChorinTheme.textMuted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(ChorinTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let userId = appState.session?.user.id else { return }
        isLoading = true
        defer { isLoading = false }

        // Fetch completions going back 8 weeks
        let eightWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -8, to: WeekHelper.startOfCurrentWeek())!
        let dateString = ISO8601DateFormatter.choreDateFormatter.string(from: eightWeeksAgo)

        async let completionsTask: [ChoreCompletionWithChore] = supabase
            .from("chore_completions")
            .select("*, chores(name, icon)")
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: dateString)
            .order("date", ascending: false)
            .execute()
            .value

        async let goalsTask: [SavingsGoal] = supabase
            .from("savings_goals")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_active", value: true)
            .execute()
            .value

        do {
            completions = try await completionsTask
            savingsGoals = try await goalsTask
        } catch {
            print("Error loading earnings data: \(error)")
        }
    }
}

#Preview {
    EarningsView()
        .environment(AppState())
}
