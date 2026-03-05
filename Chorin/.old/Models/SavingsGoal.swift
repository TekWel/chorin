import Foundation

struct SavingsGoal: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    let name: String
    let targetAmount: Decimal
    let icon: String
    let autoPercent: Decimal   // 0–100
    let isActive: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case userId = "user_id"
        case name
        case targetAmount = "target_amount"
        case icon
        case autoPercent = "auto_percent"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}
