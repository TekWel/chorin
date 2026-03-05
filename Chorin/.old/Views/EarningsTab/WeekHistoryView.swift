import SwiftUI

struct WeekHistoryView: View {
    let weekStart: Date
    let completions: [ChoreCompletionWithChore]

    private var weekRange: ClosedRange<Date> { WeekHelper.weekRange(for: weekStart) }

    private var weekTotal: Decimal {
        WeekHelper.totalEarnings(from: completions, in: weekRange)
    }

    private var dailyBreakdown: [(date: Date, total: Decimal)] {
        WeekHelper.earningsByDay(from: completions, in: weekRange)
    }

    private var choreBreakdown: [(name: String, total: Decimal, count: Int)] {
        WeekHelper.earningsByChore(from: completions, in: weekRange)
    }

    var body: some View {
        List {
            // Week total
            Section {
                VStack(spacing: 8) {
                    Text(WeekHelper.weekLabel(for: weekStart))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(weekTotal.formatted(.currency(code: "USD")))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Theme.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Daily breakdown
            if !dailyBreakdown.isEmpty {
                Section("By Day") {
                    ForEach(dailyBreakdown, id: \.date) { day in
                        HStack {
                            Text(day.date, format: .dateTime.weekday(.wide).month().day())
                            Spacer()
                            Text(day.total.formatted(.currency(code: "USD")))
                                .foregroundStyle(Theme.green)
                        }
                    }
                }
            }

            // Chore breakdown
            if !choreBreakdown.isEmpty {
                Section("By Chore") {
                    ForEach(choreBreakdown, id: \.name) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                Text("\(item.count) time\(item.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.total.formatted(.currency(code: "USD")))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if dailyBreakdown.isEmpty && choreBreakdown.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Earnings",
                        systemImage: "dollarsign.circle",
                        description: Text("No chores were completed this week")
                    )
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Week Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
