import Foundation

struct SavingsContribution: Codable, Identifiable {
    let id: UUID
    let goalId: UUID
    let userId: UUID
    let amount: Decimal
    let source: String          // "manual" | "auto"
    let completionId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case userId = "user_id"
        case amount
        case source
        case completionId = "completion_id"
        case createdAt = "created_at"
    }
}
