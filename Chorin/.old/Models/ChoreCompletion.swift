import Foundation

struct ChoreCompletion: Codable, Identifiable {
    let id: UUID
    let choreId: UUID
    let userId: UUID
    let date: Date
    let earnedAmount: Decimal
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case choreId = "chore_id"
        case userId = "user_id"
        case date
        case earnedAmount = "earned_amount"
        case createdAt = "created_at"
    }
}

// Used in EarningsView — completion joined with its chore info
struct ChoreCompletionWithChore: Codable, Identifiable {
    let id: UUID
    let choreId: UUID
    let userId: UUID
    let date: Date
    let earnedAmount: Decimal
    let createdAt: Date
    let chore: ChoreInfo

    enum CodingKeys: String, CodingKey {
        case id
        case choreId = "chore_id"
        case userId = "user_id"
        case date
        case earnedAmount = "earned_amount"
        case createdAt = "created_at"
        case chore = "chores"
    }
}

struct ChoreInfo: Codable {
    let name: String
    let icon: String
}
