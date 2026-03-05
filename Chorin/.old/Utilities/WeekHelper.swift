import Foundation

enum WeekHelper {
    /// Returns the start of the current week (Monday at midnight)
    static func startOfCurrentWeek(from date: Date = Date()) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    /// Returns the Monday–Sunday date range for the week containing the given date
    static func weekRange(for date: Date = Date()) -> ClosedRange<Date> {
        let start = startOfCurrentWeek(from: date)
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start)!
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: end)!
        return start...endOfDay
    }

    /// Returns a formatted string for a week range (e.g., "Feb 17 – Feb 23")
    static func weekLabel(for date: Date = Date()) -> String {
        let range = weekRange(for: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: range.lowerBound)) – \(formatter.string(from: range.upperBound))"
    }

    /// Returns the start dates of the last N weeks (most recent first)
    static func pastWeekStarts(count: Int, from date: Date = Date()) -> [Date] {
        var weeks: [Date] = []
        var current = startOfCurrentWeek(from: date)
        for _ in 0..<count {
            weeks.append(current)
            current = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: current)!
        }
        return weeks
    }

    /// Calculates total earnings from an array of completions within a date range
    static func totalEarnings(from completions: [ChoreCompletionWithChore], in range: ClosedRange<Date>) -> Decimal {
        completions
            .filter { range.contains($0.date) }
            .reduce(Decimal.zero) { $0 + $1.earnedAmount }
    }

    /// Groups completions by day within a date range
    static func earningsByDay(from completions: [ChoreCompletionWithChore], in range: ClosedRange<Date>) -> [(date: Date, total: Decimal)] {
        let calendar = Calendar.current
        let filtered = completions.filter { range.contains($0.date) }

        var dayTotals: [Date: Decimal] = [:]
        for completion in filtered {
            let day = calendar.startOfDay(for: completion.date)
            dayTotals[day, default: Decimal.zero] += completion.earnedAmount
        }

        return dayTotals
            .sorted { $0.key < $1.key }
            .map { (date: $0.key, total: $0.value) }
    }

    /// Groups completions by chore name within a date range
    static func earningsByChore(from completions: [ChoreCompletionWithChore], in range: ClosedRange<Date>) -> [(name: String, total: Decimal, count: Int)] {
        let filtered = completions.filter { range.contains($0.date) }
        var groups: [String: (total: Decimal, count: Int)] = [:]
        for c in filtered {
            let key = c.chore.name
            groups[key] = (
                total: (groups[key]?.total ?? 0) + c.earnedAmount,
                count: (groups[key]?.count ?? 0) + 1
            )
        }
        return groups
            .map { (name: $0.key, total: $0.value.total, count: $0.value.count) }
            .sorted { $0.total > $1.total }
    }
}
